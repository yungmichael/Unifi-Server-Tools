if (!(Test-Path -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi'))) {
    New-Item -Path $Env:LOCALAPPDATA -Name 'Unifi' -ItemType Directory | Out-Null
}
Function Add-UServerFile {
    param(
        [parameter(Mandatory = $true, Position = 0)]
        [array]$Server
    )

    foreach ($Item in $Server) {
        $Servers += @([PSCustomObject]@{
                Address = (($Item).Split(':'))[0]
                Port    = (($Item).Split(':'))[1]
            })
    }

    $Servers | Export-CliXml -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi\Server.xml') -Force | Out-Null
}

Function Add-UCredentialFile {
    param(
        [parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $false)]
        [psobject]$Credential
    )

    if (!($Credential)) {
        $Credential = Get-Credential -Message 'Enter Credential with Superadmin privileges for Unifi Controller'
    }

    $Credential | Export-CliXml -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi\Credentials.xml') -Force | Out-Null
}

Function Add-USiteFile {
    param(
        [switch]$Full
    )

    $UData = Import-UData -WithoutSite

    if ($Full) {
        $Sites = Get-USiteInformation -Server $UData.Servers -Credential $UData.Credential -Full
        $Sites | Export-CliXml -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi\SitesFull.xml') -Force | Out-Null
    }
    else {
        $Sites = Get-USiteInformation -Server $UData.Servers -Credential $UData.Credential
        $Sites | Export-CliXml -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi\Sites.xml') -Force | Out-Null
    }
}

