#
'''
05/03/2024

Luiz Fernando Mizael Meier

Adaptação de código para ser utilizado com passagem de parâmetros. O intuito é ser utilizado como script customizado em ferramenta de monitoramento.

Edite conforme a sua necessidade, principalmente aa impressão das críticas. Ainda cabem muitas melhorias nesse script.

Adaptado de:
https://github.com/rbonicenha/PaloAlto

Referências
https://docs.paloaltonetworks.com/pan-os/9-1/pan-os-panorama-api/get-started-with-the-pan-os-rest-api/access-the-rest-api
https://www.packetswitch.co.uk/getting-started-with-palo-alto-rest-api/
https://live.paloaltonetworks.com/t5/automation-api-discussions/rest-api-parameter-error-for-non-vsys-device/td-p/390273
https://yourFirewall/restapi-doc/
https://realpython.com/api-integration-in-python/

W3Schools
Muita busca sobre Python na internet
'''

# Importando bibliotecas
import requests
import json
import sys
import xml.etree.ElementTree as ET

# Define as variáveis que serão usadas como argumento quando o script for chamado
firewall = sys.argv[1]  # Endereço do firewall
action = sys.argv[2]    # Ação a ser tomada (aceita up ou down)
group = sys.argv[3]     # Nome do address group no firewall
host = sys.argv[4]      # Nome do host a ser adicionado ou removido
username = sys.argv[5]  # Usuário para acesso
password = sys.argv[6]  # Senha para acesso

# Opcional - Desabilitar o aviso de certificado autoassinado
requests.packages.urllib3.disable_warnings()

# Gera urls base
api_url = 'https://' + firewall + '/api'

# Autenticando e pegando token
query = {"type": "keygen", "user": username, "password": password}
response = requests.get(api_url, verify=False, params=query)

# Tratando o valor do XML
root = ET.fromstring(response.text)

# Pega o valor da key e preenche a variável
key_value = root.find(".//key").text

# Gera o header de autorização que será usado na chamada
api_key = {
    "X-PAN-KEY": key_value
}
###

###
# Capturando a versao do firewall
query = {"type": "version"}
response = requests.get(api_url, verify=False, params=query, headers=api_key)

# Tratando o valor do XML
root = ET.fromstring(response.text)

# Pega o valor da key e preenche a variável
ver_value = root.find(".//sw-version").text

# PanOS só entende os dois primeiros valores da versão. Então splita para que fique no formato adequado
ver_value = ver_value.split(".")[0] + "." + ver_value.split(".")[1]

# Monta url que será usada para chamar a api
restapi_url = 'https://' + firewall + '/restapi' + '/v' + ver_value 

###
# Captura o grupo
query_url = restapi_url + '/Objects/AddressGroups'

# Preenche os parâmetros
location = {
    'location': 'vsys',
    'vsys': 'vsys1',
    'name': group
    }

# Chama o firewall captura o conteúdo do address group
addr_group_raw = requests.get(query_url, verify=False, headers=api_key, params=location)

# Trata retorno do grupo
addr_group = json.loads(addr_group_raw.text)
###

###
# Avaliação da ação pedida pelo usuário
# Se a ação for down
if action == "down":

    # Checa se o host a ser tratado existe no address group. Se sim, remove o host do array
    if host in addr_group["result"]["entry"][0]["static"].get('member'):
        addr_group["result"]["entry"][0]["static"]["member"].remove(host)

    # Se não existe o host no grupo, critica e aborta
    else:
        print("Host não pertence ao grupo. Abortando...")
        exit ()

# Se a ação for up
elif action == "up":
     # Checa se o host a ser tratado existe no address group. Se existe, critica e aborta
    if host in addr_group["result"]["entry"][0]["static"].get('member'):
        print("Host já existe no grupo. Abortando...")
        exit ()

    # Se o host não existe no grupo, adiciona ao array
    else:
        addr_group["result"]["entry"][0]["static"]["member"].append(host)

# Se nem up ou down, critica e aborta
else:
   print("Ação incorreta. Abortando")
   exit ()
###

###
# Cria novo body para editar o objeto (member já virá com [])
addr_group_updated = {
    "entry": {
        "@name": group,
        "static": {
            "member": addr_group["result"]["entry"][0]["static"]["member"]
        }
    }
}

# Edita o objeto
requests.put(query_url, params=location, verify=False, headers=api_key, json=addr_group_updated)

# Monta a URL para commit
commit_url = 'https://' + firewall + '/api?type=commit&cmd=<commit></commit>'

# Commita a configuração
requests.post(commit_url, verify=False, headers=api_key)
