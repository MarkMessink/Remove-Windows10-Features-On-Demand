<#
.SYNOPSIS
    Remove built-in Features On Demand from Windows 10.

.DESCRIPTION
    This script will remove all Features-On-Demand that's not specified in the 'white-list' in this script.
	Documentation: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/features-on-demand-non-language-fod

.EXAMPLE
    .\RemoveFeaturesOnDemand.ps1

.NOTES
    FileName:    RemoveFeaturesOnDemand.ps1
    Author:      Mark Messink
    Contact:     
    Created:     2020-11-24
    Updated:     

    Version history:
    1.0.0 - (2020-11-24) First script, Windows 10 version 20H2
	
	Create new Whitelist:
	Get-WindowsCapability -Online | where state -eq installed | FT Name

#>
Begin {
    $WhiteListedFOD = New-Object -TypeName System.Collections.ArrayList
   
<##### Features On Demand #####>   
	$WhiteListedFOD.AddRange(@(
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
	"Media.WindowsMediaPlayer"
	))

<##### Features On Demand that shouldn't be removed #####>  			
	$WhiteListedFOD.AddRange(@(	
	"Windows.Client.ShellComponents",	
	"Language",
	"Hello.Face"	
	))
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
            [string]$FileName = "pslog_RemoveFeaturesOnDemand.txt"
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

	# Create default logpath (if not exist)
	$path = "C:\IntuneLogs"
	If(!(test-path $path))
	{
      New-Item -ItemType Directory -Force -Path $path
	}
	
    # Initial logging
	$date = get-date
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
	Write-LogEntry -Value "Script Version: 20H2 (2020-11-23)"
    Write-LogEntry -Value "$date"
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
	Write-LogEntry -Value "Starting Features on Demand removal process"
	
	# Determine packagenames installed FOD
	$FODArrayList = Get-WindowsCapability -online | where state -eq installed | Select-Object -ExpandProperty Name
	
	# Determine packagenames from $WhiteListedFOD
	$WhiteListedFOD = foreach ($FOD in $WhiteListedFOD) {Get-WindowsCapability -Online -Name $FOD* | where state -eq installed | Select-Object -ExpandProperty Name}
	
	# Loop through the list of FOD
	foreach ($FOD in $FODArrayList) {
		Write-LogEntry -Value "-------------------------------------------------------------------------------"
        Write-LogEntry -Value "Processing FOD package: $($FOD)"
		
        # If FOD name not in FOD white list, remove FOD
        if (($FOD -in $WhiteListedFOD)) {
            Write-LogEntry -Value ">>> Skipping excluded application package: $($FOD)"
        }
		else {
		
		    try {
                Write-LogEntry -Value "Removing Feature on Demand package: $($FOD)"
				Get-WindowsCapability -Online -LimitAccess -ErrorAction Stop | Where-Object { $_.Name -like $FOD } | Remove-WindowsCapability -Online -ErrorAction Stop | Out-Null
                }
				
            catch [System.Exception] {
                Write-LogEntry -Value "Removing Feature on Demand package failed: $($_.Exception.Message)"
				}
			}
	}
    # Complete
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
    Write-LogEntry -Value "Completed Feature on Demand removal process"
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
}
