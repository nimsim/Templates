param (
	[Parameter(Mandatory)]
	[string]$domainname
)

$installPath = "$env:PUBLIC\Desktop\Hybrid"
New-Item -Path $installPath -ItemType Directory -Force 

$txtOutput = @"
Run this from command line for Certificates to be established on your server:

wacs.exe --target manual --host mail.${domainName},owa.${domainName},autodiscover.${domainName} --store centralssl --centralsslstore "C:\Central SSL" --installation iis,script --installationsiteid 1 --script "./Scripts/ImportExchange.ps1" --scriptparameters "'{CertThumbprint}' 'IIS,SMTP,IMAP' 1 '{CacheFile}' '{CachePassword}' '{CertFriendlyName}'" 
"@ | out-file -filepath $installPath\README.txt -append -width 200

$runScript = $PSScriptRoot+"\aadccert.ps1"
&$runScript
    
