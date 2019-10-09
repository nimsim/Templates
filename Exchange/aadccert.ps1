[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$installPath = "$env:PUBLIC\Desktop\Hybrid"
$SSLPath = "C:\CentralSSL"

If(!(test-path $installPath))
{
      New-Item -ItemType Directory -Force -Path $installPath
}

If(!(test-path $SSLPath))
{
      New-Item -ItemType Directory -Force -Path $SSLPath
}

$outpath = "$installPath\1.AADConnect.exe"
$url = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
Invoke-WebRequest -Uri $url -OutFile $outpath

$outpath = "$installPath\ExchangeCertificatesTemp.zip"
$url = "http://github.com/PKISharp/win-acme/releases/download/v2.0.4.227/win-acme.v2.0.4.227.zip"
Invoke-WebRequest -Uri $url -OutFile $outpath

$path = $installPath+"\2.ExchangeCertificates"
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}

Expand-Archive $outpath -DestinationPath $path

Remove-Item -Path $outpath

$txtOutput = @"
DOWNLOAD SUCCESSFUL!
Please follow the guide on OneNote to continue:
https://microsoft.sharepoint.com/teams/OfficePeople/_layouts/OneNote.aspx?id=%2Fteams%2FOfficePeople%2FSiteAssets%2FOffice%20People%20Notebook&wd=target%28Projects%2FTest%20Lab.one%7CA70B945C-4284-48F6-983A-30A0C55E78C1%2FExchange%202016%20Setup%20%2B%20Hybrid%20%26%20AADC%7C97D18BAD-BFC4-4C9E-92C5-AF81E1A13042%2F%29 `
The Configuration/Installation order should be: 
1. Change DNS
2. Set up Azure AD Connect
3. Set up Exchange Certificates
4. Set up Exchange Hybrid
"@

$txtOutput | out-file -filepath $installPath\README.txt -append -width 200

# disable IE Enhanced Security Configuration for administrators
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 -ErrorAction Stop

Unblock-File -Path $path\Scripts\ImportExchange.ps1
