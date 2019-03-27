Param(
    [Parameter(Mandatory=$true)]
		[String]$fqdn,

		[Parameter(Mandatory=$true)]
		[String]$VMAdminCreds
)
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://$exchangeDomainName/PowerShell/" -Authentication Kerberos -Credential $VMAdminCreds
Import-PSSession $Session
New-SendConnector -Name "To internet" -AddressSpaces * -Internet
Remove-PSSession $Session
