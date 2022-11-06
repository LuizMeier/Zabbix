# Luiz Fernando - 17/05/2019

# Script para editar os tablets dentro da base do ClearPass

# Carrega a lista de endereços MAC
$Tablets = Get-Content 'I:\Infraestrutura\WiFi\Tablets Lojas.txt'

# Informando credenciais do ClearPass
Write-Host -ForegroundColor Yellow "Informe seu usuário: " -NoNewline
$usuario = Read-Host

Write-Host -ForegroundColor Yellow "Informe sua senha: " -NoNewline
$senha = Read-Host -AsSecureString
$plainSenha = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($senha))

# Aqui deve informar a Id criada no ClearPass para a consulta.
Write-Host -ForegroundColor Yellow "Informe seu client_id: " -NoNewline
$id = Read-Host

# Gerando um token de autorização
$urlBase = "https://clearpassdmz.paranabanco.b.br/api/"

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

# Configurando body
$body = @{
    attributes = @{
        Tablet_Loja = "true"
    }
} | ConvertTo-Json

# Já possuo um token, vamos editar os endpoints

Foreach ($endpoint in $Tablets) {
    
    Write-Host -ForegroundColor Yellow "Executando em $endpoint"
    
    # Monta nova URL (não rolou passando por parâmetro)
    $uriGet = $urlBase + "endpoint?filter=%7B%22mac_address%22%3A%20%22" + $endpoint + "%22%7D&sort=%2Bid&offset=0&limit=25&calculate_count=false"

    # Consulta o dispositivo filtrando pelo mac
    $endpointID = (Invoke-RestMethod -Uri $uriGet -Headers $headers -Method Get -ContentType "application/json")._embedded.items.id

    if ($endpointID -ne $null) {
        # Já existe no Clearpass, seta Tablet_Loja = True
        
        # Configurando body
        $body = @{
            attributes = @{
                Tablet_Loja = "true"
            }
        } | ConvertTo-Json

        $uriPatch = $urlBase + "endpoint/$endpointID"
        
        Invoke-RestMethod -Uri $uriPatch -Headers $headers -Method Patch -ContentType "application/json" -Body $body
    }

    else {
        Write-Host -ForegroundColor Yellow "$endpoint não existe no ClearPass! Criando..."

            # Configurando body
            $body = @{
                mac_address = $endpoint.ToString()
                status = "Unknown"
                attributes = @{
                    Tablet_Loja = "true"
                }
            } | ConvertTo-Json

        Invoke-RestMethod -Uri ($urlBase + "endpoint") -Headers $headers -Method Post -ContentType "application/json" -Body $body
    }
}