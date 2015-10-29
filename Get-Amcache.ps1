function Get-Amcache
{
<#
.SYNOPSIS
This script loads the AMCache hive from the default Windows location and
prints relevant data.

.DESCRIPTION
This script loads the AMCache hive from the default Windows location and
prints relevant data.

.PARAMETER RegHive
The Amcache registry hive file to load.  Defaults to \Windows\AppCompat\Programs\Amcache.hve

.PARAMETER DestRegKey
The destination registry key to load the registry hive to.  Defaults to HKLM:\amcache

#>

    [CmdletBinding()]
        Param (
            [Parameter(HelpMessage="Location of Amcache.hve file")]
            [String]$RegHive = $env:SYSTEMROOT + "\AppCompat\Programs\Amcache.hve",

            [Parameter(HelpMessage="Destination registry key to load amcache hive to")]
            [String]$DestRegKey = "HKLM\amcache",

            [Parameter(HelpMessage="Last N number of objects")]
            [Int]$LastN = 10
        )

    try {
        reg.exe load $DestRegKey $RegHive | Out-Null
        $rootfile = $DestRegKey.replace("\", ":") + "\Root\File"
        $amcache = Get-ChildItem -Recurse -Path $rootfile
        $amcache | Select-Object -Last $LastN | Get-ItemProperty | `
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
            } | Sort-Object $_.17
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
	    break
    }
    finally {
        $amcache.Handle.close()
        [gc]::collect()
        [gc]::WaitForPendingFinalizers()
        reg.exe unload $DestRegKey | Out-Null
    }
}