param (
	[Parameter(Mandatory)]
    [string]$uri,
	[Parameter(Mandatory)]
    [string]$destination
)

function DownloadISO {

	# Local file storage location
    $localPath = "$env:SystemDrive"
    

    # Log file
    $logFileName = "CSDownload.log"
    $logFilePath = "$localPath\$logFileName"
	
	if(Test-Path $destination) {
		"Destination path exists. Skipping ISO download" | Tee-Object -FilePath $logFilePath -Append
		return
	}
	
	$destination = Join-Path $env:SystemDrive $destination
	New-Item -Path $destination -ItemType Directory

	$destinationFile = $null
    $result = $false
	# Download ISO
	$retries = 3
	# Stop retrying after download succeeds or all retries attempted
	while(($retries -gt 0) -and ($result -eq $false)) {
		try
		{
			"Downloading ISO from URI: $uri to destination: $destination" | Tee-Object -FilePath $logFilePath -Append
			$isoFileName = [System.IO.Path]::GetFileName($uri)
			$webClient = New-Object System.Net.WebClient
			$_date = Get-Date -Format hh:mmtt
			$destinationFile = "$destination\$isoFileName"
			$webClient.DownloadFile($uri, $destinationFile)
			$_date = Get-Date -Format hh:mmtt
			if((Test-Path $destinationFile) -eq $true) {
				"Downloading ISO file succeeded at $_date" | Tee-Object -FilePath $logFilePath -Append
				$result = $true
			}
			else {
				"Downloading ISO file failed at $_date" | Tee-Object -FilePath $logFilePath -Append
				$result = $false
			}
		} catch [Exception] {
			"Failed to download ISO. Exception: $_" | Tee-Object -FilePath $logFilePath -Append
			$retries--
			if($retries -eq 0) {
				Remove-Item $destination -Force -Confirm:0 -ErrorAction SilentlyContinue
			}
		}
	}
	
	# Extract ISO
	if($result)
    {
        "Mount the image from $destinationFile" | Tee-Object -FilePath $logFilePath -Append
        $image = Mount-DiskImage -ImagePath $destinationFile -PassThru
        $driveLetter = ($image | Get-Volume).DriveLetter

        "Copy files to destination directory: $destination" | Tee-Object -FilePath $logFilePath -Append
        Robocopy.exe ("{0}:" -f $driveLetter) $destination /E | Out-Null
    
        "Dismount the image from $destinationFile" | Tee-Object -FilePath $logFilePath -Append
        Dismount-DiskImage -ImagePath $destinationFile
    
        "Delete the temp file: $destinationFile" | Tee-Object -FilePath $logFilePath -Append
        Remove-Item -Path $destinationFile -Force
    }
    else
    {
		"Failed to download the file after exhaust retry limit" | Tee-Object -FilePath $logFilePath -Append
		Remove-Item $destination -Force -Confirm:0 -ErrorAction SilentlyContinue
        Throw "Failed to download the file after exhaust retry limit"
    }
}

$installPath = "$env:PUBLIC\Desktop\Hybrid"
If(!(test-path $installPath))
{
      New-Item -ItemType Directory -Force -Path $installPath
}

$myHereString = @"
Run this from command line for Certificates to be established on your server:
wacs.exe --target manual --host mail.${domainName},owa.${domainName},autodiscover.${domainName} --store centralssl --centralsslstore "C:\Central SSL" --installation iis,script --installationsiteid 1 --script "./Scripts/ImportExchange.ps1" --scriptparameters "'{CertThumbprint}' 'IIS,SMTP,IMAP' 1 '{CacheFile}' '{CachePassword}' '{CertFriendlyName}'" 
"@ | out-file -filepath $installPath\README.txt -append -width 200
DownloadISO

"Added Readme to Hybrid" | Tee-Object -FilePath $logFilePath -Append
$runScript = $PSScriptRoot+"\aadcert.ps1"
"Running AAD Connect download and Let's Encrypt download" | Tee-Object -FilePath $logFilePath -Append
&$runScript
