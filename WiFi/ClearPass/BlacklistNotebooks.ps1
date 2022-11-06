# Luiz Fernando - 17/05/2019

# Script para editar os tablets dentro da base do ClearPass


# Informando credenciais do ClearPass
Write-Host -ForegroundColor Yellow "Informe seu usuário: " -NoNewline
$usuario = Read-Host

Write-Host -ForegroundColor Yellow "Informe sua senha: " -NoNewline
$senha = Read-Host -AsSecureString
$plainSenha = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($senha))

# Aqui deve informar a Id criada no ClearPass para a consulta.
Write-Host -ForegroundColor Yellow "Informe seu client_id: " -NoNewline
$id = Read-Host

# Url a ser chamada
$urlBase = "https://clearpass.paranabanco.b.br/api/"

$credenciais = @{
        
    grant_type = "password"
    username = $usuario
    password = $plainSenha
    client_id = $id

} | ConvertTo-Json

# Conseguindo um token de autorização
$retornoLogin = Invoke-RestMethod -Uri ($urlBase + "oauth") -Method POST -ContentType "application/json" -Body $credenciais

# Configurando header
$headers = @{
    Authorization = "Bearer " + $retornoLogin.access_token
    Accept = "application/json"
} 


# Possuo token, vamos consultar os endpoints que são notebooks e do domínio.
Get-ADComputer -Identity PRBNTNX86 -Properties *