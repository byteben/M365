<#	
===========================================================================
Created on:   	23/11/2020
Created by:   	Ben Whitmore
Organization: 	byteben.com
Filename:     	Get_MSOLDomainDNS.ps1
===========================================================================

1.202311.01   23/11/2020  Ben Whitmore @byteben.com
Initial Release

.DESCRIPTION
Script to check if the actual DNS records for verified domains are the expected DNS records
Requires the following PowerShell Modules:-

Install-Module -Name AzureAD / AzureADPreview
Install-Module -Name MSOnline

.EXAMPLE
Get_MSOLDomainDNS.ps1 -DNSServer "8.8.8.8"

.PARAMETER DNSServer
Specify which DNS Server to use to lookup existing DNS records

#>

Param (
    [Parameter(Mandatory = $False)]
    [String]$DNSServer = "8.8.8.8"
)

Function Get_Custom_MXRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Resolve DNS Name for existing MX Record on Verified Domain
    Try {
        Resolve-DNSName -Name $Domain -Type MX -Server $DNSServer -Erroraction Stop | Out-Null
        Resolve-DNSName -Name $Domain -Type MX -Server $DNSServer | Select-Object -ExpandProperty NameExchange -Erroraction Stop
    }
    Catch {
        Write-Host "Error getting MX Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor Red
    }
}

Function Get_Custom_TXTRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Resolve DNS Name for existing TXT Record on Verified Domain
    Try {
        Resolve-DNSName -Name $Domain -Type TXT -Server $DNSServer -ErrorAction Stop | Out-Null
        Resolve-DNSName -Name $Domain -Type TXT -Server $DNSServer | Where-Object { $_.Strings -like "v=spf*" } | Select-Object -ExpandProperty Strings -ErrorAction Stop
    }
    Catch {
        Write-Host "Error getting TXT Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor Red
    }
}
Function Get_Custom_AutoDiscoverRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Build AutoDiscover Parameter
    $AutoDiscoverCNAME = "autodiscover.$($Domain)"

    #Resolve DNS Name for existing AutoDiscover CNAME Record on Verified Domain
    Try {
        Resolve-DNSName -Name $AutoDiscoverCNAME -Type CNAME -Server $DNSServer -ErrorAction Stop | Out-Null
        Resolve-DNSName -Name $AutoDiscoverCNAME -Type CNAME -Server $DNSServer | Where-Object { $_.Type -eq "CNAME"} | Select-Object -ExpandProperty NameHost -ErrorAction Stop
    }
    Catch {
        Write-Host "Error getting Autodiscover CNAME Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor Red
    }
}

$Credentials = Get-Credential

#Import Modules - AzureADPreview can be substituted for AzureAD
Import-Module AzureADPreview
Import-Module MSOnline

#Connect to Services
Connect-MsolService -Credential $Credentials | Out-Null
Connect-AzureAD -Credential $Credentials | Out-Null

#Get a list of Verified Domains for the tenant
Write-Host "Enumerating Verified Domains..."  -ForegroundColor Green
$VerifiedDomains = Get-MsolDomain | Where-Object { ($_.Status -eq 'Verified') -and (!($_.Name -like "*onmicrosoft.com")) } | Sort-Object Name | Out-GridView -Title 'Choose a Verfied Domain(s):' -PassThru

If ($VerifiedDomains -eq $Null) {
    Write-Host "No Verified Domains were selected or the operation was cancelled by the user" -ForegroundColor Red
    Exit 1
}
else {
    Write-Host "The following Verified Domains were selected:" -ForegroundColor Green
    Foreach ($Domain in $VerifiedDomains) {
        Write-Host $Domain.Name | Out-Host
    }

    Write-Host "Checking DNS Records for selected Domains..." -ForegroundColor Green

    Foreach ($Domain in $VerifiedDomains) {
        Write-Host "--------------------------------------" -ForegroundColor Green
        Write-Host $Domain.Name -ForegroundColor Green
        Write-Host "--------------------------------------" -ForegroundColor Green
        
        #Check MX Record
        Write-Host "MX Record for Verfied Domain is:"
        $Custom_MXRecordResult = Get_Custom_MXRecord -Domain $Domain.Name -DNSServer $DNSServer
        Write-Host $Custom_MXRecordResult -ForegroundColor Yellow
        
        #Get Expected MX Record
        Write-Host "Expected MX Record for Verfied Domain is:"
        Try {
            $MS_MXRecordResult = Get-AzureADDomainServiceConfigurationRecord -Name $Domain.Name | Where-Object { $_.RecordType -eq "MX" } | Select-Object -ExpandProperty MailExchange -ErrorAction Stop
            Write-Host $MS_MXRecordResult -ForegroundColor Yellow
        } 
        Catch {
            Write-Host "Could not verify expected MX Record for $($Domain.Name)" -ForegroundColor Red
        }

        #Check TXT Record
        Write-Host "TXT Record for Verfied Domain is:"
        Try {
            $Custom_TXTRecordResult = Get_Custom_TXTRecord -Domain $Domain.Name -DNSServer $DNSServer
            Write-Host $Custom_TXTRecordResult -ForegroundColor Yellow
        } 
        Catch {
            Write-Host "Could not verify TXT Record for $($Domain.Name)" -ForegroundColor Red
        }
        
        #Get Expected TXT Record
        Write-Host "Expected TXT Record for Verfied Domain is:"
        Try {
            $MS_TXTRecordResult = Get-AzureADDomainServiceConfigurationRecord -Name $Domain.Name | Where-Object { $_.RecordType -eq "TXT" } | Select-Object -ExpandProperty Text -ErrorAction Stop
            Write-Host $MS_TXTRecordResult -ForegroundColor Yellow
        } 
        Catch {
            Write-Host "Could not verify expected TXT Record for $($Domain.Name)" -ForegroundColor Red
        }
        
        #Check Autodiscover CNAME Record
        Write-Host "Autodiscover CNAME Record for Verfied Domain is:"
        $Custom_AutoDiscoverRecordResult = Get_Custom_AutoDiscoverRecord -Domain $Domain.Name -DNSServer $DNSServer
        Write-Host $Custom_AutoDiscoverRecordResult -ForegroundColor Yellow
        
        #Get Expected Autodiscover CNAME Record
        Write-Host "Expected Autodiscover CNAME Record for Verfied Domain is:"
        Try {
            $MS_AutoDiscoverRecordResult = Get-AzureADDomainServiceConfigurationRecord -Name $Domain.Name | Where-Object { ($_.RecordType -eq "CNAME") -and ($_.SupportedService -eq "Email") } | Select-Object -ExpandProperty Label -ErrorAction Stop
            Write-Host $MS_AutoDiscoverRecordResult -ForegroundColor Yellow
        } 
        Catch {
            Write-Host "Could not verify expected AutoDiscover CNAME Record for $($Domain.Name)" -ForegroundColor Red
        }
    }
}
#Disconect remote PowerShell session
#Disconnect-AzureAD -Confirm:$False