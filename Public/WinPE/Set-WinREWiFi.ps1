function Set-WinREWiFi() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Please add Wireless network name")]
        [System.String]
        $WLanName,
        
        [System.String]
        $Passwd,
        
        [Parameter(Mandatory = $false, HelpMessage = "This switch will generate a WPA profile instead of WPA2")]
        [System.Management.Automation.SwitchParameter]
        $WPA = $false
    )

    if ($Passwd) {
        # escape XML special characters
        $Passwd = [System.Security.SecurityElement]::Escape($Passwd)
    }

    if ($WPA -eq $false) {
        $WpaState = "WPA2PSK"
        $EasState = "AES"
    } else {
        $WpaState = "WPAPSK"
        $EasState = "AES"
    }

    $XMLProfile = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
      <name>$WlanName</name>
      <SSIDConfig>
         <SSID>
              <name>$WLanName</name>
          </SSID>
     </SSIDConfig>
     <connectionType>ESS</connectionType>
     <connectionMode>auto</connectionMode>
     <MSM>
         <security>
             <authEncryption>
                 <authentication>$WpaState</authentication>
                 <encryption>$EasState</encryption>
                 <useOneX>false</useOneX>
             </authEncryption>
             <sharedKey>
                 <keyType>passPhrase</keyType>
                 <protected>false</protected>
				<keyMaterial>$Passwd</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
</WLANProfile>
"@

    if ($Passwd -eq "") {
        $XMLProfile = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>$WLanName</name>
	<SSIDConfig>
		<SSID>
			<name>$WLanName</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>manual</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>open</authentication>
				<encryption>none</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
		</security>
	</MSM>
	<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
		<enableRandomization>false</enableRandomization>
	</MacRandomization>
</WLANProfile>
"@
    }

    $WLanName = $WLanName -replace "\s+"
    $WlanConfig = "$env:TEMP\$WLanName.xml"
    $XMLProfile | Set-Content $WlanConfig
    $result = Netsh WLAN add profile filename=$WlanConfig
    Remove-Item $WlanConfig -ErrorAction SilentlyContinue
    if ($result -notmatch "is added on interface") {
        throw "There was en error when setting up WIFI $WLanName connection profile. Error was $result"
    }
}
