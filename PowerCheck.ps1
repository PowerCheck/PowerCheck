[CmdletBinding()]
param (
  [Parameter(Mandatory=$true)] [Alias("PluginPath")] [String]$Plugin,
  [Parameter(Mandatory=$false)] [ValidateScript({Test-Path $_ -PathType 'Container' -IsValid})] [String]$Outputpath = $null,
  [Parameter(Mandatory=$false)] [Alias("DefaultConfig")] [Switch]$ResetGlobalConfig,
  [Parameter(Mandatory=$false)] [ValidateSet("None", "Global", "Plugin", "Full")][String]$SetupWizard = "None"
)
Clear-Host

$script:GlobalVars = @{
  Author = "Luis Tavares"
  Version = "1.0"
}

#Region Enumerator flags
[Flags()] enum SetupWizardFlags {
  None = 0
  Global = 1
  Plugin = 2
  Full = 255
}
#EndRegion

#Region Load modules and define global paths
# Define the PowerCheck root path and import modules
$script:PowerCheckPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)
foreach ($moduleFile in Get-ChildItem -Path $script:PowerCheckPath\Modules -Filter *.psm1) {
  Import-Module -Name $moduleFile.FullName -Force
}
# Define other common paths
if (Test-Path -LiteralPath $Plugin -PathType Container) {
  $script:PluginRootPath = $Plugin
  $Plugin = Split-Path -Path $Plugin -Leaf -Resolve
} else {
  $script:PluginRootPath = Get-ReportPluginRoot -ScriptPath $script:PowerCheckPath -Plugin $Plugin
}

if (-not $script:PluginRootPath) {
  Write-Error ("Could not find plugin '{0}' in the default locations" -f $Plugin)
  exit 0
}
#EndRegion

#Region Configuration and SetupWizard
# If the ResetGlobalConfig switch is used, then restore PowerCheck GlobalVariables.ps1 and exit
if ($ResetGlobalConfig) {
  Restore-DefaultConfig -FileName $script:PowerCheckPath\GlobalVariables.ps1
  exit 0
}
# Check for main configuration file
Test-Configuration -FileName $script:PowerCheckPath\GlobalVariables.ps1

$runSetupWizardGlobal = $false
$runSetupWizardPlugin = $false
$setupWizardFlag = [SetupWizardFlags].GetEnumValues().Where({$_ -eq $SetupWizard}).value__

# Global configuration SetupWizard
if (Test-Path -Path $script:PowerCheckPath\GlobalVariables.ps1) {
  $config = Get-Content -Path $script:PowerCheckPath\GlobalVariables.ps1 -Raw
  if ( ($config | Select-String '(?smi)\$SetupWizard\s+?=\s+?\$true') -or ($setupWizardFlag -band [SetupWizardFlags]::Global)) {
    $runSetupWizardGlobal = $true
    Set-Configuration -FileName $script:PowerCheckPath\GlobalVariables.ps1 -ConfigMode global
  }
}

# User plugin configuration SetupWizard
if (Test-Path -Path $script:PluginRootPath\GlobalVariables.ps1) {
  $config = Get-Content -Path $script:PluginRootPath\GlobalVariables.ps1 -Raw
  if ( ($config | Select-String '(?smi)\$SetupWizard\s+?=\s+?\$true') -or ($setupWizardFlag -band [SetupWizardFlags]::Plugin) ) {
    $runSetupWizardPlugin = $true
    Set-Configuration -FileName $script:PluginRootPath\GlobalVariables.ps1 -ConfigMode plugin
  }
}

# Run SetupWizard for user plugin if global or plugin SetupWizard are enabled
if ($runSetupWizardGlobal -or $runSetupWizardPlugin) {
  foreach ($file in Get-ChildItem -Path $script:PluginRootPath\plugins -Filter *.ps1 -Recurse) {
    Set-Configuration -FileName $file.FullName -ConfigMode plugin
  }
}
#EndRegion

#Region Load global variables
# Load global variables, from the main PowerCheck folder and then from the plugin folder,
# overriding global variables set by PowerCheck.
$script:GlobalVars = Get-GlobalVariables -PowerCheckPath $script:PowerCheckPath -PluginRootPath $script:PluginRootPath -GlobalVars $script:GlobalVars
#EndRegion

#Region localization
# Gets localized script and plugin messages. By default it uses en-US messages if another language is specified then replaces en-US messages with the language message if available.
$script:PowerCheckLocalization = @{}
$script:PowerCheckLocalization += Import-Localization -PowerCheckPath $script:PowerCheckPath -Culture $GlobalVars.Culture
$script:PowerCheckLocalization += Import-PluginLocalization -Culture $GlobalVars.Culture -PluginRoot $script:PluginRootPath
#EndRegion

#Region Run plugin scripts
Write-LogMessage -Message $script:PowerCheckLocalization.pcStart
Set-Location $script:PluginRootPath
$pluginData = Invoke-Plugin -PluginRootPath $script:PluginRootPath -Localization $script:PowerCheckLocalization -GlobalVars $script:GlobalVars
Set-Location $script:PowerCheckPath
Write-LogMessage -Message $script:PowerCheckLocalization.pcStop
#EndRegion

#Region Invoke end scripts
if ( Test-Path -Path $script:PowerCheckPath\EndScript.ps1 ) {
  Write-LogMessage -Message $script:PowerCheckLocalization.pcEndScriptGlobal
. $script:PowerCheckPath\EndScript.ps1
}
if ( Test-Path $script:PluginRootPath\EndScript.ps1) {
Write-LogMessage -Message $script:PowerCheckLocalization.pcEndScriptPlugin
. $script:PluginRootPath\EndScript.ps1
}
#EndRegion

