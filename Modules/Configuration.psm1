New-Variable -Option Constant -Name varList -Value @(
  "SetupWizard",  "Culture", 
  "ReportTitle",  "DisplaytoScreen",  "DisplayReportEvenIfEmpty",
  "SendEmail",  "SMTPSRV",  "EmailSSL",  "EmailFrom",  "EmailTo",  "EmailCc", 
  "EmailSubject",  "EmailReportEvenIfEmpty",  "EmailBodyFormat",  "EmailBodyTextSource",  "SendAttachment",
  "Style",  "Banner",
  "ReportOnScriptList",  "ListEnabledScriptsFirst",  "ReportOnTimeToRun",  "ScriptRuntimeSeconds",  "ScriptGroupShowName",  "ScriptGroupRemoveIndex",
  "KeepReport",  "ReportsFolderPath",  "ReportFilenameFormat",
  "ExportJson",  "JsonFilePath",  "JsonFilenameFormat"
)

function Set-Configuration {
  param (
    [Parameter()] [String]$FileName,
    [Parameter()] [ValidateSet("global", "plugin", "script")][String]$ConfigMode = "global"
  )

  # Read configuration from file and get all settings
  # TODO: need to handle variables without title, currently they are ignored.
  $content = Get-Content $FileName -Raw
  $config = $content | Select-String '(?smi)# Start of Settings(.*)# End of Settings' -AllMatches
  if ($null -eq $config) { return $null }
  $settings = $config.Matches.Groups[1].Value | Select-String '\s+#(\s+)?(?<title>.*)\s+\$(?<var>.*)(\s+)?=(\s+)?(?<val>.*)' -AllMatches

  # Exit if no settings are found, this can happen in plugins
  if ($null -eq $settings) { return $null }

  $newConfig = $null

  # Loops through all valid title, variables and values. There are only 3 named groups but PowerShell counts unnamed groups and adds a default group 0.
  foreach ($setting in $settings.Matches.Groups.Where({$_.Groups.Count -eq 7})) {
    $newValue = $null
    # $configSource = "global"
    ($title, $var, $val) = Get-SettingData -Setting $setting

    $newValue = Read-Host ("{0} ({2}) [{1}]: " -f $title, $val, $ConfigMode)

    # Create the config lines, will decide to use later
    if ("" -eq $newValue) { $newValue = $val }
    if ("string" -eq (Get-ValueType -Value $newValue)) {
      $newLine = ('# {0}${1} = "{2}"' -f "$title`r`n", $var, $(if($newValue -ne '$null'){$newValue}else{$val}))
    } else {
      $newLine = ('# {0}${1} = {2}' -f "$title`r`n", $var, $(if($newValue -ne '$null'){$newValue}else{$val}))
    }

      $newConfig += "$newLine`r`n"
  }

  $content = $config -replace '(?smi)# Start of Settings(.*)# End of Settings', "# Start of Settings`r`n$newConfig# End of Settings"
  if ($ConfigMode -ne "script") { $content = $content -replace '\$SetupWizard.*\$true', '$SetupWizard = $false'}
  $content | Out-File -FilePath $FileName -Encoding utf8

}

function Get-ValueType {
  param (
    [Parameter()]$Value
  )
  if ($Value -match '\$(true|false)') {
    return "boolean"
  } elseif ($Value -match '\d+') {
    return "number"
  } else {
    return "string"
  }
}

function Get-SettingByVariableName {
  param (
    [Parameter()] [Object]$Settings,
    [Parameter()] [String]$VariableName
  )
  $data = $Settings.Matches.Groups.Where({$_.Value -imatch $VariableName})[0].Groups

  if ($null -eq $data) {
    return @($null, $null)
  }

  return @(
    $data.Where({$_.Name -eq "title"}).Value.Replace('"', '').Trim()
    $data.Where({$_.Name -eq "val"}).Value.Replace('"', '').Trim()
  )
}

function Get-SettingData {
  param (
    [Parameter()] [Object]$Setting
  )
  return @(
    $Setting.Groups.Where({$_.Name -eq "title"}).Value.Replace('"', '').Trim()
    $Setting.Groups.Where({$_.Name -eq "var"}).Value.Replace('"', '').Trim()
    $Setting.Groups.Where({$_.Name -eq "val"}).Value.Replace('"', '').Trim()
  )
}

