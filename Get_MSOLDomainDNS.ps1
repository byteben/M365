<#	
===========================================================================
Created on:   	23/11/2020
Created by:   	Ben Whitmore
Organization: 	byteben.com
Filename:     	Get_MSOLDomainDNS.ps1
===========================================================================

1.202311.02   23/11/2020  Ben Whitmore @byteben.com
Added 3 Functions to query existing DNS Records and Catch any errors

1.202311.01   23/11/2020  Ben Whitmore @byteben.com
Initial Release

1.240501.01   05/01/2023  Håvard Øverås #HavardOveras
Converted to Microsoft Graph SDK

.DESCRIPTION
Script to check if the actual DNS records for verified domains are the expected DNS records
Requires the following PowerShell Module:

Install-Module -Name Install-Module -Name Microsoft.Graph

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
        Write-Host "Error getting MX Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor $ErrorColor
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
        Write-Host "Error getting TXT Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor $ErrorColor
    }
}
Function Get_Custom_AutoDiscoverRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Build Record Parameter
    $AutoDiscoverCNAME = "autodiscover.$($Domain)"

    #Resolve DNS Name for existing AutoDiscover CNAME Record on Verified Domain
    Try {
        Resolve-DNSName -Name $AutoDiscoverCNAME -Type CNAME -Server $DNSServer -ErrorAction Stop | Out-Null
        $Record = Resolve-DNSName -Name $AutoDiscoverCNAME -Type CNAME -Server $DNSServer | Where-Object { $_.Type -eq "CNAME" } | Select-Object -ExpandProperty NameHost -ErrorAction Continue 
        If ($Record -eq $Null) { $Record = "Missing: Record Not Found" }
        $Record
    }
    Catch {
        Write-Host "Error getting Autodiscover CNAME Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor $ErrorColor
    }
}

Function Get_Custom_SIPRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Build Record Parameter
    $SIPCNAME = "sip.$($Domain)"

    #Resolve DNS Name for existing SIP CNAME Record on Verified Domain
    Try {
        Resolve-DNSName -Name $SIPCNAME -Type CNAME -Server $DNSServer -ErrorAction Stop | Out-Null
        $Record = Resolve-DNSName -Name $SIPCNAME -Type CNAME -Server $DNSServer | Where-Object { $_.Type -eq "CNAME" } | Select-Object -ExpandProperty NameHost -ErrorAction Continue 
        If ($Record -eq $Null) { $Record = "Missing: Record Not Found" }
        $Record
    }
    Catch {
        Write-Host "Error getting SIP CNAME Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor $ErrorColor
    }
}

Function Get_Custom_LyncDiscoverRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Build Record Parameter
    $LyncDiscoverCNAME = "lyncdiscover.$($Domain)"

    #Resolve DNS Name for existing AutoDiscover CNAME Record on Verified Domain
    Try {
        Resolve-DNSName -Name $LyncDiscoverCNAME -Type CNAME -Server $DNSServer -ErrorAction Stop | Out-Null
        $Record = Resolve-DNSName -Name $LyncDiscoverCNAME -Type CNAME -Server $DNSServer | Where-Object { $_.Type -eq "CNAME" } | Select-Object -ExpandProperty NameHost -ErrorAction Continue 
        If ($Record -eq $Null) { $Record = "Missing: Record Not Found" }
        $Record
    }
    Catch {
        Write-Host "Error getting LyncDiscover CNAME Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor $ErrorColor
    }
}

Function Get_Custom_SIPTLSRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Build Record Parameter
    $SIPTLSSRV = "_sip._tls.$($Domain)"

    #Resolve DNS Name for existing SIP TLS Record on Verified Domain
    Try {
        Resolve-DNSName -Name $SIPTLSSRV -Type SRV -Server $DNSServer -ErrorAction Stop | Out-Null
        Resolve-DNSName -Name $SIPTLSSRV -Type SRV -Server $DNSServer | Where-Object { $_.Type -eq "SRV" } | Select-Object Name, Port, Priority, Weight -ErrorAction Stop
    }
    Catch {
        Write-Host "Error getting SIP TLS SRV Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor $ErrorColor
    }
}

