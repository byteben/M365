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

$Credentials = Get-Credential

#Import Modules - AzureADPreview can be substituted for AzureAD
Import-Module AzureADPreview
Import-Module MSOnline

#Connect to Services
Connect-MsolService -Credential $Credentials | Out-Null
Connect-AzureAD -Credential $Credentials | Out-Null

#Resolve DNS Name for existing MX Record on Verified Domain
$Custom_MXRecord = 'Resolve-DNSName -Name $Domain.Name -Type MX -Server $DNSServer | Select-Object -ExpandProperty NameExchange'

$Custom_TXTRecord = 'Resolve-DNSName -Name $Domain.Name -Type TXT -Server $DNSServer | Where-Object {$_.Strings -like "v=spf*"}| Select-Object -ExpandProperty Strings'

#Get Expected DNS Record for Verified Domain
$MS_MXRecord = 'Get-AzureADDomainServiceConfigurationRecord -Name $Domain.Name | Where-Object {$_.RecordType -eq "MX"} | Select-Object -ExpandProperty MailExchange'

$MS_TXTRecord = 'Get-AzureADDomainServiceConfigurationRecord -Name $Domain.Name | Where-Object {$_.RecordType -eq "TXT"} | Select-Object -ExpandProperty Text'

#Get a list of Verified Domains for the tenant
Write-Host "Enumarting Verified Domains..."  -ForegroundColor Green
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
        Try {
            $Custom_MXRecordResult = Invoke-Expression $Custom_MXRecord -ErrorAction Continue
            Write-Host $Custom_MXRecordResult -ForegroundColor Yellow
        } 
        Catch {
            Write-Host "Could not verify MX Record for $($Domain.Name)" -ForegroundColor Red
        }
        
        #Get Expected MX Record
        Write-Host "Expected MX Record for Verfied Domain is:"
        Try {
            $MS_MXRecordResult = Invoke-Expression $MS_MXRecord -ErrorAction Continue
            Write-Host $MS_MXRecordResult -ForegroundColor Yellow
        } 
        Catch {
            Write-Host "Could not verify expected MX Record for $($Domain.Name)" -ForegroundColor Red | Out-Host
        }
        
        #Check TXT Record
        Write-Host "TXT Record for Verfied Domain is:"
        Try {
            $Custom_TXTRecordResult = Invoke-Expression $Custom_TXTRecord -ErrorAction Continue
            Write-Host $Custom_TXTRecordResult -ForegroundColor Yellow
        } 
        Catch {
            Write-Host "Could not verify TXT Record for $($Domain.Name)" -ForegroundColor Red
        }
        
        #Get Expected TXT Record
        Write-Host "Expected TXT Record for Verfied Domain is:"
        Try {
            $MS_TXTRecordResult = Invoke-Expression $MS_TXTRecord -ErrorAction Continue
            Write-Host $MS_TXTRecordResult -ForegroundColor Yellow
        } 
        Catch {
            Write-Host "Could not verify expected TXT Record for $($Domain.Name)" -ForegroundColor Red | Out-Host
        }
        
    }
}
#Disconect remote PowerShell session
Disconnect-AzureAD -Confirm:$False