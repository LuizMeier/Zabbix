# Script exemplo para workshop Zabbix
#																									#
# Luiz Fernando - 30/04/2021																		#
#																									#


if ($args[0] -eq "discovery")
{
	$files = Get-ChildItem -Path $args[1] | where { ! $_.PSIsContainer }
		
	# Counting the total items on the array
	$total = ($files -split '[\n]').length
	$i = 0
	
	# Begin JSON
	Write-Host "{"
	Write-Host " `"data`":["
	
	foreach ($item in ($files -split '[\n]'))
	{
		# Count avoid printing comma after the last value
		$i++
		#$item = $item.Trim() -replace ",", "."
		if($item -ne "")
		{
			Write-Host -NoNewline "    {""{#FILENAME}"":""$item""}"				
			# Dealing with the comma
			If ($i -lt $total){
				Write-Host ","
			}
		}
	}	
	Write-Host
	Write-Host " ]"
	Write-Host "}"
}

elseif ($args[0] -eq "size")
{
	$file = Get-ChildItem -Path $args[1]
	$file.Length
}

# "used" to used space:
elseif ($args[0] -eq "lastWrite")
{
	$file = Get-ChildItem -Path $args[1]
	$file.LastWriteTime.ToString("dd-MM-yyyy")
}

else {
    Write-Host -ForegroundColor Red "Informe um parâmetro"
}