Function Get_Custom_SIPFederationTLSRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Build Record Parameter
    $SIPFederationTLSSRV = "_sipfederationtls._tcp.$($Domain)"

    #Resolve DNS Name for existing SIP Federation TLS Record on Verified Domain
    Try {
        Resolve-DNSName -Name $SIPFederationTLSSRV -Type SRV -Server $DNSServer -ErrorAction Stop | Out-Null
        Resolve-DNSName -Name $SIPFederationTLSSRV -Type SRV -Server $DNSServer | Where-Object { $_.Type -eq "SRV" } | Select-Object Name, Port, Priority, Weight -ErrorAction Stop
    }
    Catch {
        Write-Host "Error getting SIP Federation TLS SRV Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor $ErrorColor
    }
}

Function Get_Custom_EnterpriseRegistrationRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Build Record Parameter
    $EnterpriseRegistrationCNAME = "enterpriseregistration.$($Domain)"

    #Resolve DNS Name for existing Enterprise Registration CNAME Record on Verified Domain
    Try {
        Resolve-DNSName -Name $EnterpriseRegistrationCNAME -Type CNAME -Server $DNSServer -ErrorAction Stop | Out-Null
        $Record = Resolve-DNSName -Name $EnterpriseRegistrationCNAME -Type CNAME -Server $DNSServer | Where-Object { $_.Type -eq "CNAME" } | Select-Object -ExpandProperty NameHost -ErrorAction Continue 
        If ($Record -eq $Null) { $Record = "Missing: Record Not Found" }
        $Record
    }
    Catch {
        Write-Host "Error getting Enterprise Registration CNAME Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor $ErrorColor
    }
}

Function Get_Custom_EnterpriseEnrollmentRecord {
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Domain,
        [String]$DNSServer
    )

    #Build Record Parameter
    $EnterpriseEnrollmentCNAME = "enterpriseenrollment.$($Domain)"

    #Resolve DNS Name for existing Enterprise Enrollment CNAME Record on Verified Domain
    Try {
        Resolve-DNSName -Name $EnterpriseEnrollmentCNAME -Type CNAME -Server $DNSServer -ErrorAction Stop | Out-Null
        $Record = Resolve-DNSName -Name $EnterpriseEnrollmentCNAME -Type CNAME -Server $DNSServer | Where-Object { $_.Type -eq "CNAME" } | Select-Object -ExpandProperty NameHost -ErrorAction Continue 
        If ($Record -eq $Null) { $Record = "Missing: Record Not Found" }
        $Record
    }
    Catch {
        Write-Host "Error getting Enterprise Enrollment CNAME Record for $Domain. Error: $($Error[0].Exception.Message)" -ForegroundColor $ErrorColor
    }
}

#Set Colour Preference
$CustomRecordColor = "Cyan"
$MSRecordColor = "Yellow"
$ErrorColor = "Red"

#Import Module
Import-Module Microsoft.Graph.Identity.DirectoryManagement

#Connect to Graph
Connect-MgGraph -NoWelcome -Scopes Domain.Read.All

#Get a list of Verified Domains for the tenant
Write-Host "Enumerating Verified Domains..."  -ForegroundColor Green
$VerifiedDomains = Get-MgDomain | Where-Object { ($_.IsVerified -eq '$true') -and (!($_.Id -like "*onmicrosoft.com")) } | Sort-Object Id #| Out-GridView -Title 'Choose a Verified Domain(s):' -PassThru

