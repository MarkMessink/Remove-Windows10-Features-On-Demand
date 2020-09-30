<#
.SYNOPSIS
    Remove built-in Features On Demand from Windows 10.

.DESCRIPTION
    This script will remove all Features-On-Demand die niet in de 'white-list' staan
	Documentatie: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/features-on-demand-non-language-fod

.EXAMPLE
    .\RemoveFeaturesOnDemand.ps1

.NOTES
    FileName:    RemoveFeaturesOnDemand.ps1
    Author:      Mark Messink
    Contact:     
    Created:     2020-07-07
    Updated:     2020-09-30

    Version history:
    1.0.0 - (2020-07-07) First script, Windows 10 version 2004
	1.0.1 - (2020-09-30) Windows 10 version 20H2
#>
Begin {
    # White list of Features On Demand packages
	# Get-WindowsCapability -online 
	$WhiteListOnDemand = @(
		
	##### Preinstalled FODs #####
			"DirectX.Configuration.Database",
			"Browser.InternetExplorer",
			"MathRecognizer",
			"Microsoft.Windows.Notepad",
			"OneCoreUAP.OneSync",
		###	"OpenSSH.Client",
			"Microsoft.Windows.MSPaint",
		###	"Microsoft.Windows.PowerShell.ISE",
			"Print.Management.Console",
			"App.Support.QuickAssist",
		###	"App.StepsRecorder",
			"Print.Fax.Scan",
			"Microsoft.Windows.WordPad",
			"Media.WindowsMediaPlayer",
			
	##### FODs that shouldn't be removed #####
			"Windows.Client.ShellComponents"		
			"Language",
			"Hello.Face"	
)

	# Onliner
	$WhiteListOnDemand = $WhiteListOnDemand -join "|"

}

Process {
    # Functions
    function Write-LogEntry {
        param(
            [parameter(Mandatory=$true, HelpMessage="Value added to the logfile.")]
            [ValidateNotNullOrEmpty()]
            [string]$Value,

            [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
            [ValidateNotNullOrEmpty()]
            [string]$FileName = "ilog_RemoveFeaturesOnDemand.txt"
        )
        # Logbestand Locatie
        $LogFilePath = Join-Path -Path C:\IntuneLogs -ChildPath "$($FileName)"

        # Add value to log file
        try {
            Out-File -InputObject $Value -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to $($FileName) file"
        }
    }

	# Aanmaken standaard logpath (als deze nog niet bestaat)
	$path = "C:\IntuneLogs"
	If(!(test-path $path))
	{
      New-Item -ItemType Directory -Force -Path $path
	}

    # Initial logging
	$date = get-date
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
    Write-LogEntry -Value "$date"
	Write-LogEntry -Value "Starting Features on Demand removal process"
	Write-LogEntry -Value "WhiteList: $WhiteListOnDemand"

    # Get Features On Demand that should be removed
    try {
        $OSBuildNumber = Get-WmiObject -Class "Win32_OperatingSystem" | Select-Object -ExpandProperty BuildNumber

        # Handle cmdlet limitations for older OS builds
        if ($OSBuildNumber -le "16299") {
            $OnDemandFeatures = Get-WindowsCapability -Online -ErrorAction Stop | Where-Object { $_.Name -notmatch $WhiteListOnDemand -and $_.State -like "Installed"} | Select-Object -ExpandProperty Name
        }
        else {
            $OnDemandFeatures = Get-WindowsCapability -Online -LimitAccess -ErrorAction Stop | Where-Object { $_.Name -notmatch $WhiteListOnDemand -and $_.State -like "Installed"} | Select-Object -ExpandProperty Name
        }

        foreach ($Feature in $OnDemandFeatures) {
            try {
				Write-LogEntry -Value "-------------------------------------------------------------------------------"
                Write-LogEntry -Value "Removing Feature on Demand package: $($Feature)"

                # Handle cmdlet limitations for older OS builds
                if ($OSBuildNumber -le "16299") {
                    Get-WindowsCapability -Online -ErrorAction Stop | Where-Object { $_.Name -like $Feature } | Remove-WindowsCapability -Online -ErrorAction Stop | Out-Null
                }
                else {
                    Get-WindowsCapability -Online -LimitAccess -ErrorAction Stop | Where-Object { $_.Name -like $Feature } | Remove-WindowsCapability -Online -ErrorAction Stop | Out-Null
                }
            }
            catch [System.Exception] {
                Write-LogEntry -Value "Removing Feature on Demand package failed: $($_.Exception.Message)"
            }
        }    
    }
    catch [System.Exception] {
        Write-LogEntry -Value "Attempting to list Feature on Demand packages failed: $($_.Exception.Message)"
    }

    # Complete
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
    Write-LogEntry -Value "Completed Feature on Demand removal process"
}