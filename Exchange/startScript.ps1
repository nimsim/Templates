Param(
    [Parameter(Mandatory=$true)]
		[String]$domainName,

		[Parameter(Mandatory=$true)]
		[String]$vmAdminCreds
)
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://$exchangeDomainName/PowerShell/" -Authentication Kerberos -Credential $VMAdminCreds
Import-PSSession $Session
New-SendConnector -Name "To internet" -AddressSpaces * -Internet
Remove-PSSession $Session

$installPath = "$env:PUBLIC\Desktop\Hybrid"
New-Item -Path $installPath -ItemType Directory -Force 

$txtOutput = @"
Run this from command line for Certificates to be established on your server:

wacs.exe --target manual --host mail.${domainName},owa.${domainName},autodiscover.${domainName} --store centralssl --centralsslstore "C:\Central SSL" --installation iis,script --installationsiteid 1 --script "./Scripts/ImportExchange.ps1" --scriptparameters "'{CertThumbprint}' 'IIS,SMTP,IMAP' 1 '{CacheFile}' '{CachePassword}' '{CertFriendlyName}'" 
"@ | out-file -filepath $installPath\README.txt -append -width 200

$runScript = $PSScriptRoot+"\aadccert.ps1"
&$runScript $domainName $vmAdminCreds
    
