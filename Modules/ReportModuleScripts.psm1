function Get-ScriptKeyInfo {
  param (
    [Parameter()] [String]$content,
    [Parameter()] [String]$key
  )
  $m = $content | Select-String -Pattern "\$+${key}\s+=\s+(?<key>.+)\s?"
  $value = $m.Matches.Groups | Where-Object { $_.Name -eq "key" }
  if ($null -eq $value) {
    return $null
  } else {
    return ($value.Value.Replace("""", ""))
  }
}

function Get-ReportPluginInfo {
  param (
    [Parameter()] [String]$Filename
  )
  $content = Get-Content -Path $Filename -Raw

  $Header = Get-ScriptKeyInfo $content "Header"
  $Title = Get-ScriptKeyInfo $content "Title"
  if (!$Title) { $Title = $Filename }
  $Comments = Get-ScriptKeyInfo $content "Comments"

  $Display = Get-ScriptKeyInfo $content "Display"

  $Author = Get-ScriptKeyInfo $content "Author"
  $Version = ("{0:N1}" -f (Get-ScriptKeyInfo $content "PluginVersion") )
  $Category = Get-ScriptKeyInfo $content "Plugincategory"

  return [PSCustomObject]@{
    Title = $Title
    Header = $Header
    Comments = $Comments

    Author = $Author
    Version = $Version
    Category = $Category

    Display = $Display
  }
}

function Get-ReportPluginScripts {
  param (
    [Parameter()] [String]$PluginRoot
  )

  $scripts = Get-ChildItem -Path $PluginRoot\Scripts\ -Include *.ps1, *.ps1.disabled  -Recurse | Sort-Object Directory,FullName
  return $scripts
}

function Get-ReportPluginLocalizationFiles {
  param (
    [Parameter()] [String]$PluginRoot
  )
  $langFiles = Get-ChildItem -Path $PluginRoot\lang\ -Include *.psd1 -Recurse
  return $langFiles
}

function Invoke-ReportPluginScripts {
  param (
    [Parameter()] [String]$PluginRootPath,
    [Parameter()] [Object]$ScriptList,
    [Parameter()] [Object]$Localization
  )

  $scriptsEnabled = $ScriptList | Where-Object { $_.Name -notmatch ".ps1.disabled" }

  $pluginResult = @()
  $i = 1
  foreach ($script in $scriptsEnabled ) {
    $pluginStatus = ("[{0} of {1}] {2}" -f $i, $scriptsEnabled.Length, $script.Name)

    Write-Progress -ID 1 -Activity "Evaluating plugins" -Status $pluginStatus -PercentComplete (100 * $i/($scriptsEnabled.count))
    Write-LogPluginExecution -Current $i -Total $scriptsEnabled.Length -ScriptName ($script.FullName.Split("\")[-2,-1] -join " \ ")

    try {
	    $Display = "Table"
      $timeToRun = [System.Math]::Round( (Measure-Command { $details = @(. $script.FullName; $null = $details) }).TotalSeconds, 2 )
      Write-Host Ok -ForegroundColor Green
    } catch {
      Write-Host Error -ForegroundColor Red
      Write-Host "Error running plugin:`n$_`n" -ForegroundColor Red
	    $timeToRun = -1
      $details = $null
    } finally {
      # Write full message to log file
      $scriptName = $script.FullName.Split("\")[-2,-1] -join "\"
      if ($script.Directory.Name -eq "Scripts") {
        $scriptName = "{0}\{1}" -f $Localization.PluginRoot, $script.Name
      }
    }

    $pluginResult += [PSCustomObject]@{
      Name = $script.Name.Split(".")[0]

      Title = $Title
      Header = $Header
      Comments = $Comments

      Author = $Author
      Version = $PluginVersion
      Category = $PluginCategory

      Display = $Display
      Details = $details
      TimeToRun = $timeToRun

      TableFormat = $TableFormat

      # Json Extra data
      Order = $i
      Script = $scriptName
    }

    $TableFormat = $false
    $i++
  }
  Write-Progress -ID 1 -Activity "Evaluating plugins" -Status "Complete" -Completed

  return $pluginResult | Where-Object { $null -ne $_.Details }
}

function Get-ReportPluginPluginReport {
  param (
    [Parameter()] [String]$Author,
    [Parameter()] [String]$Version,
    [Parameter()] [Object]$LanguageData,
    [Parameter()] [Object]$ScriptList,
    [Parameter()] [Boolean]$ListEnabledScriptsFirst=$false
  )
  $plugins = @()

  foreach ($plugin in $ScriptList) {
    $plugins += [PSCustomObject]@{
      Name = (Get-ReportPluginInfo $plugin.FullName).Title
      Enabled = $plugin.FullName -notmatch (".ps1.disabled")
    }
  }

  if ($ListEnabledScriptsFirst) {
    $plugins = $plugins | Sort-Object -Property Enabled -Descending
  }

  # return $plugins
  return [PSCustomObject]@{
    Name = "PluginList"

    Title = $LanguageData.slTitle
    Header = $LanguageData.slHeader
    Comments = $LanguageData.slComments

    Author = $Author
    Version = $Version
    Category = "PowerCheckCore"

    Display = "Table"
    Details = $plugins
    TableFormat = $null
  }
}

function Get-ReportPluginTimeToRun {
  param (
    [Parameter()] [String]$Author,
    [Parameter()] [String]$Version,
    [Parameter()] [Object]$LanguageData,
    [Parameter()] [DateTime]$StartDate,
    [Parameter()] [DateTime]$FinishDate,
    [Parameter()] [Object]$PluginResult,
    [Parameter()] [Int32]$ScriptRuntimeSeconds
  )

  return [PSCustomObject]@{
    Name = "TimeToRun"

    Title = $LanguageData.ttrTitle
    Header = ($LanguageData.ttrHeader -f [System.Math]::round(($FinishDate - $StartDate).TotalMinutes, 2), ($FinishDate.ToLongDateString()), ($FinishDate.ToLongTimeString()))
    Comments = ($LanguageData.ttrComments -f $ScriptRuntimeSeconds)

    Author = $Author
    Version = $Version
    Category = "PowerCheckCore"

    Display = "Table"
    Details = @($PluginResult | Where-Object { $_.TimeToRun -gt $ScriptRuntimeSeconds } | Select-Object Title, TimeToRun | Sort-Object TimeToRun -Descending)
    TableFormat = $null
  }
}

function Invoke-Plugin {
  param(
    [Parameter()] [String]$PluginRootPath,
    [Parameter()] [String]$PluginName,
    [Parameter()] [Object]$GlobalVars,
    [Parameter()] [Object]$Localization
  )

  #Region Run the plugin scripts
  $startDate = Get-Date
  $scriptFiles = Get-ReportPluginScripts -PluginRoot $PluginRootPath
  $pluginResult = Invoke-ReportPluginScripts -ScriptList $scriptFiles -PluginRootPath $PluginRootPath -Localization $Localization
  $finishDate = Get-Date
  #EndRegion

  #Region Updates localization messages in the report results
  foreach ($report in $pluginResult ) {
    $temp = $Localization.($report.Name)
    foreach ($key in $temp.Keys) {
      if (($report | Get-Member).Name -contains $key) {
        $report.($key) = $temp.($key)
      } else {
        $report | Add-Member -MemberType NoteProperty -Name $key -Value $temp.($key)
      }
    }
  }
  #EndRegion

  #Region Add list of plugins run to the report
  if ($GlobalVars.ReportOnScriptList) {
    $plugins = Get-ReportPluginPluginReport `
      -Author $GlobalVars.Author `
      -Verbose $GlobalVars.Version `
      -LanguageData $Localization `
      -ScriptList $scriptFiles `
      -ListEnabledScriptsFirst $GlobalVars.ListEnabledScriptsFirst
    # $plugins
    $pluginResult += $plugins
  }
  #EndRegion

  #Region Add Time to run
  if ($GlobalVars.ReportOnTimeToRun) {
    $timeToRunReport = Get-ReportPluginTimeToRun `
      -Author $GlobalVars.Author `
      -Version $GlobalVars.Version `
      -LanguageData $Localization `
      -StartDate $startDate `
      -FinishDate $finishDate `
      -PluginResult $PluginResult `
      -ScriptRuntimeSeconds $GlobalVars.ScriptRuntimeSeconds
    $pluginResult += $timeToRunReport
  }
  #EndRegion

  return [PsCustomObject]@{
    Result = $pluginResult
    ScriptFiles = $scriptFiles
    StartDate = $startDate
    FinishDate = $finishDate
  }
}

function Export-JsonData {
  param(
    [Parameter()] [Object]$GlobalVars,
    [Parameter()] [Object]$ReportData,
    [Parameter()] [String]$PowerCheckPath,
    [Parameter()] [String]$PluginRootPath,
    [Parameter()] [String]$PluginName,
    [Parameter()] [String]$JsonFileName,
    [Parameter()] [String]$JsonFilePath
  )

  if (!(Test-Path -Path $JsonFilePath)) {
    New-Item -Path $JsonFilePath -ItemType Directory -Force
  }

  @{
    Title = $GlobalVars.ReportTitle
    Plugin = $PluginName
    Runtime = @{
      Start = $ReportData.StartDate
      Finish = $ReportData.FinishDate
    }
    Version = $GlobalVars.Version
    Data = $ReportData.Result
    ScriptList = $ReportData.ScriptFiles.FullName.Replace("$PluginRootPath\plugins\","")
  } | ConvertTo-Json -Depth 5 | Out-File -FilePath "$JsonFilePath\$JsonFileName" -Force
}

function Write-LogMessage {
  param(
    [Parameter(Mandatory=$true)] [String]$Message
  )
  $date = Get-Date

  Write-Color -Text `
  ("[{0}.{1}] " -f $date, $date.Millisecond ),
  ("{0} `n" -f $message) `
  -Color Magenta,White
}

function Write-LogPluginExecution {
  param(
    [Parameter()] [int]$Current,
    [Parameter()] [int]$Total,
    [Parameter()] [String]$ScriptName
  )

  $date = Get-Date

  Write-Color -Text `
  ("[{0}.{1}] " -f $date, $date.Millisecond ),
  ("({0}/{1}) " -f $Current, $Total),
  ("{0}... "  -f $ScriptName) `
  -Color Magenta, DarkCyan, White

}

function Write-LogSuccess {
  param (
    [Parameter] [bool]$Success
  )

  if ($true) {
    Write-Host "done" -ForegroundColor Green
  } else {
    Write-Host "Error" -ForegroundColor Red
  }
}

function Write-Color {
  param (
    [Parameter(Mandatory=$true)] [String[]]$Text,
    [Parameter(Mandatory=$true)] [ConsoleColor[]]$Color
  )
  for ($i = 0; $i -lt $Text.Length; $i++) {
      Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
  }
}

Export-ModuleMember -Function Invoke-Plugin
Export-ModuleMember -Function Export-JsonData
Export-ModuleMember -Function Write-LogMessage