#Region Report filename and storage locations
$script:ResourceFiles = Get-ResourceFiles -Style $GlobalVars.Style -Culture $GlobalVars.Culture -PowerCheckPath $script:PowerCheckPath -PluginPath $script:PluginRootPath

$date = $pluginData.StartDate | Get-Date -Format "yyyyMMdd-hhmm"
$date = "00000000-0000"
$tempPath = (Resolve-Path -Path $env:TEMP).Path

if ($Outputpath -eq "") {
  $GlobalVars.ReportsFolderPath = $GlobalVars.ReportsFolderPath.Replace("_POWERCHECK_", $script:PowerCheckPath).Replace("_PLUGIN_", $script:PluginRootPath)
  if (!(Test-Path -Path $GlobalVars.ReportsFolderPath)) {
    New-Item -Path $GlobalVars.ReportsFolderPath -ItemType Directory -Force
  }
  $reportPath = (Resolve-Path -Path $GlobalVars.ReportsFolderPath).Path
} else {
  $reportPath = $Outputpath
}

$filename = ("{0}.html" -f $GlobalVars.ReportFilenameFormat).Replace("_DATE_", $date).Replace("_PLUGIN_", $plugin)
$jsonFilename = ("{0}.json" -f $GlobalVars.JsonFilenameFormat).Replace("_DATE_", $date).Replace("_PLUGIN_", $plugin)
#EndRegion

#Region Email, Display and/or archive the report
# Save report as JSON file
if ($GlobalVars.ExportJson) {
  Write-LogMessage -Message ($script:PowerCheckLocalization.pcJson -f "$reportPath")
  Export-JsonData `
    -GlobalVars $GlobalVars `
    -ReportData $pluginData `
    -PowerCheckPath $script:PowerCheckPath `
    -PluginRootPath $script:PluginRootPath `
    -PluginName $Plugin `
    -JsonFileName $jsonFilename `
    -JsonFilePath $reportPath
}

# Create the HTML report as a file if we need to display to user or send as attachment via email
if ($GlobalVars.DisplaytoScreen -or $GlobalVars.SendAttachment -or $GlobalVars.KeepReport) {
  Write-LogMessage -Message ($script:PowerCheckLocalization.pcHtml -f "$tempPath")
  Get-HtmlReport `
    -Format html `
    -GlobalVars $script:GlobalVars `
    -ResourceFiles $script:ResourceFiles `
    -ReportData $pluginData `
    -Localization $script:PowerCheckLocalization `
    -ReportPath $tempPath `
    -ReportFilename $filename `
    -PowerCheckPath $script:PowerCheckPath
}

# Send report via email
if ($GlobalVars.SendEmail) {
  Write-LogMessage -Message $script:PowerCheckLocalization.pcEmail
  $htmlReport = Get-HtmlReport `
    -Format email `
    -GlobalVars $script:GlobalVars `
    -ResourceFiles $script:ResourceFiles `
    -ReportData $pluginData `
    -Localization $script:PowerCheckLocalization `
    -PowerCheckPath $script:PowerCheckPath `
    -ReturnHtml

  $body = $null
  switch ($GlobalVars.EmailBodyTextSource) {
    "report" {
      $body = $null
      foreach ($result in $pluginData.Result) {
        $body += "Title: {0}
Comments: {1}
{2}" -f $result.Title, $result.Comments, ($result.Details | Format-Table -AutoSize | Out-String)
      }
    }
    "file" {
      if ( Test-Path -Path "$script:PluginRootPath\emailbody.txt") {
        $body = Get-Content "$script:PluginRootPath\emailbody.txt" -Raw
      } else {
        $body = "Could not find file $script:PluginRootPath\emailbody.txt"
      }
    }
    Default {
      $body = ($powerCheckLocalization.emailBody -f $Plugin, $pluginData.StartDate.ToShortDateString(), $pluginData.StartDate.ToShortTimeString())
    }
  }

  . $script:PowerCheckPath\Modules\Email.ps1 `
    -HtmlBody $htmlReport.html `
    -TextBody "$body" `
    -File "$tempPath\$filename" `
    -SMTPSRV $GlobalVars.SMTPSRV `
    -EmailSSL $GlobalVars.EmailSSL `
    -EmailFrom $GlobalVars.EmailFrom `
    -EmailTo $GlobalVars.EmailTo `
    -EmailCc $GlobalVars.EmailCc `
    -EmailSubject $GlobalVars.EmailSubject `
    -EmailBodyFormat $GlobalVars.EmailBodyFormat `
    -SendAttachment $GlobalVars.SendAttachment `
    -Attachments $htmlReport.attachments
}

# Keep a copy of the report and display it to screen if required
if (($reportPath -ne $tempPath) -and $GlobalVars.KeepReport) {
  if ( -not (Test-Path -LiteralPath $reportPath) ) {
    $null = New-Item -ItemType Directory -Path $reportPath
  }
  Move-Item "$tempPath\$filename" "$reportPath\" -Force
} else {
   $reportPath = $tempPath
}
if ($GlobalVars.DisplaytoScreen) {
  Invoke-Item -Path "$reportPath\$filename"
}
#EndRegion

Write-LogMessage -Message $script:PowerCheckLocalization.pcDone
