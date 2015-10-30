function Get-Amcache
{
<#
.SYNOPSIS
This script loads the AMCache hive from the default Windows location and
prints relevant data.

Author: Joff Thyer, Penetration Tester and Security Researcher
        Black Hills Information Security
        Copyright (c) October 2015

.DESCRIPTION
This script loads the AMCache hive from the default Windows location and
prints relevant data.

.PARAMETER RegHive
The Amcache registry hive file to load.  Defaults to \Windows\AppCompat\Programs\Amcache.hve

.PARAMETER DestRegKey
The destination registry key to load the registry hive to.  Defaults to HKLM:\amcache

.PARAMETER Since
The historic cutoff date used to select the registry hive objects.   All objects are
selected from that date up through today.

.PARAMETER Ext
Specify what file extension you want to match.

.EXAMPLE
PS C:\> Get-Amcache -Since 9/1/2015 -Ext exe
PS C:\> Get-Amcache -Since 9/1/2015 -Filename *install* -Ext exe


#>

    [CmdletBinding()]
        Param (
            [Parameter(HelpMessage="Location of Amcache.hve file")]
            [String]$RegHive = $env:SYSTEMROOT + "\AppCompat\Programs\Amcache.hve",

            [Parameter(HelpMessage="Destination registry key to load amcache hive to")]
            [String]$DestRegKey = "HKLM\amcache",

            [Parameter(HelpMessage="Amount of amcache history cutoff date.  Defaults to 90 days back.")]
            [ValidatePattern("^\d{1,2}/\d{1,2}/\d{4}$")]
            [String]$Since = (Get-Date).AddDays(-90).ToString('MM/dd/yyyy'),

            [Parameter(HelpMessage="Specify the file extension to match.  Matches all by default.")]
            [ValidatePattern("^exe|dll|sys$")]
            [String]$Ext = "*",

            [Parameter(HelpMessage="Specify a filename to match.")]
            [String]$Filename="*",

            [Switch]$Descending = $false
        )

    try {
        reg.exe load $DestRegKey $RegHive | Out-Null
        $rootfile = $DestRegKey.replace("\", ":") + "\Root\File"
        if (-not [IO.Path]::GetExtension($Filename)) { $Filename = $Filename + "*"}
        $sortparams = @{ Property = "TimestampLastModified" }
        if ($Descending) { $sortparams.Descending = $true }
        Get-ChildItem -Recurse -Path $rootfile | Get-ItemProperty | `
            foreach {
                $ts_created = ""
                $ts_lastmodified = ""
                $ts_compile = ""
                if ($_.f) {
                    $origin = [TimeZone]::CurrentTimeZone.ToLocalTime([datetime]'1/1/1970')
                    $ts_compile = $origin.AddSeconds($_.f)
                }
                if ($_.12) { $ts_created = [DateTime]::FromFileTime($_.12) }
                if ($_.17) { $ts_lastmodified = [DateTime]::FromFileTime($_.17)}

                if ([IO.Path]::GetExtension($_.15) -like "." + $Ext `
                    -and [IO.Path]::GetFilename($_.15) -like $Filename) {
                    New-Object psobject -Property @{
                        ProductName = $_.0
                        CompanyName = $_.1
                        FileVersionNo = $_.2
                        LangCode = $_.3
                        SwitchBackContext = $_.4
                        FileVersion = $_.5
                        FileSize = $_.6
                        PEHeaderImageSize = $_.7
                        PEHeaderHash = $_.8
                        PEHeaderChecksum = $_.9
                        FileDescription = $_.c
                        TimestampCompile = $ts_compile
                        TimestampCreated = $ts_created
                        FilePath = $_.15
                        TimestampLastModified = $ts_lastmodified
                        ProgramID = $_.100
                        SHA1Hash = $_.101
                    }
                }
            } | Where { $_.TimestampLastModified -gt $Since } `
                    | Sort-Object @sortparams
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
	    break
    }
    finally {
        [gc]::collect()
        [gc]::WaitForPendingFinalizers()
        reg.exe unload $DestRegKey | Out-Null
    }
}