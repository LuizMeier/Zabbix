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

'''

#Não esqueça de importar a biblioteca requests com o comando "pip install requests"
import requests
import json

# Desabilitar o aviso de certificado autoassinado
# requests.packages.urllib3.disable_warnings()

# Autenticando e pegando token
api_url = "https://10.41.13.101/api/?type=keygen"
passwd = {"user":"user", "password": "password"}
response = requests.post(api_url, json=passwd)
response.json


def ler_ips(arquivo):
    """
    Lê os endereços IP do arquivo especificado.

    Parâmetros:
    - arquivo: O nome do arquivo a ser lido.

    Retorna:
    - Uma lista de endereços IP se o arquivo for encontrado e não estiver vazio.
    - None se o arquivo não for encontrado ou estiver vazio.
    """
    try:
        with open(arquivo, "r") as file:
            ips = file.read().splitlines()

        # Verifica se o conteúdo do arquivo não está vazio
        if ips:
            return ips
        else:
            return None
    except FileNotFoundError:
        return None

def ping(ip):
    """
    Verifica a conectividade com um endereço IP usando o comando ping.

    Parâmetros:
    - ip: O endereço IP a ser verificado.

    Retorna:
    - True se o ping for bem-sucedido (o IP está online).
    - False se houver um erro no ping ou se o IP estiver offline.
    """
    try:
        subprocess.check_output(["ping", "-n", "1", ip], timeout=1)
        return True
    except subprocess.CalledProcessError:
        return False
    except subprocess.TimeoutExpired:
        return False

def atualizar_arquivo(nome_arquivo, ips):
    """
    Atualiza um arquivo com uma lista de IPs, caso a lista seja diferente da anterior.

    Parâmetros:
    - nome_arquivo: O nome do arquivo a ser atualizado.
    - ips: A lista de IPs a ser gravada no arquivo.

    Retorna:
    - True se houver uma alteração e o arquivo for atualizado.
    - False se não houver alteração.
    """
    try:
        with open(nome_arquivo, "r") as file:
            ips_anterior = file.read().splitlines()
    except FileNotFoundError:
        ips_anterior = []

    if set(ips) != set(ips_anterior):
        with open(nome_arquivo, "w") as file:
            for ip in ips:
                file.write(ip + "\n")
        return True
    return False

def executar_commit(servidores_up, servidores_down, arquivo):
    """
    Executa o commit no firewall Palo Alto Networks para atualizar a lista de servidores.

    Parâmetros:
    - servidores_up: Lista de servidores online.
    - servidores_down: Lista de servidores offline (não utilizada para commit, apenas para controle).
    - arquivo: O arquivo sendo monitorado.
    """
    if servidores_up:
      # Não esqueça de modificar o endereço ip do firewall para o endereço de gerencia do seu firewall!!!
        RestApiPANW = "https://192.168.100.230/restapi/v11.0/Objects/AddressGroups"
        RestApiCommit = "https://192.168.100.230/api/?type=commit&cmd=<commit></commit>"
        Localizacao = {'location': 'vsys', 'vsys': 'vsys1', 'name': arquivo.split(".")[0]}

        CriarObjeto = {
            "entry": {
                "@name": arquivo.split(".")[0],
                "static": {
                    "member": servidores_up

                }
            }
        }

        # Criar objeto no firewall
        criar_enderecos = requests.put(RestApiPANW, params=Localizacao, verify=False, headers=ApiKEY, json=CriarObjeto)
        print(criar_enderecos.text)

        # Mensagens na tela
        print(f"Conteúdo lido de {arquivo}: {ler_ips(arquivo)}")
        print(f"Ips Online: {servidores_up}")
        print(f"Ips Offline: {servidores_down}")

        # Atualizar arquivo com os IPs online
        atualizar_arquivo(f"{arquivo.split('.')[0]}_up.txt", servidores_up)

        # Executar commit
        requests.post(RestApiCommit, verify=False, headers=ApiKEY)

def monitorar_arquivos(lista_arquivos):
    """
    Monitora os endereços IP de cada arquivo na lista e executa a função de commit quando necessário.

    Parâmetros:
    - lista_arquivos: Lista de arquivos a serem monitorados.
    """
    servidores_up_anterior = {}  # Dicionário para controlar os servidores_up anteriores de cada arquivo
    while True:
        for arquivo in lista_arquivos:
            ips = ler_ips(arquivo)

            # Verificar se o arquivo foi encontrado e não está vazio
            if ips is not None:
                ips_online = []
                ips_offline = []

                # Verificar o status de cada IP
                for ip in ips:
                    if ping(ip):
                        ips_online.append(ip)
                    else:
                        ips_offline.append(ip)

                # Atualizar arquivo com os IPs offline (caso necessário)
                atualizar_arquivo(f"{arquivo.split('.')[0]}_down.txt", ips_offline)

                # Se a lista de IPs online foi atualizada e é diferente da anterior, executar commit
                if atualizar_arquivo(f"{arquivo.split('.')[0]}_up.txt",
                                     ips_online) and ips_online != servidores_up_anterior.get(arquivo, []):
                    executar_commit(ips_online, ips_offline, arquivo)
                    servidores_up_anterior[arquivo] = ips_online

            else:
                print(f"Conteúdo de {arquivo}: Sem valores.")

        # Aguarda X segundos antes de verificar novamente
        time.sleep(5)

if __name__ == "__main__":
    # Lista de arquivos a serem monitorados (Sempre que possível, tente manter uma coerencia entre o nome do arquivo e o nome da regra de NAT)
    lista_arquivos = ["NAT1.txt", "NAT2.txt"]  # Adicione mais arquivos conforme necessário

    monitorar_arquivos(lista_arquivos)
