[CmdletBinding()]
Param (
    [Parameter(Mandatory = $True)]
    [String]$Domain
)
Write-Output "`n#################"
Write-Output "DKIM/DMARC Records"
Write-Output "#################"
Resolve-DNSName -Type CNAME -Name "selector1._domainkey.$Domain" | Select-Object -First 1 -Property Name, Type, TTL, NameHost
Resolve-DNSName -Type CNAME -Name "selector2._domainkey.$Domain"  | Select-Object -First 1 -Property Name, Type, TTL, NameHost
Resolve-DNSName -Type TXT -Name "_dmarc.$Domain"
Write-Output "`n#################"
Write-Output "SPF Record"
Write-Output "#################"
(Resolve-DnsName -Type TXT -Name $Domain).Strings | Where-Object {$_ -like "v=spf*"}  