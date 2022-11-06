#!/bin/bash

# Luiz Fernando - 14/05/2021 - SCript para monitoramento da estrutura de Wi-Fi via AirWave

# Rererências:
# https://support.hpe.com/hpesc/public/docDisplay?docLocale=en_US&docId=emr_na-a00090969en_us
# https://community.arubanetworks.com/community-home/digestviewer/viewthread?MID=29593
# https://community.arubanetworks.com/browse/articles/blogviewer?blogkey=51b1034e-ddc0-4ecb-bcf9-a4f2b6a48020
# https://community.arubanetworks.com/community-home/digestviewer/viewthread?MID=28891
# https://www.youtube.com/watch?v=xIbWRx0DF1k
# https://www.w3schools.com/xml/xpath_intro.asp
# https://www.w3schools.com/xml/xpath_syntax.asp
# https://unix.stackexchange.com/questions/492116/how-to-output-html-to-a-file-with-xmllint
# https://www.cyberciti.biz/faq/grep-regular-expressions/

# URL base para chamadas
urlbase="https://airwave.domain.local"

# Função de autenticação
autentica() {

    # Credenciais
    username='username'
    password='password'

    # Monta a url para autenticação
    url="$urlbase/LOGIN"

    # Chamada de autenticação (armazena o retorno no arquivo 'token' e o cookie no arquivo 'cookie'). 
    # -s para suprimir progresso
    # -k para ignorar erros de certificado
    # >/dev/null para descartar impressão do cabeçalho HTTP
    curl -s -k -D /usr/lib/zabbix/externalscripts/token -c /usr/lib/zabbix/externalscripts/cookie -d "credential_0=$username" -d "credential_1=$password" -d "destination=/" -d "login=Log In" $url > /dev/null

    # Armazena a linha contendo o valor X-BISCOTTI, que depois deve ser repassado nas chamadas posteriores
    TOKEN=`cat /usr/lib/zabbix/externalscripts/token | grep X-BISCOTTI`

}

# Checa se o cookie é mais velho que 3:50, uma vez que expira em 4 horas

# Se existe, entra
if test -f /usr/lib/zabbix/externalscripts/cookie; then

    # Se existe e for mais velho que 30 minutos, entra e chama autenticação
    if test `find /usr/lib/zabbix/externalscripts/cookie -cmin +30`; then
        autentica
    fi

# Se não existe, entra e chama autenticação
else
       autentica

fi


# Se não passar argumentos, efetua LLD
if [ $# -eq 0 ] ; then

    # Monta a url
    url=$urlbase/ap_list.xml
    
    # Trata o conteúdo do retorno (Só traz se não for virtual controller, seleciona a linha contendo o 'name' e depois trata para só exibir a string do nome, assumindo 'PRBAP')
    aps=`curl -s -k --header "$TOKEN" -b /usr/lib/zabbix/externalscripts/cookie $url | xmllint --xpath "//ap[model!='Instant Virtual Controller']" --format - | grep 'name' | grep -o 'APNAME[A-Z]\+[0-9]\+'`
    count=`echo "${aps}" | wc -l`

    # Monta e imprime o JSON
    echo '{'
    echo '"data":['
    for i in `/usr/bin/seq 1 $count`; do
        desc=`echo "${aps}" | sed "${i}!d"`
        line='{"{#APNAME}":"'${desc}'"}'
        printf "$line"

        if [ $i -ne $count ]; then
            echo ','
        fi
        
    done
    echo
    echo ']'
    echo '}'
fi

# Traz status do dispositivo
if [ "$1" = "bandwidth" ] ; then
    url=$urlbase/ap_search.xml?query=$2
    curl -s -k --header "$TOKEN" -b /usr/lib/zabbix/externalscripts/cookie $url | xmllint --xpath "//bandwidth[@sort_value]" --format - | grep -o 'display_value="[0-9]\+\.[0-9]\+' | grep -o '[0-9]\+\.[0-9]\+'
fi


# Traz status de configuração do dispositivo
if [ "$1" = "config" ] ; then
    url=$urlbase/ap_search.xml?query=$2
    curl -s -k --header "$TOKEN" -b /usr/lib/zabbix/externalscripts/cookie $url | xmllint --xpath "//management_state[@ascii_value]" --format - | grep -o 'ascii_value="\w\+' | grep -oE 'Good|Bad'
fi


# Traz status do dispositivo
if [ "$1" = "status" ] ; then
    url=$urlbase/ap_search.xml?query=$2
    curl -s -k --header "$TOKEN" -b /usr/lib/zabbix/externalscripts/cookie $url | xmllint --xpath "//monitoring_status[@ascii_value]" --format - | grep -o 'ascii_value="\w\+' | grep -oE 'Up|Down'
fi
