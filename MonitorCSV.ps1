# Script intended to discover and collect the status of cluster shared volumes in a failover cluster using Zabbix
#																									#
# Luiz Fernando - 02/01/2014																		#
#																									#
# It expects two arguments: args[0] is the disk name and[1] is the information you want


# Import the FailoverCluster module
Import-Module FailoverClusters

# "total" to the total colume size:
if ($args[1] -eq "total")
{
	$vols = Get-ClusterSharedVolume $args[0] | select -Expand SharedVolumeInfo | select -Expand Partition | ft -auto -hidetableheaders @{ Label = "Size(GB)" ; Expression = { "{0:N2}" -f ($_.Size/1024/1024/1024) }} | out-string
	$vols = $vols -replace "\.", ""
	$vols = $vols -replace ",", "."
	Write-Host $vols.Trim()
}

# "used" to used space:
elseif ($args[1] -eq "used")
{
	$vols = Get-ClusterSharedVolume $args[0] | select -Expand SharedVolumeInfo | select -Expand Partition | ft -auto -hidetableheaders @{ Label= "UsedSpace(GB)" ; Expression = { "{0:N2}" -f ($_.UsedSpace/1024/1024/1024) } } | out-string
	$vols = $vols -replace "\.", ""
	$vols = $vols -replace ",", "."
	Write-Host $vols.Trim()
}

# "free" to free space:
elseif ($args[1] -eq "free")
{
	$vols = Get-ClusterSharedVolume $args[0] | select -Expand SharedVolumeInfo | select -Expand Partition | ft -auto -hidetableheaders @{ Label ="FreeSpace(GB)" ; Expression = { "{0:N2}" -f ($_.FreeSpace/1024/1024/1024) } } | out-string
	$vols = $vols -replace "\.", ""
	$vols = $vols -replace ",", "."
	Write-Host $vols.Trim()
}

# "pfree" to free space (in %):
elseif ($args[1] -eq "pfree")
{
	$vols = Get-ClusterSharedVolume $args[0] | select -Expand SharedVolumeInfo | select -Expand Partition | ft -auto -hidetableheaders @{ Label = "PercentFree" ; Expression = { "{0:N2}" -f ($_.PercentFree) } } | out-string
	$vols = $vols -replace "\.", ""
	$vols = $vols -replace ",", "."
	Write-Host $vols.Trim()
}

# If there is no declared argument, discover the volumes.
else
{
	$vols = Get-ClusterSharedVolume | select name | ft -hidetableheaders | out-string
	$vols = $vols.Trim()	
	
	# Counting the total items on the array
	$total = ($vols -split '[\n]').length
	$i = 0
	
	# Begin JSON
	Write-Host "{"
	Write-Host " `"data`":["
	
	foreach ($item in ($vols -split '[\n]'))
	{
		# Count avoid printing comma after the last value
		$i++
		$item = $item.Trim() -replace ",", "."
		if($item -ne "")
		{
			Write-Host -NoNewline "    {""{#VOLNAME}"":""$item""}"						
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
