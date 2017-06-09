#####################################################################################
# THIS IS SAMPLE CODE AND IS ENTIRELY UNSUPPORTED. THIS CODE AND INFORMATION        #
# IS PROVIDED "AS-IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,    #
# INCLUDING BUT NOT LIMITED TO AN IMPLIED WARRANTY OF MERCHANTABILITY AND/OR        #
# FITNESS FOR A PARTICULAR PURPOSE.                                                 #
#####################################################################################

# 23/01/2017 - Edited by Luiz Fernando
# Original source: https://blogs.msdn.microsoft.com/carmelop/2013/04/29/how-to-monitor-application-request-routing-via-powershell/

# This script is intended to monitor an IIS Server Farm
 
# First add a reference to the MWA dll
$dll=[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
 
# Get the manager and config object
$mgr = New-Object Microsoft.Web.Administration.ServerManager
$conf = $mgr.GetApplicationHostConfiguration()
 
# Get the webFarms section
$section = $conf.GetSection("webFarms")
$webFarms = $section.GetCollection()
 
foreach ($webFarm in $webFarms)
{
    # Get the farm name
    $Name= $webFarm.GetAttributeValue("name");
    
    #Get the servers in the farm
    $servers = $webFarm.GetCollection()
}

# If option ResponseTime, then ResponseTime
if ($args[0] -eq "rt") {
    foreach ($server in $servers) {
        if ($server.RawAttributes.address -like $args[1]) {
            #Get the ARR section and values
            $arr = $server.GetChildElement("applicationRequestRouting")
            $counters = $arr.GetChildElement("counters")
            $responseTime = $counters.GetAttributeValue("responseTime")
            Write-Host $responseTime
        }
    }
}

# If option RequestPerSecond, then RequestPerSecond
elseif ($args[0] -eq "rps") {
    foreach ($server in $servers) {
        if ($server.RawAttributes.address -like $args[1]) {
            #Get the ARR section and values
            $arr = $server.GetChildElement("applicationRequestRouting")
            $counters = $arr.GetChildElement("counters")
            $responseTime = $counters.GetAttributeValue("requestPerSecond")
            Write-Host $responseTime
        }
    }
}

# If option FailedRequests, then FailedRequests
elseif ($args[0] -eq "fr") {
    foreach ($server in $servers) {
        if ($server.RawAttributes.address -like $args[1]) {
            #Get the ARR section and values
            $arr = $server.GetChildElement("applicationRequestRouting")
            $counters = $arr.GetChildElement("counters")
            $failedRequests = $counters.GetAttributeValue("failedRequests")
            Write-Host $failedRequests
        }
    }
}

# If RequestDistribution, then Requestdistribution
elseif ($args[0] -eq "rd") {
    $allRequests = 0
    foreach ($server in $servers) {
            #Get the ARR section and values
            $arr = $server.GetChildElement("applicationRequestRouting")
            $counters = $arr.GetChildElement("counters")
            $serverTotalRequests = $counters.GetAttributeValue("totalRequests")
            
            # If the current server in array is the selected server, memorize it
            if ($server.RawAttributes.address -like $args[1]) {
                $selectedServerTotalRequests = $serverTotalRequests
            }

            # $allrequests is the sum of all servers "totalRequest" parameter and $serverTotalRequests is the
            # number of total requests of the current server going through the array
            $allRequests = $allRequests + $serverTotalRequests
    }
    # Calculate the percentage of selected server and format decimal
    $requestDistribution = '{0:f2}' -f ((100 * $selectedServertotalRequests) / $allRequests)
    Write-Host $requestDistribution
}

# If option Healthy, then Healthy
elseif ($args[0] -eq "healthy") {
    foreach ($server in $servers) {
        if ($server.RawAttributes.address -like $args[1]) {
            #Get the ARR section and values
            $arr = $server.GetChildElement("applicationRequestRouting")
            $counters = $arr.GetChildElement("counters")
            $isHealthy = $counters.GetAttributeValue("isHealthy")
            if ($isHealthy -eq "True") {
                Write-Host "1"
            }
            else {
                Write-Host "0"
            }
        }
    }
}

# If no arguments were given, discover the servers in farm and print in JSON format
else {
    Write-Host "{"
    Write-Host " `"data`":["
    
    # Array counter
    $i = 0
    
    # For each server in the servers array, print
    foreach ($server in $servers) {
        $i++
        $hostname = $server.GetAttributeValue("address")
        $ip = (Resolve-DnsName $hostname -Type A).IPAddress
        Write-Host -NoNewline "    {""{#SERVERNAME}"":""$hostname"","
        Write-Host -NoNewline " ""{#SERVERIP}"":""$ip""}"
        
        # Do not print comma after the last server
        if ($i -lt $servers.Count) {
            Write-Host ","
            }
    }
    
    Write-Host
    Write-Host " ]"
    Write-Host "}"
}
