# Consulta se as entradas DNS estão com recurso de proxy ativado na CloudFlare
# Requer chave de API criada na conta da CloudFlare

# Luiz Fernando - 07/10/2021 - Criação/Adaptação do script

# Luiz Fernando - 21/03/2022 - Tratamento da saída, informando os campos 'name' e 'proxied'

# Referência: https://blog.netnerds.net/2015/12/powershell-invoke-restmethod-cloudflare-api-v4-code-sample/


# Informe de opções necessárias
$token = ""
$email = ""
$domain = "" # Pode ser melhorado para que o script capture o domínio a partir da entrada DNS automaticamente

# Declara o array a ser preenchido com os resultados
$outputs = @()

# Lista de registros a serem pesquisados
$records = @(
    "coxinha.meudominio.com",
    "kibe.dominiodosucesso.com.br",
    "scriptdosucesso.meudominio.com.br"
)

# Trata a URL base
$baseUrl = "https://api.cloudflare.com/client/v4/zones"
$zoneUrl = "$baseurl/?name=$domain"

# Cabeçalho de autenticação
$headers = @{
    'X-Auth-Key' = $token
	'X-Auth-Email' = $email
}

# Captura informação da zona DNS
$zone = Invoke-RestMethod -Uri $zoneurl -Method Get -Headers $headers
$zoneid = $zone.result.id

# Para cada entrada DNS, executa
foreach ($record in $records) {

    # Cria a URL para consulta do registro DNS
    $recordurl = "$baseurl/$zoneid/dns_records/?name=$record"

    # Captura as informações do registro DNS da vez
    $dnsrecord = Invoke-RestMethod -Uri $recordurl -Method Get -Headers $headers
    
    # Adiciona os dados da vez ao array de resultados
    $outputs += $dnsrecord

}

# Imprime os resultados (Tratar conforme a necessidade)
$outputs.result | Select-Object name, proxied