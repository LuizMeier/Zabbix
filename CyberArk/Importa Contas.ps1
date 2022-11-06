# Luiz Fernando 01/04/2020

# Script para importar contas no CyberArk - É pssível via CSV ou manualmente. Leia as linhas comentadas!

# Informando credenciais
Write-Host -ForegroundColor Yellow "Informe seu usuário: " -NoNewline
$usuario = Read-Host

Write-Host -ForegroundColor Yellow "Informe sua senha: " -NoNewline
$senha = Read-Host -AsSecureString
$plainSenha = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($senha))


# Preenchendo variáveis
$urlBase = "https://URL/PasswordVault/API/"

$credenciais = @{

    username = $usuario
    password = $plainSenha

} | ConvertTo-Json

# Conseguindo um token de autorização
$token = Invoke-RestMethod -Uri ($urlBase + "/auth/LDAP/Logon") -Method POST -ContentType "application/json" -Body $credenciais

# Configurando header
$headers = @{
    Authorization = $token
} 

##############################################################################

# Já possuo um token, vamos trabalhar!

# Consultar Contas
#Invoke-RestMethod -Uri ($urlBase + "Accounts") -Method POST -ContentType "application/json" -Headers $headers | ConvertTo-Json

# Adicionar contas manualmente

<# Montando Body manualmente

$body = @{
    name = ""
    address = ""
    userName = ""
    platformId = ""
    safeName = ""
    secretType = ""
    secret = ""
    platformAccountProperties =  @{
        Port = ""
        IgnoreCertificate = ""
    }
    secretManagement =  @{
        automaticManagementEnabled = ""
        manualManagementReason = ""
    }
} | ConvertTo-Json

# Envia ao Cofre
Invoke-RestMethod -Uri ($urlBase + "Accounts") -Method POST -ContentType "application/json" -Headers $headers -Body $body


#>

# Adicionar contas via csv
#$Contas = Import-Csv -Path C:\Caminho\Do\CSV.csv
$Contas = Import-Csv C:\Caminho\Do\CSV.csv | Where-Object {$_."Login Name" -eq ""}

foreach ($conta in $Contas) {

    #Montando $body
    $body = @{
        name = $conta.Account
        address = $conta."Web Site"
        userName = $conta."Login Name"
        platformId = "CyberArkPTA"
        safeName = "SAFENAME"
        secretType = "password"
        secret = $conta.Password
#        platformAccountProperties =  @{
#            Port = $conta.Port
#            IgnoreCertificate = $conta.IgnoreCertificate
#        }
        secretManagement =  @{
            automaticManagementEnabled = "False"
            manualManagementReason = "VPN"
        }
    } | ConvertTo-Json

    # Envia ao cofre
    Invoke-RestMethod -Uri ($urlBase + "Accounts") -Method POST -ContentType "application/json" -Headers $headers -Body $body

}

#>