#
'''
Código de Automação e Probe de endereços/objetos nos firewalls da Palo Alto Networks

Esse script foi desenvolvido por Rodrigo Bonicenha Ferreira em 22/11/2023 e é livre sua edição,
modificação e melhoria desde que sejam respeitados os créditos de seu desenvolvedor.

                        ATENÇÃO:
Para contato, CONSULTORIA, TREINAMENTOS e PROJETOS utilize os canais abaixo:

 - Linkedin: https://www.linkedin.com/in/rodrigo-bonicenha/
 - Email: rodrigo.bonicenha@gmail.com
 - YouTube: https://www.youtube.com/c/RodrigoBonicenha

 '''

'''
05/03/2024

Luiz Fernando Mizael Meier

Adaptação de código para ser utilizado com passagem de parâmetros. O intuito é ser utilizado como script customizado em ferramenta de monitoramento.

Referências
https://docs.paloaltonetworks.com/pan-os/9-1/pan-os-panorama-api/get-started-with-the-pan-os-rest-api/access-the-rest-api
https://www.packetswitch.co.uk/getting-started-with-palo-alto-rest-api/


'''

#Não esqueça de importar a biblioteca requests com o comando "pip install requests"
import requests
import json
import sys
import xml.etree.ElementTree as ET

# Define as variáveis que serão usadas como argumento quando o script for chamado
firewall = sys.argv[1]
action = sys.argv[2]
value = sys.argv[3]
username = sys.argv[4]
password = sys.argv[5]

# Desabilitar o aviso de certificado autoassinado
# requests.packages.urllib3.disable_warnings()

# Autenticando e pegando token
api_url = 'https://' + firewall + '/api/?type=keygen'
query = {"type": "keygen", "user": username, "password": password}
response = requests.get(api_url, verify=False, params=query)

# Tratando o valor do XML
root = ET.fromstring(response.text)

# Pega o valor da key e preenche a variável
key_value = root.find(".//key").text

# Gera o header que será usado na chamada
api_key = {
    "X-PAN-KEY": key_value
}

if firewall == 'up':
    # Captura os endereços contidos on grupo
    