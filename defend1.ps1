function testDNSBlock {
    	Get-DnsClient
    	Get-DnsClientGlobalSetting
    	Get-DnsClientServerAddress
    	$IPAddress = Resolve-DnsName isitblocked.org | Select-Object -ExpandProperty IPAddress
    	Write-Output "isitblocked.org IP address: $IPAddress"

    	if ($IPAddress -eq "74.208.236.124"){
        	Write-Output "The Host is not using DNS filtering."
    } else {
        	Write-Output "The Host is using DNS filtering."
    }
}


function enableDoH {
    	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoH" -Value 2

    	Write-Host "DNS over HTTPS has been enabled. The computer will now reboot."
    	Restart-Computer
}

function setupQuadDoH {
    	$interfaceName = "Ethernet 3"
    	Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses ("9.9.9.9")

    	$interface = Get-NetAdapter -Name $interfaceName
    	$guid = $interface.InterfaceGuid

    	$regPath = "HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\9.9.9.9"
    	if (!(Test-Path $regPath)) {
        	New-Item -Path $regPath -Force
    }

    	Set-ItemProperty -Path "$regPath" -Name "DohFlags" -Value 1
	Write-Output "Changes had been made."
}

function resetDoH() {
    	$interfaceName = "Ethernet 3"
    	Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ResetServerAddresses

    	$interface = Get-NetAdapter -Name $interfaceName
    	$guid = $interface.InterfaceGuid

    	$regPath = "HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\9.9.9.9"

    	if (Test-Path $regPath) {
        	Set-ItemProperty -Path "$regPath" -Name "DohFlags" -Value 0
    }

		Write-Output "The DNS filter has been disabled"
}
	
function preTest {
    	Write-Host "Current DNS settings:"
    	Get-DnsClient | Format-Table -AutoSize

    	$isFilteringEnabled = $false
    	$IPAddress = Resolve-DnsName isitblocked.org | Select-Object -ExpandProperty IPAddress
    	if ($IPAddress -ne "74.208.236.124") {
        	$isFilteringEnabled = $true
    }
    	if ($isFilteringEnabled) {
        	Write-Host "DNS filtering is already enabled."
    } else {
        	Write-Host "DNS filtering is not enabled."
    }

    	$isDoHEnabled = $false
    	$doHEnabledValue = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoH" | Select-Object -ExpandProperty "EnableAutoDoH"
    	if ($doHEnabledValue -eq 2) {
        	$isDoHEnabled = $true
    }
    	if ($isDoHEnabled) {
        	Write-Host "DNS over HTTPS is already enabled."
    } else {
        	Write-Host "DNS over HTTPS is not enabled."
    }
}

function setup {
    	$IPAddress = Resolve-DnsName isitblocked.org | Select-Object -ExpandProperty IPAddress
    	if ($IPAddress -ne "74.208.236.124") {
        	Write-Host "Enabling DNS filtering..."
        	Set-DnsClientServerAddress -InterfaceAlias "Ethernet 3" -ServerAddresses ("127.0.0.1")
        	Write-Host "DNS filtering enabled."
    }

    	$doHEnabledValue = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoH" | Select-Object -ExpandProperty "EnableAutoDoH"
    	if ($doHEnabledValue -ne 2) {
        	Write-Host "Enabling DNS over HTTPS..."
        	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoH" -Value 2
        	Restart-Computer
    }
    	Write-Host "DNS over HTTPS enabled."
}

function postTest {
    	Write-Host "Current DNS settings:"
    	Get-DnsClient | Format-Table -AutoSize

    	$isFilteringEnabled = $false
    	$IPAddress = Resolve-DnsName isitblocked.org | Select-Object -ExpandProperty IPAddress
    	if ($IPAddress -ne "74.208.236.124") {
        	$isFilteringEnabled = $true
    }
    	if ($isFilteringEnabled) {
        	Write-Host "DNS filtering is enabled."
    } else {
        	Write-Host "DNS filtering is not enabled."
    }
}

    	$isDoHEnabled = $false
    	$doHEnabledValue = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoH" | Select-Object -ExpandProperty "EnableAutoDoH"

$arg1 = $args[0]
	if ($arg1 -eq "DoH-test") {
	preTest
    	testDNSBlock
	postTest
}
	elseif ($arg1 -eq "DoH-enable") {
	preTest
    	enableDoH
}
	elseif ($arg1 -eq "DoH-setupQuad") {
	setup
    	setupQuadDoH
	postTest
}
	elseif ($arg1 -eq "DoH-reset") {
	resetDoH
}
	else {
    	Write-Host "Unknown argument"
}