#
# Copyright="© Microsoft Corporation. All rights reserved."
#

configuration InstallAndConfigureExchange
{
	param
    (
		[Parameter(Mandatory=$true)]
		[String]$DomainName,

		[Parameter(Mandatory=$true)]
		[String]$StorageSize,

		[Parameter(Mandatory=$true)]
		[PSCredential]$VMAdminCreds,

		[Parameter(Mandatory=$true)]
		[String]$Location
	)

	$DomainCreds = [System.Management.Automation.PSCredential]$DomainFQDNCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($VMAdminCreds.UserName)", $VMAdminCreds.Password)

	Import-DscResource -ModuleName 'PSDesiredStateConfiguration';
	Import-DscResource -ModuleName xActiveDirectory;
	Import-DscResource -ModuleName xDisk;
	Import-DscResource -ModuleName xDownloadFile;
	Import-DscResource -ModuleName xDownloadISO;
    Import-DscResource -ModuleName xExchange;
	Import-DscResource -ModuleName xExchangeValidate;
	Import-DscResource -ModuleName xExtract;
	Import-DscResource -ModuleName xInstaller;
	Import-DscResource -ModuleName xPendingReboot;
	Import-DscResource -ModuleName xPSDesiredStateConfiguration;
	Import-DscResource -ModuleName xPSWindowsUpdate;

	# Downloaded file storage location
	$downloadPath = "$env:SystemDrive\DownloadsForDSC";
	$downloadAAD = "$env:SystemDrive\DownloadsForHybrid";
	$exchangeInstallerPath = "$env:SystemDrive\InstallerExchange";
	$diskNumber = 2;

	Node localhost
    {
		xWaitforDisk Disk2
        {
            DiskNumber = $diskNumber
            RetryIntervalSec = 60
            RetryCount = 60
        }
        xDisk Volume
        {
			DiskNumber = $diskNumber
            DriveLetter = 'F'
			DependsOn = '[xWaitforDisk]Disk2'
        }
		xPSWindowsUpdate InstallNet45
		{
			KBArticleID = "2934520"
			DependsOn = '[xDisk]Volume'
		}
		# Reboot node if necessary
		xPendingReboot RebootPostInstallNet45
        {
            Name      = "AfterNet452"
			DependsOn = "[xPSWindowsUpdate]InstallNet45"
        }
		# Install Exchange 2016 Pre-requisits | Reference: https://technet.microsoft.com/en-us/library/bb691354(v=exchg.160).aspx
		# Active Directory
		WindowsFeature RSATADDS {
			Name = "RSAT-ADDS"
            Ensure = "Present"
			DependsOn = "[xPendingReboot]RebootPostInstallNet45"
		}
		# Mailbox Server Role
		WindowsFeature HTTPActivation {
			Name = "AS-HTTP-Activation"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]RSATADDS"
		}
		# Media Foundation
		WindowsFeature MediaFoundationInstall 
        {
            Name = "Server-Media-Foundation"
			Ensure = "Present"
			DependsOn = "[WindowsFeature]HTTPActivation"
        }
		xPendingReboot RebootPostMediaFoundationInstall
        {
           	Name = "AfterADDSInstall"
           	DependsOn = "[WindowsFeature]MediaFoundationInstall"
        }
		WindowsFeature Net45Features {
			Name = "NET-Framework-45-Features"
            Ensure = "Present"
			DependsOn = "[xPendingReboot]RebootPostMediaFoundationInstall"
		}
		WindowsFeature RPCOverHTTPProxy {
			Name = "RPC-over-HTTP-proxy"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]Net45Features"
		}
		WindowsFeature RSATClustering {
			Name = "RSAT-Clustering"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]RPCOverHTTPProxy"
		}
		WindowsFeature RSATClusteringCmd {
			Name = "RSAT-Clustering-CmdInterface"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]RSATClustering"
		}
		WindowsFeature RSATClusteringMgmt {
			Name = "RSAT-Clustering-Mgmt"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]RSATClusteringCmd"
		}
		WindowsFeature RSATClusteringPS {
			Name = "RSAT-Clustering-PowerShell"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]RSATClusteringMgmt"
		}
		WindowsFeature WASProcessModel {
			Name = "WAS-Process-Model"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]RSATClusteringPS"
		}
		WindowsFeature WebAspNet45 {
			Name = "Web-Asp-Net45"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WASProcessModel"
		}
		WindowsFeature WebBasicAuth {
			Name = "Web-Basic-Auth"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebAspNet45"
		}
		WindowsFeature WebClientAuth {
			Name = "Web-Client-Auth"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebBasicAuth"
		}
		WindowsFeature WebDigestAuth {
			Name = "Web-Digest-Auth"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebClientAuth"
		}
		WindowsFeature WebDirBrowsing {
			Name = "Web-Dir-Browsing"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebDigestAuth"
		}
		WindowsFeature WebDynCompression {
			Name = "Web-Dyn-Compression"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebDirBrowsing"
		}
		WindowsFeature WebHttpErrors {
			Name = "Web-Http-Errors"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebDynCompression"
		}
		WindowsFeature WebHttpLogging {
			Name = "Web-Http-Logging"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebHttpErrors"
		}
		WindowsFeature WebHttpRedirect {
			Name = "Web-Http-Redirect"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebHttpLogging"
		}
		WindowsFeature WebHttpTracing {
			Name = "Web-Http-Tracing"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebHttpRedirect"
		}
		WindowsFeature WebISAPIExt {
			Name = "Web-ISAPI-Ext"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebHttpTracing"
		}
		WindowsFeature WebISAPIFilter {
			Name = "Web-ISAPI-Filter"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebISAPIExt"
		}
		WindowsFeature WebLgcyMgmtConsole {
			Name = "Web-Lgcy-Mgmt-Console"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebISAPIFilter"
		}
		WindowsFeature WebMetabase {
			Name = "Web-Metabase"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebLgcyMgmtConsole"
		}
		WindowsFeature WebMgmtConsole {
			Name = "Web-Mgmt-Console"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebMetabase"
		}
		WindowsFeature WebMgmtService {
			Name = "Web-Mgmt-Service"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebMgmtConsole"
		}
		WindowsFeature WebNetExt45 {
			Name = "Web-Net-Ext45"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebMgmtService"
		}
		WindowsFeature WebRequestMonitor {
			Name = "Web-Request-Monitor"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebNetExt45"
		}
		WindowsFeature WebServer {
			Name = "Web-Server"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebRequestMonitor"
		}
		WindowsFeature WebStatCompression {
			Name = "Web-Stat-Compression"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebServer"
		}
		WindowsFeature WebStaticContent {
			Name = "Web-Static-Content"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebStatCompression"
		}
		WindowsFeature WebWindowsAuth {
			Name = "Web-Windows-Auth"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebStaticContent"
		}
		WindowsFeature WebWMI {
			Name = "Web-WMI"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebWindowsAuth"
		}
		WindowsFeature WindowsIdentityFoundation {
			Name = "Windows-Identity-Foundation"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WebWMI"
		}
		# Edge Transport Server Role
		WindowsFeature ADLDS {
			Name = "ADLDS"
            Ensure = "Present"
			DependsOn = "[WindowsFeature]WindowsIdentityFoundation"
		}
		# DNS
		WindowsFeature DNS 
        {
            Name = "DNS"
			Ensure = "Present"
			DependsOn = "[WindowsFeature]ADLDS"
        }
		# Active Directory Domain Service
		WindowsFeature ADDSInstall 
        {
            Name = "AD-Domain-Services"
			Ensure = "Present"
			DependsOn = "[WindowsFeature]DNS"
        }
		xPendingReboot RebootPostADDSInstall
        {
           	Name = "AfterADDSInstall"
           	DependsOn = "[WindowsFeature]ADDSInstall"
        }
		# AD Domain creation needs a reboot
		xADDomain FirstDS 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "$env:SystemDrive\NTDS"
            LogPath = "$env:SystemDrive\NTDS"
            SysvolPath = "$env:SystemDrive\SYSVOL"
			DependsOn = "[xPendingReboot]RebootPostADDSInstall"
        }
		# Reboot node if necessary
		xPendingReboot RebootPostFirstDS
        {
            Name      = "AfterFirstDS"
            DependsOn = "[xADDomain]FirstDS"
        }
        # Download Unified Communication Manager API 4.0
        xDownloadFile DownloadUCMA4
		{
			SourcePath = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
			FileName = "UcmaRuntimeSetup.exe"
			DestinationDirectoryPath = $downloadPath
			DependsOn = "[xPendingReboot]RebootPostFirstDS"
		}
		# Install Unified Communication Manager API 4.0
        xInstaller InstallUCMA4
		{
			Path = "$downloadPath\UcmaRuntimeSetup.exe"
			Arguments = "-q"
			RegistryKey = "NA"
			DependsOn = "[xDownloadFile]DownloadUCMA4"
		}
        # Download VCRedist2013
        xDownloadFile DownloadVCRedist2013
		{
			SourcePath = "http://download.microsoft.com/download/0/5/6/056dcda9-d667-4e27-8001-8a0c6971d6b1/vcredist_x64.exe"
			FileName = "vcredist_x64.exe"
			DestinationDirectoryPath = $downloadPath
			DependsOn = "[xInstaller]InstallUCMA4"
		}
		# Install VCRedistributable
        xInstaller InstallVCRedist2013
		{
			Path = "$downloadPath\vcredist_x64.exe"
			Arguments = "-q"
			RegistryKey = "NA"
			DependsOn = "[xDownloadFile]DownloadVCRedist2013"
		}
		# Reboot node if necessary
		xPendingReboot RebootPostInstallVCRedist2013
        {
            Name      = "AfterVCRedist2013"
            DependsOn = "[xInstaller]InstallVCRedist2013"
        }
		# Download Azure AD Connect
        xDownloadFile DownloadAzureADConnect
		{
			SourcePath = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
			FileName = "AzureADConnect.msi"
			DestinationDirectoryPath = $downloadAAD
			DependsOn = "[xInstaller]InstallUCMA4"
		}
		# Install Exchange 2016 CU1
        xExchInstall InstallExchange
        {
            Path = "$exchangeInstallerPath\setup.exe"
            Arguments = "/Mode:Install /Role:Mailbox /OrganizationName:ExchOrg /TargetDir:F:\Exchange /IAcceptExchangeServerLicenseTerms"
            Credential = $DomainCreds
            DependsOn = '[xPendingReboot]RebootPostInstallVCRedist2013'
			PsDscRunAsCredential = $DomainCreds
        }
		#xExchangeValidate ValidateExchange2016
		#{
		#	TestName = "All"
		#	DependsOn = "[xInstaller]DeployExchangeCU1"
		#}
		# Reboot node if needed
		
		#Configure Exchange necessary URLs
        xExchOwaVirtualDirectory OwaURL
        {
            Identity = "owa (Default Web Site)"
            Credential = $DomainCreds
            ExternalUrl = "https://owa.$DomainName/owa"
            InternalUrl = "https://owa.$DomainName/owa"
        }
        xExchEcpVirtualDirectory EcpURL
        {
            Identity = "ecp (Default Web Site)"
            Credential = $DomainCreds
            ExternalUrl = "https://owa.$DomainName/ecp"
            InternalUrl = "https://owa.$DomainName/ecp"
        }
        xExchOutlookAnywhere UrlOutlookAnywhere
        {
            Identity = "$($env:COMPUTERNAME)\Rpc (Default Web Site)"
            Credential = $DomainCreds
            ExternalHostname = "mail.$DomainName"
            InternalHostname = "mail.$DomainName"
        }

        xExchClientAccessServer AutoDiscoverUrl
        {
            Identity = "$($env:COMPUTERNAME)"
            Credential = $DomainCreds
            AutoDiscoverServiceInternalUri = "https://mail.$DomainName/Autodiscover/Autodiscover.xml"
        }

        xExchOabVirtualDirectory OabUrl
        {
            Identity = "$($env:COMPUTERNAME)\OAB (Default Web Site)"
            Credential = $DomainCreds
            ExternalUrl = "https://mail.$DomainName/OAB"
            InternalUrl = "https://mail.$DomainName/OAB"
        }

        xExchMapiVirtualDirectory MapiUrl
        {
            Identity = "$($env:COMPUTERNAME)\mapi (Default Web Site)"
            Credential = $DomainCreds
            ExternalUrl = "https://mail.$DomainName/mapi"
            InternalUrl = "https://mail.$DomainName/mapi"
        }

        xExchPowerShellVirtualDirectory PsUrl
        {
            Identity = "PowerShell (Default Web Site)"
            Credential = $DomainCreds
            ExternalUrl = "https://mail.$DomainName/powershell"
            InternalUrl = "https://mail.$DomainName/powershell"
        }

        xExchWebServicesVirtualDirectory EwsUrl
        {
            Identity = "EWS (Default Web Site)"
            Credential = $DomainCreds
            ExternalUrl = "https://mail.$DomainName/EWS/Exchange.asmx"
            InternalUrl = "https://mail.$DomainName/EWS/Exchange.asmx"
            MRSProxyEnabled = $true
        }

        xExchActiveSyncVirtualDirectory EasUrl
        {
            Identity = "Microsoft-Server-ActiveSync (Default Web Site)"
            ExternalUrl = "https://mail.$DomainName/Microsoft-Server-ActiveSync"
            InternalUrl = "https://mail.$DomainName/Microsoft-Server-ActiveSync"
        }
		#xExchangeValidate ValidateExchange2016
		#{
		#	TestName = "All"
		#	DependsOn = "[xInstaller]DeployExchangeCU1"
		#}
		# Reboot node if needed
		LocalConfigurationManager 
        {
			ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $True
        }
	}
}
