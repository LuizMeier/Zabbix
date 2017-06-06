#####################################################################################################
# Script para descoberta e retorno das propriedades de CSV em um cluster de Failover.				#
#																									#
# Script proposto para uso em processos de descoberta do Zabbix										#
#																									#
# Luiz Fernando - 02/01/2014																		#
#																									#
# Espera-se semprAe dois argumentos: args[0] para o nome do disco e args[1] para o tipo de item.	#
#####################################################################################################

# Importa o módulo de Failover para PS
Import-Module FailoverClusters

# "total" para espaço total do volume:
if ($args[1] -eq "total")
{
	$vols = Get-ClusterSharedVolume $args[0] | select -Expand SharedVolumeInfo | select -Expand Partition | ft -auto -hidetableheaders @{ Label = "Size(GB)" ; Expression = { "{0:N2}" -f ($_.Size/1024/1024/1024) }} | out-string
	$vols = $vols -replace "\.", ""
	$vols = $vols -replace ",", "."
	Write-Host $vols.Trim()
}

# "used" para espaço utilizado:
elseif ($args[1] -eq "used")
{
	$vols = Get-ClusterSharedVolume $args[0] | select -Expand SharedVolumeInfo | select -Expand Partition | ft -auto -hidetableheaders @{ Label= "UsedSpace(GB)" ; Expression = { "{0:N2}" -f ($_.UsedSpace/1024/1024/1024) } } | out-string
	$vols = $vols -replace "\.", ""
	$vols = $vols -replace ",", "."
	Write-Host $vols.Trim()
}

# "free" para espaço livre:
elseif ($args[1] -eq "free")
{
	$vols = Get-ClusterSharedVolume $args[0] | select -Expand SharedVolumeInfo | select -Expand Partition | ft -auto -hidetableheaders @{ Label ="FreeSpace(GB)" ; Expression = { "{0:N2}" -f ($_.FreeSpace/1024/1024/1024) } } | out-string
	$vols = $vols -replace "\.", ""
	$vols = $vols -replace ",", "."
	Write-Host $vols.Trim()
}

# "pfree" para porcentagem livre:
elseif ($args[1] -eq "pfree")
{
	$vols = Get-ClusterSharedVolume $args[0] | select -Expand SharedVolumeInfo | select -Expand Partition | ft -auto -hidetableheaders @{ Label = "PercentFree" ; Expression = { "{0:N2}" -f ($_.PercentFree) } } | out-string
	$vols = $vols -replace "\.", ""
	$vols = $vols -replace ",", "."
	Write-Host $vols.Trim()
}

# No caso de não serem declarados parâmetros válidos, o script serve somente para descoberta de volumes.
else
{
	$vols = Get-ClusterSharedVolume | select name | ft -hidetableheaders | out-string
	$vols = $vols.Trim()	
	
	# Conta a quantidade de itens do array
	$total = ($vols -split '[\n]').length
	$i = 0
	
	# Início do JSON
	Write-Host "{"
	Write-Host " `"data`":["
	
	foreach ($item in ($vols -split '[\n]'))
	{
		# Contador para não imprimir vírgula após o último elemento
		$i++
		$item = $item.Trim() -replace ",", "."
		if($item -ne "")
		{
			Write-Host -NoNewline "    {""{#VOLNAME}"":""$item""}"						
			# Tratando a impressão da vírgula
			If ($i -lt $total){
				Write-Host ","
			}
		}
	}	
	Write-Host
	Write-Host " ]"
	Write-Host "}"
}