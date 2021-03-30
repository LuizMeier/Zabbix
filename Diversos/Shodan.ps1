# Luiz Fernando 30/3/2021

# Script para consultar dados do Shodan

# Documentação: https://developer.shodan.io/api

# Informando credenciais
Write-Host -ForegroundColor Yellow "Informe sua chave API: " -NoNewline
$apikey = Read-Host -AsSecureString
$plainKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($apikey))

#$plainKey = ""

# Parâmetros
$urlBase = "https://api.shodan.io"


# Chama a API e traz os resultados conforme necessidade

# Host específico
Write-Host -ForegroundColor Yellow "Informe o endereço IP: " -NoNewline
$hostip = Read-Host
Invoke-WebRequest ($urlBase + "/shodan/host/" + $hostip + "?key=" + $plainKey) | ConvertFrom-Json

# Busca pela rede
Write-Host -ForegroundColor Yellow "Informe a rede no formato CIDR: " -NoNewline
$hostnet = Read-Host
$results = Invoke-WebRequest ($urlBase + "/shodan/host/search" + "?key=" + $plainKey + "&query=net:" + "$hostnet") 
$results | ConvertFrom-Json | select -expand XPTO


##########################################################################

# Consulta a partir de arquivo
$file = Get-Content "Caminho\do\arquivo.json"

$file | ConvertFrom-Json | select ip_str, port
