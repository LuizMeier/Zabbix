#!/usr/bin/python
# -*- coding: utf-8 -*-

# Script para monitoramento de túneis IPSec Palo Alto

# 05/08/2024 - Elaborado por Luiz Meier / Reristen Souza

# Importa bibliotecas
import requests
import json
import sys
import xml.etree.ElementTree as ET

# Define as variáveis que serão usadas 
firewall = sys.argv[1]  # Endereço do firewall
username = sys.argv[2]  # Usuário para acesso
password = sys.argv[3]  # Senha para acesso
action = sys.argv[4]    # Ação

# Como o parâmetro to nome do túnel é opcional, se faz necessário o if. Caso contrário o Python retorna erro pela variável não estar preenchida.
if len(sys.argv) > 5:
    tunnel = sys.argv[5]    # Nome do túnel

# Opcional - Desabilitar o aviso de certificado autoassinado
requests.packages.urllib3.disable_warnings()

# Gera urls base
api_url = 'https://' + firewall + '/api'

# Autenticação
# Autenticando e pegando token
query = {"type": "keygen", "user": username, "password": password}
response = requests.get(api_url, verify=False, params=query)

# Checa código de retorno
if response.status_code != 200:
    print("Erro! [", response.status_code, "]")
    sys.exit()

# Tratando o valor do XML
root = ET.fromstring(response.text)

# Pega o valor da key e preenche a variável
key_value = root.find(".//key").text

# Gera o header de autorização que será usado na chamada
api_key = {
    "X-PAN-KEY": key_value
}
###

# Valida o parâmetro 'action'
if action != 'discovery' and action != 'status':
    print('Parâmetro inválido')

# Se o valor de action for 'discovery', faz o LLD. Esse JSON é usado pelo Zabbix para criar os itens de monitoramento.
if action == "discovery":
    
    # Capturando a versao do firewall
    query = {"type": "version"}
    response = requests.get(api_url, verify=False, params=query, headers=api_key)
   
   # Checa código de retorno
    if response.status_code != 200:
        print("Erro! [", response.status_code, "]")
        sys.exit()

    # Tratando o valor do XML
    root = ET.fromstring(response.text)

    # Pega o valor do campo "sw-version" e preenche a variável
    ver_value = root.find(".//sw-version").text

    # PanOS só entende os dois primeiros valores da versão. Então splita para que fique no formato adequado
    ver_value = ver_value.split(".")[0] + "." + ver_value.split(".")[1]

    # Monta url que será usada para chamar a api rest
    restapi_url = 'https://' + firewall + '/restapi' + '/v' + ver_value 
    ###
    
    # Monta a url a ser chamada
    query_url = restapi_url + '/Network/IPSecTunnels'

    # Preenche os parâmetros
    params = {
        'location': 'panorama-pushed',
    }

    # Chama o firewall captura a lista de túneis IPSec
    ipsec_tunnels_raw = requests.get(query_url, verify=False, headers=api_key, params=params)

    # Checa código de retorno
    if response.status_code != 200:
        print("Erro! [", response.status_code, "]")
        sys.exit()

    # Trata retorno do grupo
    ipsec_tunnels = json.loads(ipsec_tunnels_raw.text)
    
    # Imprime o json de descoberta
    print('{')
    print('"data":[')
    for tunnel in ipsec_tunnels["result"]["entry"]:
        a = '{"{#TUNNELNAME}":"' + tunnel["@name"] + '"},'
        
        if tunnel["@name"] != ipsec_tunnels["result"]["entry"][-1]["@name"]:
            print(a)
        
        else:
            a = '{"{#TUNNELNAME}":"' + tunnel["@name"] + '"}'
            print(a)
    print(']')
    print('}')


# Se a ação for para checar o status de um túnel, checa.
if action == "status":
    
    # Monta o local da informação dentro do retorno xml
    tunnel_location = '<show><vpn><flow><name>' + tunnel + '</name></flow></vpn></show>'

    # Monta o header
    params = {
        'type': 'op',
        'cmd': tunnel_location
    }

    # Chama a api
    status_tunnel_raw = requests.get(api_url, verify=False, headers=api_key, params=params)

    # Checa código de retorno
    if response.status_code != 200:
        print("Erro! [", response.status_code, "]")
        sys.exit()

    # Tratando o valor do XML
    root = ET.fromstring(status_tunnel_raw.text)

    # Pega o valor do campo "state" e preenche a variável
    status = root.find(".//state").text

    # Imprime o status, de acordo com o status
    if status == 'active':
        print('1')
    else:
        print('0')
