[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$installPath = "$env:PUBLIC\Desktop\Hybrid"
If(!(test-path $installPath))
{
      New-Item -ItemType Directory -Force -Path $installPath
}
$outpath = "$installPath\1.AADConnect.exe"
$url = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
Invoke-WebRequest -Uri $url -OutFile $outpath

$outpath = "$installPath\ExchangeCertificatesTemp.zip"
$url = "http://github.com/PKISharp/win-acme/releases/download/v2.0.4.227/win-acme.v2.0.4.227.zip"
Invoke-WebRequest -Uri $url -OutFile $outpath

$path = "$env:PUBLIC\Desktop\Hybrid\2.ExchangeCertificates"
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}

Expand-Archive $outpath -DestinationPath $path

Remove-Item -Path $outpath

"`nDOWNLOAD SUCCESSFUL!`n 
Please follow the guide on OneNote to continue:
https://microsoft.sharepoint.com/teams/OfficePeople/_layouts/OneNote.aspx?id=%2Fteams%2FOfficePeople%2FSiteAssets%2FOffice%20People%20Notebook&wd=target%28Projects%2FTest%20Lab.one%7CA70B945C-4284-48F6-983A-30A0C55E78C1%2FExchange%202016%20Setup%20%2B%20Hybrid%20%26%20AADC%7C97D18BAD-BFC4-4C9E-92C5-AF81E1A13042%2F%29 `
The Configuration/Installation order should be: `n1. Set up Azure AD Connect `
2. Set up Exchange Certificates `n3. Set up Exchange Hybrid" | out-file -filepath $installPath\README.txt -append -width 200

Unblock-File -Path $path\Scripts\ImportExchange.ps1