function Restore-DefaultConfig {
  param (
    [parameter()] [String]$FileName
  )
  # $content = Get-Content -Path .\GlobalVariables.ps1 -Raw
  # [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
  $defaultConfig = "IyBZb3UgY2FuIGNoYW5nZSB0aGUgZm9sbG93aW5nIGRlZmF1bHRzIGJ5IGFsdGVyaW5nIHRoZSBiZWxvdyBzZXR0aW5nczoKCiMgU2V0IHRoZSBmb2xsb3dpbmcgdG8gdHJ1ZSB0byBlbmFibGUgdGhlIHNldHVwIHdpemFyZCBmb3IgZmlyc3QgdGltZSBydW4KJFNldHVwV2l6YXJkID0gJGZhbHNlCgojIFN0YXJ0IG9mIFNldHRpbmdzCiMgTGFuZ3VhZ2UgY3VsdHVyZSB0byB1c2UKJEN1bHR1cmUgPSAiZW4tVVMiCgojIFJlcG9ydCBoZWFkZXIKJFJlcG9ydFRpdGxlID0gIlBvd2VyQ2hlY2sgcmVwb3J0IgojIFdvdWxkIHlvdSBsaWtlIHRoZSByZXBvcnQgZGlzcGxheWVkIGluIHRoZSBsb2NhbCBicm93c2VyIG9uY2UgY29tcGxldGVkPwokRGlzcGxheXRvU2NyZWVuID0gJHRydWUKIyBEaXNwbGF5IHRoZSByZXBvcnQgZXZlbiBpZiBpdCBpcyBlbXB0eT8KJERpc3BsYXlSZXBvcnRFdmVuSWZFbXB0eSA9ICRmYWxzZQojIFVzZSB0aGUgZm9sbG93aW5nIGl0ZW0gdG8gZGVmaW5lIGlmIGFuIGVtYWlsIHJlcG9ydCBzaG91bGQgYmUgc2VudCBvbmNlIGNvbXBsZXRlZAokU2VuZEVtYWlsID0gJGZhbHNlCiMgUGxlYXNlIFNwZWNpZnkgdGhlIFNNVFAgc2VydmVyIGFkZHJlc3MgKGFuZCBvcHRpb25hbCBwb3J0KSBbc2VydmVybmFtZSg6cG9ydCldCiRTTVRQU1JWID0gInNtdHBzZXJ2ZXIuZG9tYWluLmxvY2FsIgojIFdvdWxkIHlvdSBsaWtlIHRvIHVzZSBTU0wgdG8gc2VuZCBlbWFpbD8KJEVtYWlsU1NMID0gJGZhbHNlCiMgUGxlYXNlIHNwZWNpZnkgdGhlIGVtYWlsIGFkZHJlc3Mgd2hvIHdpbGwgc2VuZCB0aGUgdkNoZWNrIHJlcG9ydAokRW1haWxGcm9tID0gInBvd2VyY2hlY2tAZG9tYWluLmxvY2FsIgojIFBsZWFzZSBzcGVjaWZ5IHRoZSBlbWFpbCBhZGRyZXNzKGVzKSB3aG8gd2lsbCByZWNlaXZlIHRoZSB2Q2hlY2sgcmVwb3J0IChzZXBhcmF0ZSBtdWx0aXBsZSBhZGRyZXNzZXMgd2l0aCBjb21tYSkKJEVtYWlsVG8gPSAicmVwb3J0c0Bkb21haW4ubG9jYWwiCiMgUGxlYXNlIHNwZWNpZnkgdGhlIGVtYWlsIGFkZHJlc3MoZXMpIHdobyB3aWxsIGJlIENDZCB0byByZWNlaXZlIHRoZSB2Q2hlY2sgcmVwb3J0IChzZXBhcmF0ZSBtdWx0aXBsZSBhZGRyZXNzZXMgd2l0aCBjb21tYSkKJEVtYWlsQ2MgPSAiIgojIFBsZWFzZSBzcGVjaWZ5IGFuIGVtYWlsIHN1YmplY3QKJEVtYWlsU3ViamVjdCA9ICJQb3dlckNoZWNrIFJlcG9ydCIKIyBTZW5kIHRoZSByZXBvcnQgYnkgZS1tYWlsIGV2ZW4gaWYgaXQgaXMgZW1wdHk/CiRFbWFpbFJlcG9ydEV2ZW5JZkVtcHR5ID0gJHRydWUKIyBFbWFpbCBmb3JtYXQgW2h0bWx8dGV4dF0KJEVtYWlsQm9keUZvcm1hdCA9ICJodG1sIgojIFNvdXJjZSBvZiBmb3IgdGhlIGJvZHkgb2YgdGhlIGVtYWlsIGlmIGNsaWVudCBkb2Vzbid0IHN1cHBvcnQgSFRNTCBvciBFbWFpbEJvZHlGb3JtYXQgaXMgdGV4dCBbZGVmYXVsdHxyZXBvcnR8ZmlsZV0KJEVtYWlsQm9keVRleHRTb3VyY2UgPSAiZGVmYXVsdCIKIyBJZiB5b3Ugd291bGQgcHJlZmVyIHRoZSBIVE1MIGZpbGUgYXMgYW4gYXR0YWNobWVudCB0aGVuIGVuYWJsZSB0aGUgZm9sbG93aW5nCiRTZW5kQXR0YWNobWVudCA9ICRmYWxzZQojIFNldCB0aGUgc3R5bGUgdGVtcGxhdGUgdG8gdXNlCiRTdHlsZSA9ICJDbGFyaXR5IgojIFBhdGggdG8gdGhlIGJhbm5lciBpbWFnZSwgc2V0IHRvIGZhbHNlIHRvIHVzZSB0aGUgZGVmYXVsdCBiYW5uZXIKJEJhbm5lciA9ICRmYWxzZQojIERvIHlvdSB3YW50IHRvIGluY2x1ZGUgcGx1Z2luIGRldGFpbHMgaW4gdGhlIHJlcG9ydD8KJFJlcG9ydE9uU2NyaXB0TGlzdCA9ICR0cnVlCiMgTGlzdCBFbmFibGVkIHNjcmlwdHMgZmlyc3QgaW4gUGx1Z2luIFJlcG9ydD8KJExpc3RFbmFibGVkU2NyaXB0c0ZpcnN0ID0gJHRydWUKIyBTZXQgdGhlIGZvbGxvd2luZyBzZXR0aW5nIHRvICR0cnVlIHRvIHNlZSBob3cgbG9uZyBlYWNoIHNjcmlwdCB0YWtlcyB0byBydW4gYXMgcGFydCBvZiB0aGUgcmVwb3J0CiRSZXBvcnRPblRpbWVUb1J1biA9ICR0cnVlCiMgUmVwb3J0IG9uIHNjcmlwdHMgdGhhdCB0YWtlIGxvbmdlciB0aGFuIHRoZSBmb2xsb3dpbmcgYW1vdW50IG9mIHNlY29uZHMKJFNjcmlwdFJ1bnRpbWVTZWNvbmRzID0gMzAKIyBEaXNwbGF5IHRoZSBuYW1lIG9mIHRoZSBkaXJlY3RvcnkgdGhhdCBjb250YWlucyBhIGdyb3VwIG9mIHNjcmlwdHMKJFNjcmlwdEdyb3VwU2hvd05hbWUgPSAkdHJ1ZQojIFJlbW92ZSBhbnkgbnVtYmVycyBwcmVmaXhpbmcgdGhlIG5hbWUgb2YgcGx1Z2luIGdyb3VwIGRpcmVjdG9yeSBuYW1lCiRTY3JpcHRHcm91cFJlbW92ZUluZGV4ID0gJHRydWUKIyBTYXZlIGEgY29weSBvZiB0aGUgcmVwb3J0IHRvIHRoZSBSZXBvcnRzIGZvbGRlcgokS2VlcFJlcG9ydCA9ICR0cnVlCiMgX1BPV0VSQ0hFQ0tfLCBfUExVR0lOXyAoZm9yIHJlbGF0aXZlIHBhdGhzIHRvIFBvd2VyQ2hlY2sgb3IgUGx1Z2luIGxvY2F0aW9uKSwgRnVsbCBvciBVTkMgcGF0aCB3aGVyZSB0byBzYXZlIHRoZSBodG1sIHJlcG9ydCBmaWxlCiRSZXBvcnRzRm9sZGVyUGF0aCA9ICJfUE9XRVJDSEVDS19cUmVwb3J0cyIKIyBIVE1MIHJlcG9ydCBmaWxlbmFtZSBmb3JtYXQKJFJlcG9ydEZpbGVuYW1lRm9ybWF0ID0gIl9EQVRFXy1Qb3dlckNoZWNrLV9QTFVHSU5fIgojIFNhdmUgcmVwb3J0IGRhdGEgYXMgSlNPTgokRXhwb3J0SnNvbiA9ICR0cnVlCiMgX1BPV0VSQ0hFQ0tfLCBfUExVR0lOXyAoZm9yIHJlbGF0aXZlIHBhdGhzIHRvIFBvd2VyQ2hlY2sgb3IgUGx1Z2luIGxvY2F0aW9uKSwgRnVsbCBvciBVTkMgcGF0aCB3aGVyZSB0byBzYXZlIHRoZSBKU09OIGZpbGUKJEpzb25GaWxlUGF0aCA9ICJfUE9XRVJDSEVDS19cUmVwb3J0cyIKIyBKU09OIHJlcG9ydCBmaWxlbmFtZSBmb3JtYXQKJEpzb25GaWxlbmFtZUZvcm1hdCA9ICJfREFURV8tUG93ZXJDaGVjay1fUExVR0lOXyIKIyBFbmQgb2YgU2V0dGluZ3MKCiMgRW5kIG9mIEdsb2JhbCBWYXJpYWJsZXMKCiMgU3VwcHJlc3MgVXNlRGVjbGFyZWRWYXJzTW9yZVRoYW5Bc3NpZ25tZW50cyB3YXJubmluZyBpbiBWUyBDb2RlCiRudWxsID0gJFNldHVwV2l6YXJkLCAkQ3VsdHVyZSwKJFJlcG9ydFRpdGxlLCAkRGlzcGxheXRvU2NyZWVuLCAkRGlzcGxheVJlcG9ydEV2ZW5JZkVtcHR5LCBgCiRTZW5kRW1haWwsICRTTVRQU1JWLCAkRW1haWxTU0wsICRFbWFpbEZyb20sICRFbWFpbFRvLCAkRW1haWxDYywKJEVtYWlsU3ViamVjdCwgJEVtYWlsUmVwb3J0RXZlbklmRW1wdHksICRFbWFpbEJvZHlGb3JtYXQsICRFbWFpbEJvZHlUZXh0U291cmNlLCAkU2VuZEF0dGFjaG1lbnQsIGAKJFN0eWxlLCAkQmFubmVyLCBgCiRSZXBvcnRPblNjcmlwdExpc3QsICRMaXN0RW5hYmxlZFNjcmlwdHNGaXJzdCwgJFJlcG9ydE9uVGltZVRvUnVuLCAkU2NyaXB0UnVudGltZVNlY29uZHMsICRTY3JpcHRHcm91cFNob3dOYW1lLCAkU2NyaXB0R3JvdXBSZW1vdmVJbmRleCwgYAokS2VlcFJlcG9ydCwgJFJlcG9ydHNGb2xkZXJQYXRoLCAkUmVwb3J0RmlsZW5hbWVGb3JtYXQsIGAKJEV4cG9ydEpzb24sICRKc29uRmlsZVBhdGgsICRKc29uRmlsZW5hbWVGb3JtYXQ="
  $config = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($defaultConfig))
  $config | Out-File -FilePath $FileName -Encoding utf8
}

