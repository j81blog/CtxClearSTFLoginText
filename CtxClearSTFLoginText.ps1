<#
.SYNOPSIS
	Text
.DESCRIPTION
	Text
.PARAMETER InnerText
	Set a custom text, default (en) text: "domain\user or user@domain.com"
	Don't specify to make it empty
.PARAMETER RestartIIS
	Restarts IIS when the changes are made, this is required to make the changes visible.
.PARAMETER Restore
	Restore the original files
.PARAMETER Store
	Specify the store, if you don't specify it a choice will be presented.
.EXAMPLE
	.\CtxClearSTFLoginText.ps1 -InnerText "domain\user or user@domain.com"
	Set your custom text.
.EXAMPLE
	.\CtxClearSTFLoginText.ps1 -InnerText "domain\user or user@domain.com" -RestartIIS
	Set your custom text and restart IIS when done
.EXAMPLE
	.\CtxClearSTFLoginText.ps1 -Restore
	Restore the original files
.EXAMPLE
	.\CtxClearSTFLoginText.ps1 -Restore -RestartIIS
	Restore the original files and restart IIS when finished
.EXAMPLE
	.\CtxClearSTFLoginText.ps1 -InnerText "" -Store "Store" -RestartIIS
	Clear the text on store "Store" and restart IIS when done
.NOTES
	File Name : CtxClearSTFLoginText.ps1
	Version   : v0.2
	Author    : John Billekens
	Requires  : Run As Administrator
	            Citrix StoreFront v3.x
.LINK
	https://blog.j81.nl
#>

#Requires -RunAsAdministrator

[cmdletbinding()]
param(
		[Parameter(Mandatory=$false)]
		[string]$InnerText="",
		
		[Parameter(Mandatory=$false)]
		[switch]$RestartIIS=$false,

		[Parameter(Mandatory=$false)]
		[switch]$Restore=$false,
		
		[Parameter(Mandatory=$false)]
		[string]$Store=""
)		

function PickList(){
	[cmdletbinding()]
	param(
		[string[]]$PickList,
		[String]$PickListPromptText,
		[Boolean]$PickListRequired
	)
	$iCounter=0
	$sPickListSelection=$null
	$sPickListItem=$null
	foreach($sPickListItem in $PickList){
		$aPickList += (,($iCounter,$sPickListItem))
		$iCounter++
	}
	Write-Host "`n$PickListPromptText`n"
	$sPickListItem=$null
	foreach ($sPickListItem in $aPickList){
		Write-Host $("`t"+$sPickListItem[0]+".`t"+$sPickListItem[1])
	}
	if ($PickListRequired) {
		while (!$Answer){
			Write-Host "`nRequired " -Fore Red -NoNewline
			$sPickListSelection = Read-Host "Enter Option Number"
			$Answer = $null
			try {
				if ([int]$sPickListSelection -is [int]) {
					if (([int]$sPickListSelection -ge 0) -and ([int]$sPickListSelection -lt $iCounter)) {
						$Answer = 1
					}
				}
			} catch {
				$Answer = $null
			}
		}
		return $aPickList[$sPickListSelection][1]
	} else {
		Write-Host "`nNot Required " -Fore White -NoNewline
		$sPickListSelection = Read-Host "Enter Option Number: "
		if($sPickListSelection){
			return $aPickList[$sPickListSelection][1]
		}
	}
}
$StorePath = "C:\inetpub\wwwroot\Citrix\"
if ($Store -eq "") {
	$MenuChoiceText = "Please select a Store"
	$Stores = (Get-ChildItem -Path $StorePath -Filter "*Auth" | where {$_.Attributes -match'Directory'}).Name.Replace("Auth","")
	$Store = PickList -PickList $Stores -PickListPromptText $sMenuChoiceText -PickListRequired $true
}
$StoreAuthPath = Join-Path $StorePath "$($Store)Auth"

if (Test-Path $StoreAuthPath) {
	$Files = Get-ChildItem -Path "C:\inetpub\wwwroot\Citrix\$($Store)Auth\App_Data\resources\ExplicitFormsCommon*.resx" -Exclude "ExplicitFormsCommon.resx"
	
	ForEach ($File in $Files) {
		[string]$xmlfile = $File.FullName
		if($Restore) {
			if (Test-Path "$($xmlfile).orig") {
				try {
					Write-Host -NoNewLine "Restoring $($File.Name).org -> $($File.Name) "
					Copy-Item -Path "$($xmlfile).orig" -Destination $xmlfile -Force | Out-Null
					Write-Host -ForeGroundColor Green "Done!"
				} catch {
					Write-Host -ForeGroundColor Red "Failed $($xmlfile).orig not restored"
				}
			} else {
				Write-Host -ForeGroundColor Yellow "Not found, nothing to restore"
			}
		} else {
			try {
				if (-not (Test-Path "$($xmlfile).orig")) {
					Write-Host -NoNewLine "Making a backup $($File.Name) -> $($File.Name).orig "
					Copy-Item -Path $xmlfile -Destination "$($xmlfile).orig" | Out-Null
					Write-Host -ForeGroundColor Green "Done!"
				}
				Write-Host -NoNewLine "Changing $($File.Name) "
				$xml = New-Object XML
				$xml.Load($xmlfile)
				[string]$xpath="//root/data[@name='DomainUserAssistiveText']/value"
				$element = $xml.SelectSingleNode($xpath)
				Write-Host -NoNewLine "Text: `"$($element.InnerText)`" into `"$($InnerText)`" "
				$element.InnerText= $InnerText
				$xml.Save($xmlfile)
				$xml = $null
				Write-Host -ForeGroundColor Green "Done!"
			} catch {
				Write-Host -ForeGroundColor Red "Failed"
			}
		}
	}
	if ($RestartIIS) {
		Start-Process "iisreset.exe" -NoNewWindow -Wait
		Write-Host -ForeGroundColor Green -NoNewLine "`r`nFinished!"
	} else {
		Write-Host -ForeGroundColor Green -NoNewLine "`r`nFinished!"
		Write-Host " Please restart IIS to make the changes visible"
	}
} else {
		Write-Host -ForeGroundColor Yellow -NoNewLine "`r`nWarning!"
		Write-Host " Store `"$StorePath`" not found!"
}