If ($VerifiedDomains -eq $Null) {
    Write-Host "No Verified Domains were selected or the operation was cancelled by the user" -ForegroundColor $ErrorColor
    Exit 1
}
else {
    Write-Host "The following Verified Domains were selected:" -ForegroundColor Green
    Foreach ($Domain in $VerifiedDomains) {
        Write-Host $Domain.Id | Out-Host
    }

    Write-Host "Checking DNS Records for selected Domains..." -ForegroundColor Green

    Foreach ($Domain in $VerifiedDomains) {
        Write-Host "--------------------------------------" -ForegroundColor Green
        Write-Host $Domain.Id -ForegroundColor Green
        Write-Host "--------------------------------------" -ForegroundColor Green

        #Start Checking Records
        Write-Host "--------------------------------------" -ForegroundColor White
        Write-Host "Exchange Online Records" -ForegroundColor White
        Write-Host "--------------------------------------" -ForegroundColor White
        
        #Check MX Record
        Write-Host "MX Record for Verified Domain is:"
        $Custom_MXRecordResult = Get_Custom_MXRecord -Domain $Domain.Id -DNSServer $DNSServer
        Write-Host $Custom_MXRecordResult -ForegroundColor $CustomRecordColor

        #Get Expected MX Record
        Write-Host "Expected MX Record for Verified Domain is:"
        Try {
            
            $MS_MXRecordResult = (Get-MgDomainServiceConfigurationRecord -DomainId $Domain.Id | Where-Object { $_.RecordType -eq "MX" } | Select-Object -ExpandProperty AdditionalProperties -ErrorAction Stop).mailExchange
            Write-Host $MS_MXRecordResult -ForegroundColor $MSRecordColor
        } 
        Catch {
            Write-Host "Could not verify expected MX Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }

        #Check TXT Record
        Write-Host "TXT Record for Verified Domain is:"
        Try {
            $Custom_TXTRecordResult = Get_Custom_TXTRecord -Domain $Domain.Id -DNSServer $DNSServer
            Write-Host $Custom_TXTRecordResult -ForegroundColor $CustomRecordColor
        } 
        Catch {
            Write-Host "Could not verify TXT Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }
        
        #Get Expected TXT Record
        Write-Host "Expected TXT Record for Verified Domain is:"
        Try {
            $MS_TXTRecordResult = (Get-MgDomainServiceConfigurationRecord -DomainId $Domain.Id | Where-Object { $_.RecordType -eq "TXT" } | Select-Object -ExpandProperty AdditionalProperties -ErrorAction Stop).text
            Write-Host $MS_TXTRecordResult -ForegroundColor $MSRecordColor
        } 
        Catch {
            Write-Host "Could not verify expected TXT Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }
        
        #Check Autodiscover CNAME Record
        Write-Host "Autodiscover CNAME Record for Verified Domain is:"
        $Custom_AutoDiscoverRecordResult = Get_Custom_AutoDiscoverRecord -Domain $Domain.Id -DNSServer $DNSServer
        Write-Host $Custom_AutoDiscoverRecordResult -ForegroundColor $CustomRecordColor
        
        #Get Expected Autodiscover CNAME Record
        Write-Host "Expected Autodiscover CNAME Record for Verified Domain is:"
        Try {
            $MS_AutoDiscoverRecordResult = (Get-MgDomainServiceConfigurationRecord -DomainId $Domain.Id | Where-Object { ($_.RecordType -eq "CNAME") -and ($_.SupportedService -eq "Email") } | Select-Object -ExpandProperty AdditionalProperties -ErrorAction Stop).canonicalName
            Write-Host $MS_AutoDiscoverRecordResult -ForegroundColor $MSRecordColor
        } 
        Catch {
            Write-Host "Could not verify expected AutoDiscover CNAME Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }

        Write-Host "--------------------------------------" -ForegroundColor White
        Write-Host "Skype for Business Records" -ForegroundColor White
        Write-Host "--------------------------------------" -ForegroundColor White

        #Check SIP CNAME Record
        Write-Host "SIP CNAME Record for Verified Domain is:"
        $Custom_SIPRecordResult = Get_Custom_SIPRecord -Domain $Domain.Id -DNSServer $DNSServer
        Write-Host $Custom_SIPRecordResult -ForegroundColor $CustomRecordColor
        
        #Get Expected SIP CNAME Record
        Write-Host "Expected SIP CNAME Record for Verified Domain is:"
        Try {
            $MS_SIPRecordResult = (Get-MgDomainServiceConfigurationRecord -DomainId $Domain.Id | Where-Object { ($_.Label -like "*sip*") -and ($_.RecordType -eq "CNAME") -and ($_.SupportedService -eq "OfficeCommunicationsOnline") } | Select-Object -ExpandProperty AdditionalProperties -ErrorAction Stop).canonicalName
            Write-Host $MS_SIPRecordResult -ForegroundColor $MSRecordColor
        } 
        Catch {
            Write-Host "Could not verify expected SIP CNAME Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }

        #Check LyncDiscover CNAME Record
        Write-Host "LyncDiscover CNAME Record for Verified Domain is:"
        $Custom_LyncDiscoverRecordResult = Get_Custom_LyncDiscoverRecord -Domain $Domain.Id -DNSServer $DNSServer
        Write-Host $Custom_LyncDiscoverRecordResult -ForegroundColor $CustomRecordColor
        
        #Get Expected LyncDiscover CNAME Record
        Write-Host "Expected LyncDiscover CNAME Record for Verified Domain is:"
        Try {
            $MS_LyncDiscoverRecordResult = (Get-MgDomainServiceConfigurationRecord -DomainId $Domain.Id | Where-Object { ($_.Label -like "*lyncdiscover*") -and ($_.RecordType -eq "CNAME") -and ($_.SupportedService -eq "OfficeCommunicationsOnline") } | Select-Object -ExpandProperty AdditionalProperties -ErrorAction Stop).canonicalName
            Write-Host $MS_LyncDiscoverRecordResult -ForegroundColor $MSRecordColor
        } 
        Catch {
            Write-Host "Could not verify expected LyncDiscover CNAME Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }

        #Check SIP TLS SRV Record
        Write-Host "SIP TLS SRV Record for Verified Domain is:"
        $Custom_SIPTLSRecordResult = Get_Custom_SIPTLSRecord -Domain $Domain.Id -DNSServer $DNSServer
        Write-Host $Custom_SIPTLSRecordResult -ForegroundColor $CustomRecordColor
        
        #Get Expected SIP TLS SRV Record
        Write-Host "Expected SIP TLS SRV Record for Verified Domain is:"
        Try {
            $MS_SIPTLSRecordResult = Get-MgDomainServiceConfigurationRecord -DomainId $Domain.Id | Where-Object { ($_.Label -like "_sip._tls*") -and ($_.RecordType -eq "SRV") -and ($_.SupportedService -eq "OfficeCommunicationsOnline") } | Select-Object @{Name='NameTarget';Expression={$_.AdditionalProperties.nameTarget}}, @{Name='Protocol';Expression={$_.AdditionalProperties.protocol}},  @{Name='Service';Expression={$_.AdditionalProperties.service}}, @{Name='Port';Expression={$_.AdditionalProperties.port}}, @{Name='Priority';Expression={$_.AdditionalProperties.priority}}, @{Name='Weight';Expression={$_.AdditionalProperties.weight}}
            Write-Host $MS_SIPTLSRecordResult -ForegroundColor $MSRecordColor
        } 
        Catch {
            Write-Host "Could not verify expected SIP TLS SRV Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }

        #Check SIP Federation TLS SRV Record
        Write-Host "SIP TLS SRV Record for Verified Domain is:"
        $Custom_SIPFederationTLSRecordResult = Get_Custom_SIPFederationTLSRecord -Domain $Domain.Id -DNSServer $DNSServer
        Write-Host $Custom_SIPFederationTLSRecordResult -ForegroundColor $CustomRecordColor
        
        #Get Expected SIP Federation TLS SRV Record
        Write-Host "Expected SIP Federation TLS SRV Record for Verified Domain is:"
        Try {
            $MS_SIPFederationTLSRecordResult = Get-MgDomainServiceConfigurationRecord -DomainId $Domain.Id | Where-Object { ($_.Label -like "_sipFederationtls*") -and ($_.RecordType -eq "SRV") -and ($_.SupportedService -eq "OfficeCommunicationsOnline") } | Select-Object @{Name='NameTarget';Expression={$_.AdditionalProperties.nameTarget}}, @{Name='Protocol';Expression={$_.AdditionalProperties.protocol}},  @{Name='Service';Expression={$_.AdditionalProperties.service}}, @{Name='Port';Expression={$_.AdditionalProperties.port}}, @{Name='Priority';Expression={$_.AdditionalProperties.priority}}, @{Name='Weight';Expression={$_.AdditionalProperties.weight}}

            Write-Host $MS_SIPFederationTLSRecordResult -ForegroundColor $MSRecordColor
        } 
        Catch {
            Write-Host "Could not verify expected SIP Federation TLS SRV Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }

        #Start Checking Records
        Write-Host "--------------------------------------" -ForegroundColor White
        Write-Host "Basic Mobility & Security Records" -ForegroundColor White
        Write-Host "--------------------------------------" -ForegroundColor White
        
        #Check Enterprise Registration Record
        Write-Host "Enterprise Registration Record for Verified Domain is:"
        $Custom_EnterpriseRegistrationRecordResult = Get_Custom_EnterpriseRegistrationRecord -Domain $Domain.Id -DNSServer $DNSServer
        Write-Host $Custom_EnterpriseRegistrationRecordResult -ForegroundColor $CustomRecordColor

        #Get Expected Enterprise Registration Record
        Write-Host "Expected Enterprise Registration Record for Verified Domain is:"
        Try {
            $MS_EnterpriseRegistrationRecordResult = (Get-MgDomainServiceConfigurationRecord -DomainId $Domain.Id | Where-Object { ($_.Label -like "enterpriseregistration*") -and ($_.RecordType -eq "CNAME") -and ($_.SupportedService -eq "Intune") } | Select-Object -ExpandProperty AdditionalProperties -ErrorAction Stop).canonicalName
            Write-Host $MS_EnterpriseRegistrationRecordResult -ForegroundColor $MSRecordColor
        } 
        Catch {
            Write-Host "Could not verify expected Enterprise Registration Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }

        #Check Enterprise Enrollment Record
        Write-Host "Enterprise Enrollment Record for Verified Domain is:"
        $Custom_EnterpriseEnrollmentRecordResult = Get_Custom_EnterpriseEnrollmentRecord -Domain $Domain.Id -DNSServer $DNSServer
        Write-Host $Custom_EnterpriseEnrollmentRecordResult -ForegroundColor $CustomRecordColor

        #Get Expected Enterprise Enrollment Record
        Write-Host "Expected Enterprise Enrollment Record for Verified Domain is:"
        Try {
            $MS_EnterpriseEnrollmentRecordResult = (Get-MgDomainServiceConfigurationRecord -DomainId $Domain.Id | Where-Object { ($_.Label -like "enterpriseenrollment*") -and ($_.RecordType -eq "CNAME") -and ($_.SupportedService -eq "Intune") } | Select-Object -ExpandProperty AdditionalProperties -ErrorAction Stop).canonicalName
            Write-Host $MS_EnterpriseEnrollmentRecordResult -ForegroundColor $MSRecordColor
        } 
        Catch {
            Write-Host "Could not verify expected Enterprise Enrollment Record for $($Domain.Id)" -ForegroundColor $ErrorColor
        }
    }
}
#Disconect Graph SDK session
Disconnect-MgGraph
