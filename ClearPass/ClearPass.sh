#!/bin/bash

# Luiz Fernando - 08/05/2023 - Script para monitoramento de saúde do cluster do ClearPass
# Luiz Fernando - 17/05/2023 - Tratamento para impressão de valor nulo quando ainda não houver replicação da base

# Rererências:
# https://developer.arubanetworks.com/aruba-cppm/docs/clearpass-configuration
# https://higherlogicdownload.s3.amazonaws.com/HPE/MigratedAssets/Using%20the%20ClearPass%20HTTP%20APIs.pdf
# https://www.zabbix.com/documentation/5.4/pt/manual/discovery/low_level_discovery

# URL base para chamadas
urlBase=$1

# Autenticação

# Monta url para autenticação
authUrl="$urlBase/oauth"

# Chave do usuario
user=$2
secret=$3

# Montagem para que o JSON de autentiocação possa ser usado via variável. Caso contrário, as aspas se perde e fica mal-formado
payload="{\"grant_type\": \"client_credentials\", \"client_secret\": \"$secret\", \"client_id\": \"$user\"}"

# Captura o token para uso na chamada de monitoramento
token=$(curl -s -X POST -k $authUrl -H "Content-Type: application/json" -d "$payload" | jq -r .access_token)


# Se o parâmetro for "role", entra
if [ "$4" = "role" ] ; then
    # Recebe o valor do quinto parâmetro, que deve ser o uuid do nó
    uuid=$5

    # Monta a url e faz a chamada, filtrando para trazer somente o campo is_master
    url=$urlBase/cluster/server/$uuid
    
    # Traz a informação true (master do cluster) ou false (secundário)
    curl -s -k -X GET $url -H "Content-Type: application/json" -H "Authorization: Bearer $token" | jq -r .is_master
    
    # De cordo com o retorno, imprime o papel - Desativado para fazer a transformação direto no próprio Zabbix
    #if [ "$is_master" = "true" ] ; then
    #    echo "Publisher"
    #
    #elif [ "$is_master" = "false" ] ; then
    #    echo "Subscriber"
    #
    #fi

# Se o parâmetro for "repl.status", entra
elif [ "$4" = "repl.status" ] ; then
    # Recebe o valor do quinto parâmetro, que deve ser o uuid do nó
    uuid=$5

    # Monta a URL
    url=$urlBase/cluster/server/$uuid
    
    # Traz status de replicação da base
    curl -s -k -X GET $url -H "Content-Type: application/json" -H "Authorization: Bearer $token" | jq -r .replication_status

# Traz a diferença (em segundos) entre agora e a última replicação da base
# Se o parâmetro for "repl.last", entra
elif [ "$4" = "repl.last" ] ; then
    # Recebe o valor do quinto parâmetro, que deve ser o uuid do nó
    uuid=$5

    # Monta a url
    url=$urlBase/cluster/server/$uuid
    
    # Chama e preenche a variável "last" com a data da última sincronização da base
    last=$(curl -s -k -X GET $url -H "Content-Type: application/json" -H "Authorization: Bearer $token" | jq -r .last_replication_timestamp)

    # Se o valor for diferente de "null", entra
    if [ "$last" != "null" ] ; then
        # Transforma a data em segundos (desde o epoch)
        last=$(date +%s -d "$last")
        
        # Pega a data atual em segundos (desde o epoch)
        now=$(date +%s)

        # Calcula a diferença entre agora e a última replicação
        diff=$(($now-$last))

        # Imprme a diferença, em segundos
        echo $diff
    
    else
        echo $last

    fi

# Se não passar argumentos, efetua LLD
else

    # Monta a url
    url=$urlBase/cluster/server
    
    # Chama e traz o nome dos nodes
    nodeNames=$(curl -s -k -X GET $url -H "Content-Type: application/json" -H "Authorization: Bearer $token" | jq -r ._embedded.items[].name)
    # Chama e traz o uuis dos nodes
    nodeUuids=$(curl -s -k -X GET $url -H "Content-Type: application/json" -H "Authorization: Bearer $token" | jq -r ._embedded.items[].server_uuid)
    # Chama e traz o ip de gerência dos nodes
    nodeIps=$(curl -s -k -X GET $url -H "Content-Type: application/json" -H "Authorization: Bearer $token" | jq -r ._embedded.items[].management_ip)
    
    # Conta quantos itens há no array $nodes
    count=$(echo "${nodeNames}" | wc -l)

    # Monta e imprime o JSON com Nome, UUID e IP dos nodes, com base na quantidade de itens do array. Este JSON é usado pelo Zabbix para criar os itens/alertas dinamicamente.
    echo '{'
    echo '"data":['
    for i in `/usr/bin/seq 1 $count`; do
        descName=$(echo "${nodeNames}" | sed "${i}!d")
        descUuid=$(echo "${nodeUuids}" | sed "${i}!d")
        descIp=$(echo "${nodeIps}" | sed "${i}!d")
        line='{"{#NODENAME}":"'${descName}'","{#NODEUUID}":"'${descUuid}'","{#NODEIP}":"'${descIp}'"}'
        printf "$line"

        if [ $i -ne $count ]; then
            echo ','
        fi
        
    done
    echo
    echo ']'
    echo '}'
fi