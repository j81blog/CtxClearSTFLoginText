<#
.SYNOPSIS
	Remove the default text "domain\user or user@domain.com" on teh StoreFront login page
.DESCRIPTION
	Remove the default text "domain\user or user@domain.com" on teh StoreFront login page
.PARAMETER InnerText
	Set a custom text, default (en) text: "domain\user or user@domain.com"
	Don't specify to make it empty
.PARAMETER RestartIIS
	Restarts IIS when the changes are made, this is required to make the changes visible.
.PARAMETER Restore
	Restore the original files
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
.NOTES
	File Name : CtxClearSTFLoginText.ps1
	Version   : v0.1
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
		[switch]$Restore=$false
)		

$Files = Get-ChildItem -Path "C:\inetpub\wwwroot\Citrix\StoreAuth\App_Data\resources\ExplicitFormsCommon*.resx" -Exclude "ExplicitFormsCommon.resx"
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
	Write-Host -ForeGroundColor Green -NoNewLine "`r`nFinished!`r`n"
} else {
	Write-Host -ForeGroundColor Green -NoNewLine "`r`nFinished!"
	Write-Host " Please restart IIS to make the changes visible`r`n"
}