Function Open-USite {
    param(
        [switch]$Chrome,
        [switch]$Firefox,
        [switch]$Live
    )

    if ($Live) {
        $UData = Import-UData -Live
    }
    else {
        $UData = Import-UData
    }
    $URL = Search-USite -UData $UData
    $DefaultBrowserName = (Get-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' | Get-ItemProperty).ProgId

    if (($DefaultBrowserName -like 'ChromeHTML') -or ($Chrome)) {
        if (Test-Path -Path "$env:LOCALAPPDATA\Unifi\Chrome\Unifi") {
            $Driver = Start-SeChrome -StartURL $URL -Maximized -Quiet -ProfileDirectoryPath "$env:LOCALAPPDATA\Unifi\Chrome\Unifi"
        }
        else {
            $Driver = Start-SeChrome -StartURL $URL -Maximized -Quiet
        }
        while ($Driver.Url -notmatch 'unifi.telmekom.net:8443') { }
    }

    elseif (($DefaultBrowserName -like 'FirefoxURL-308046B0AF4A39CB') -or ($Firefox)) {
        if (Test-Path -Path "$env:LOCALAPPDATA\Unifi\Firefox\Unifi") {
            $Driver = Start-SeFirefox -StartURL $URL -Maximized -Quiet -Arguments '-profile', "$env:LOCALAPPDATA\Unifi\Firefox\Unifi"
        }
        else {
            $Driver = Start-SeFirefox -StartURL $URL -Maximized -Quiet
        }  
        while ($Driver.Url -notmatch 'unifi.telmekom.net:8443') { }
    }

    elseif ($DefaultBrowserName -like 'MSEdgeHTM') {
        if (Test-Path -Path "$env:LOCALAPPDATA\Unifi\Chrome\Unifi") {
            $Driver = Start-SeNewEdge -StartURL $URL -Maximized -Quiet -ProfileDirectoryPath "$env:LOCALAPPDATA\Unifi\Chrome\Unifi"
        }
        else {
            $Driver = Start-SeNewEdge -StartURL $URL -Maximized -Quiet
        }            
        while ($Driver.Url -notmatch 'unifi.telmekom.net:8443') { }
    }

    else {
        $Driver = Start-SeEdge -StartURL $URL -Maximized -Quiet
        while ($Driver.Url -notmatch 'unifi.telmekom.net:8443') { }
    }
        
    $ElementUsername = Get-SeElement -Driver $Driver -Name 'username' -Wait -Timeout 10
    $ElementPassword = Get-SeElement -Driver $Driver -Name 'password' -Wait -Timeout 10
    $ElementLogin = Get-SeElement -Driver $Driver -Id 'loginButton' -Wait -Timeout 10
        
    Send-SeKeys -Element $ElementUsername -Keys (($UData.Credential | ConvertFrom-Json).username)
    Send-SeKeys -Element $ElementPassword -Keys (($UData.Credential | ConvertFrom-Json).password)
        
    Invoke-SeClick -Driver $Driver -Element $ElementLogin -JavaScriptClick
        
    while ($Driver.Url -match 'login') { }
    Enter-SeUrl $URL -Driver $Driver
}

Function Add-UProfile {    
    param(
        [switch]$Chrome,
        [switch]$Firefox,
        [switch]$Refresh
    )

    if ($Chrome) {
        $ChromeProcessID = (Get-Process -Name '*Chrome*').ID
        if ((Test-Path -Path "$env:LOCALAPPDATA\Unifi\Chrome\Unifi") -and ($Refresh)) {
            Remove-Item -Path "$env:LOCALAPPDATA\Unifi\Chrome\Unifi" -Force -Recurse
        }
        Write-Warning -Message 'Creating new profile, please wait'
        $ChromePath = Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)'
    }

    if ($Firefox) {
        $FirefoxProcessID = (Get-Process -Name '*Firefox*').ID
        if ((Test-Path -Path "$env:LOCALAPPDATA\Unifi\Firefox\Unifi") -and ($Refresh)) {
            Remove-Item -Path "$env:LOCALAPPDATA\Unifi\Firefox\Unifi" -Force -Recurse
        }
        Write-Warning -Message 'Creating new profile, please wait'
        $FirefoxPath = Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe').'(Default)'
    }

    if ($Chrome) {
        Invoke-Expression -Command "&`"$($ChromePath.FullName)`" --user-data-dir=$env:LOCALAPPDATA\Unifi\Chrome\Unifi --silent-launch"
        Start-Sleep 10     
        foreach ($ProcessID in (Get-Process -Name '*Chrome*').ID) {
            if ($ProcessID -notin $ChromeProcessID) {
                Stop-Process -Id $ProcessID -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if ($Firefox) {
        Invoke-Expression -Command "&`"$($FirefoxPath.FullName)`" --CreateProfile `"Unifi $env:LOCALAPPDATA\Unifi\Firefox\Unifi`" --no-remote"  
        Start-Sleep 10     
        foreach ($ProcessID in (Get-Process -Name '*Firefox*').ID) {
            if ($ProcessID -notin $FirefoxProcessID) {
                Stop-Process -Id $ProcessID -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Function Get-USiteURL {
    param(
        [switch]$Live
    )

    if ($Live) {
        $UData = Import-UData -Live
    }
    else {
        $UData = Import-UData
    }

    $URL = Search-USite -UData $UData
    Write-Host -Object $URL
}

Function Get-UServerStats {
    param(
        [switch]$Device,
        [switch]$Distribution,
        [switch]$Live
    ) 

    if ($Live) {
        $UData = Import-UData -Live -Full
    }
    else {
        $UData = Import-UData -OnlySite -Full 
    }

    if ($Device) {
        $DeviceStats = [PSCustomObject]@{
            PendingUpdates = ($UData.Sites.Devices.data | Where-Object -Property upgradable -eq $true).Count
            Unsupported    = ($UData.Sites.Devices.data | Where-Object -Property unsupported -eq $true).Count
            Incompatible   = ($UData.Sites.Devices.data | Where-Object -Property model_incompatible -eq $true).Count
            Mesh           = ($UData.Sites.Devices.data | Where-Object -Property mesh_sta_vap_enabled -eq $true).Count
            Locating       = ($UData.Sites.Devices.data | Where-Object -Property locating -eq $true).Count
            Overheating    = ($UData.Sites.Devices.data | Where-Object -Property overheating -eq $true).Count
        }
    }

    elseif ($Distribution) {
        foreach ($Server in ($UData.Sites.Server | Sort-Object -Unique)) {
            $DistributionStats += @([PSCustomObject]@{ 
                    Server              = $Server
                    Sites               = (($UData.Sites | Where-Object -Property Server -Match $Server).Count)
                    PendingUpdates      = (($UData.Sites | Where-Object -Property Server -Match $Server).Devices.data.upgradable | Measure-Object -sum).sum
                    DevicesAdopted      = (($UData.Sites | Where-Object -Property Server -Match $Server).health.num_adopted | Measure-Object -sum).sum
                    DevicesOnline       = ((($UData.Sites | Where-Object -Property Server -Match $Server).health.num_ap | Measure-Object -sum).sum) + ((($UData.Sites | Where-Object -Property Server -Match $Server).health.num_sw | Measure-Object -sum).sum)
                    DevicesDisconnected = (($UData.Sites | Where-Object -Property Server -Match $Server).health.num_disconnected | Measure-Object -sum).sum
                    Clients             = (($UData.Sites | Where-Object -Property Server -Match $Server).health.num_user | Measure-Object -sum).sum
                })
        }
    }

    else {
        $ServerStats = [PSCustomObject]@{
            Sites               = $UData.Sites.Count
            DevicesAdopted      = ($UData.Sites.health.num_adopted | Measure-Object -sum).sum
            DevicesOnline       = (($UData.Sites.health.num_ap | Measure-Object -sum).sum) + (($UData.Sites.health.num_sw | Measure-Object -sum).sum)
            DevicesDisconnected = ($UData.Sites.health.num_disconnected | Measure-Object -sum).sum
            Clients             = ($UData.Sites.health.num_user | Measure-Object -sum).sum  
        }
    }

    if ($Device) { 
        $DeviceStats
    }
    elseif ($Distribution) {
        foreach ($DistributionStat in $DistributionStats) {
            $DistributionStat
        }
    }
    else {
        $ServerStats
    }
}


#Helper Functions
Function Import-UData {
    param(
        [switch]$Full,
        [switch]$Live,
        [switch]$OnlySite,
        [switch]$WithoutSite
    )

    if (!($OnlySite)) {
        #retriving credential data, if credentialfile found it will read it, else it will ask for credentials
        try {
            if (Test-Path -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi\Credentials.xml')) {
                $Credential = Import-CliXml -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi\Credentials.xml')
                $Credential = @{
                    username = $Credential.UserName
                    password = ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)))
                } | ConvertTo-Json
            }
            elseif (!($Credential)) {
                $Credential = Get-Credential -Message 'Enter Credential with Superadmin privileges for Unifi Controller'
                $Credential = @{
                    username = $Credential.UserName
                    password = ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)))
                } | ConvertTo-Json
            }
        }
        catch {
            Write-Warning "$env:LOCALAPPDATA\Unifi\Credential.xml not found"
            Write-Warning "Run Add-UCredentialFile first"
            exit
        }

        #retriving server data, if serverfile found it will read it, else it will ask for server
        try {
            if (Test-Path -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi\Server.xml')) {
                if (Test-Path -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi\Server.xml')) {
                    $Servers = Import-CliXml -Path (Join-Path -Path $Env:LOCALAPPDATA -ChildPath 'Unifi\Server.xml')
                }
            }
            else {
                $Server = Read-Host -Prompt 'Enter Server <https://[Server]:[Port]>'
                foreach ($Item in $Server) {
                    $Servers += @([PSCustomObject]@{
                            Address = (($Item).Split(':'))[0]
                            Port    = (($Item).Split(':'))[1]
                        })
                }
            }
        }
        catch {
            Write-Warning "$env:LOCALAPPDATA\Unifi\Server.xml not found"
            Write-Warning "Run Add-UServerFile first"
            exit
        }
    }

    if (!($WithoutSite)) {
        #retriving site data
        if (($Live) -and ($Full)) {
            $Sites = Get-USiteInformation -Server $Servers -Credential $Credential -Full
        }
        elseif ($Live) {
            $Sites = Get-USiteInformation -Server $Servers -Credential $Credential
        }
        else {
            try {
                if ($Full) {
                    $Sites = Import-Clixml "$env:LOCALAPPDATA\Unifi\SitesFull.xml"
                }
                else {
                    $Sites = Import-Clixml "$env:LOCALAPPDATA\Unifi\Sites.xml"
                }
            }
            catch {
                Write-Warning "$env:LOCALAPPDATA\Unifi\Sites.xml or $env:LOCALAPPDATA\Unifi\SitesFull.xml not found"
                Write-Warning "Run Add-USiteFile -Full first"
                exit
            }
        }
    }
    return (@([PSCustomObject]@{
                Sites      = $Sites
                Servers    = $Servers
                Credential = $Credential
            }))          
} 