function Test-Configuration {
  param (
    [parameter()] [String]$FileName = ".\GlobalVariables.ps1"
  )

  if (-not (Test-Path -Path $FileName)) {
    throw "Could not open file $FileName"
  }
}

function Get-GlobalVariables {
  param (
    [Parameter(Mandatory=$true)] [String]$PowerCheckPath,
    [Parameter(Mandatory=$true)] [String]$PluginRootPath,
    [Parameter(Mandatory=$true)] [Object]$GlobalVars
  )
  if (Test-Path -Path $PowerCheckPath\GlobalVariables.ps1) {
    . $PowerCheckPath\GlobalVariables.ps1
  }
  if (Test-Path -Path $PluginRootPath\GlobalVariables.ps1) {
    . $PluginRootPath\GlobalVariables.ps1
  }

  foreach ($var in $varlist) {
    $value = Get-Variable -Name $var -ErrorAction SilentlyContinue
    if ( $value ) {
      $GlobalVars.Add($var, $value.Value)
    } else {
      throw "Global variable ""$var"" is not defined, please define this variable or run '.\PowerCheck.ps1 -ResetGlobalConfig' to recreate the default configuration file."
    }
    $value = $null
  }
  return $GlobalVars
}

function Clear-GlobalVariables {
  foreach ($variable in $varlist) {
    Clear-Variable -name $variable -Force -ErrorAction SilentlyContinue
  }
}

Export-ModuleMember -Function Set-Configuration
Export-ModuleMember -Function Restore-DefaultConfig
Export-ModuleMember -Function Test-Configuration
Export-ModuleMember -Function Get-GlobalVariables
Export-ModuleMember -Function Clear-GlobalVariables
