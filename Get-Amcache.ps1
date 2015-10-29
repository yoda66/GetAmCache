try {
    reg.exe load HKLM\amcache \Windows\AppCompat\Programs\Amcache.hve
	$amcache = Get-ChildItem -Recurse -Path HKLM:\amcache\Root\File
    $amcache | Select-Object -First 100 | Get-ItemProperty | foreach {
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
        }
    }
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Output $ErrorMessage
	break
}
finally {
    [gc]::collect()
    Start-Sleep -Seconds 2
    reg.exe unload hklm\amcache
}