Function Get-USiteInformation {
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [array]$Server,
        [parameter(Mandatory = $true, Position = 1)]
        [psobject]$Credential,
        [switch]$Full
    )

    Write-Host 'Parsing all Sites - Please Wait'
    foreach ($Item in $Server) {
        if (Test-NetConnection -ComputerName $Item.Address -Port $Item.Port -InformationLevel Quiet) {
            $URL = "https://$($Item.Address):$($Item.Port)"
            try {
                $Login = Invoke-RestMethod -Uri "$URL/api/login" -Method Post -Body $Credential -ContentType "application/json; charset=utf-8" -SessionVariable myWebSession -SkipCertificateCheck
            }
            catch {
                Write-Warning -Message "Login to https://$($Item.Address):$($Item.Port) failed du to wrong credentials" 
            }
            if ($Login.meta.rc -eq 'ok') {
                foreach ($Site in (Invoke-RestMethod -Uri "$URL/api/stat/sites" -WebSession $myWebSession -SkipCertificateCheck).data) {
                    if ($Full) {
                        $Sites += @([PSCustomObject]@{
                                Server   = $URL
                                SiteID   = $Site._id
                                SiteURL  = $Site.name
                                SiteName = $Site.desc
                                Health   = $Site.health
                                Devices  = Invoke-RestMethod -Uri "$URL/api/s/$($Site.Name)/stat/device" -WebSession $myWebSession -SkipCertificateCheck
                            })
                    }
                    else {
                        $Sites += @([PSCustomObject]@{
                                Server   = $URL
                                SiteID   = $Site._id
                                SiteURL  = $Site.name
                                SiteName = $Site.desc
                            })
                    }
                }
                Invoke-RestMethod -Uri "$URL/api/logout" -Method Post -ContentType "application/json; charset=utf-8" -SessionVariable myWebSession -SkipCertificateCheck | Out-Null
            }
        }
    }
    return $Sites
}

Function Search-USite {
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [psobject]$UData,
        [switch]$URL
    )

    do {
        do {
            $SelectionSite = $UData.Sites | Where-Object -Property SiteName -match (Read-Host -Prompt 'Search for Site Name / Customer ID (Enter for a list of all Sites)') -ErrorAction SilentlyContinue
        } while (!$SelectionSite)
    
        Write-Host -Object '[0] -- Return'
        for ($i = 1; $i -le $SelectionSite.length; $i++) {
            Write-Host -Object "[$i] -- $($SelectionSite[$i-1].SiteName)"
        }
        try {
            [int]$Selection = (Read-Host "Choice Site")
        }
        catch { }
    } while (($Selection -like 0) -or ($Selection -gt $i - 1) -or ($Selection -isnot [int]))
    
    $Switch = 'Switch($Selection){'
    for ($i = 1; $i -le $SelectionSite.length; $i++) {
        $Switch += "`n`t$i {return '$($SelectionSite[$i-1].Server)/manage/site/$($SelectionSite[$i-1].SiteURL)/devices/1/100'}"
    }
    $Switch += "`n}"
    Invoke-Expression $Switch
}

Open-USite -Firefox
Add-UProfile -Firefox