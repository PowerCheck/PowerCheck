function Get-ReportPluginRoot {
  param (
    [Parameter()] [String]$ScriptPath,
    [Parameter()] [String]$Plugin
  )

  # Plugins \ <plugin> \ scripts|plugins
  # Try to get the location of the plugins folder for the selected plugin
  # 1) $Plugin is the path to the plugin
  # 2) Plugins folder inside PowerCheck
  # 3) Plugins as a sibling of PowerCheck Folder
  $basePath = $null
  if (Test-Path $Plugin\Scripts) {
    $basePath = "."
  } elseif (Test-Path $ScriptPath\Plugins\$Plugin\Scripts) {
    $basePath = "$ScriptPath\Plugins"
  } elseif (Test-Path $ScriptPath\..\Plugins\$Plugin\Scripts) {
    $basePAth = "$ScriptPath\..\Plugins"

  # For compatibilty with vCheck
  } elseif (Test-Path $Plugin\Plugins) {
      $basePath = "."
    } elseif (Test-Path $ScriptPath\Plugins\$Plugin\Plugins) {
      $basePath = "$ScriptPath\Plugins"
    } elseif (Test-Path $ScriptPath\..\Plugins\$Plugin\Plugins) {
      $basePAth = "$ScriptPath\..\Plugins"

  } else {
    return $false
  }

  return Resolve-Path -Path "$basePath\$Plugin"
}

function ConvertTo-Base64Image {
  param (
    [Parameter()] [String]$Filename
  )

  switch ($FileName.Split(".")[1]) {
    "png" { $fileType = "png" }
    "gif" { $fileType = "gif" }
    "jpg" { $fileType = "jpeg"}
    "jpeg" { $fileType = "jpeg" }
    "ico" { $fileType = "ico" }
  }
  if ($Filename) {
    if ( Test-Path $Filename) {
      return ("data:image/{0};base64,{1}" -f $fileType, [convert]::ToBase64String((Get-Content -Path $Filename -Encoding Byte)))
    }
  }
}

function Get-ResourceFiles {
  param (
    [Parameter()] [String]$Style = "Clarity",
    [Parameter()] [String]$Culture = "en-US",
    [Parameter()] [String]$PowerCheckPath,
    [Parameter()] [String]$PluginPath
  )
  $sharedStylePath = "$PowerCheckPath\Styles\$style"
  $customStylePath = "$PluginPath\Styles\$style"
  $sharedStyleFiles = @(Get-ChildItem -Path $sharedStylePath -File -ErrorAction SilentlyContinue)
  $customStyleFiles = @(Get-ChildItem -Path $customStylePath -File -ErrorAction SilentlyContinue)
  $fileListStyles = Compare-ObjecstByProperty -ReferenceObject $sharedStyleFiles -DifferenceObject $customStyleFiles -Property Name

  $sharedLangPath = "$PowerCheckPath\Lang\$Culture"
  $customLangPath = "$PluginPath\Lang\$Culture"
  $sharedLangFiles = Get-ChildItem -Path $sharedLangPath -Filter *.psd1
  $customLangFiles = Get-ChildItem -Path $customLangPath -Filter *.psd1 -ErrorAction SilentlyContinue
  $fileListLang = Compare-ObjecstByProperty -ReferenceObject $sharedLangFiles -DifferenceObject $customLangFiles -Property Name -IncludeCommon -AllowDuplicates

  $favicon = $fileListStyles.Where({$_.Object.Name -match "favicon"}).FullName
  if ( ! $favicon ) {
    $favicon = "$PowerCheckPath\Resources\favicon.png"
  }

  # Add a custom member to Styles and Lang so we can get a file by its name
  $extendScript = { param([String]$filename) if($This.Object.Name.ToLower() -match $filename.ToLower()) {return $This.Object.FullName} }
  $fileListStyles | Add-Member -MemberType ScriptMethod -Name GetFile -Value $extendScript
  $fileListLang | Add-Member -MemberType ScriptMethod -Name GetFile -Value $extendScript

  return [PSCustomObject]@{
    Styles = $fileListStyles
    Lang = $fileListLang
    Favicon = $favicon
  }
}

function Compare-ObjecstByProperty {
  param (
    [Parameter()] [Array]$ReferenceObject,
    [Parameter()] [Array]$DifferenceObject,
    [Parameter()] [String]$Property,
    [Parameter()] [Switch]$IncludeCommon,
    [Parameter()] [Switch]$AllowDuplicates
  )
  $result = @()
  foreach ($obj in $ReferenceObject) {
    if ( $DifferenceObject.($Property) -notcontains $obj.($Property) ) {
      $result += [PsCustomObject]@{
        Source = "ReferenceObject"
        Object = $obj
        IsCommon = $false
      }
    } elseif ($IncludeCommon) {
      $result += [PsCustomObject]@{
        Source = "ReferenceObject"
        Object = $obj
        IsCommon = $true
      }
    }
  }
  foreach ($obj in $DifferenceObject) {
    if ($ReferenceObject.($Property) -notcontains $obj.($Property)) {
      $result += [PsCustomObject]@{
        Source = "DifferenceObject"
        Object = $obj
        IsCommon = $false
      }
    } elseif ($IncludeCommon) {
      if ($result.Object.($Property) -notcontains $obj.($Property)) {
        $result += [PsCustomObject]@{
          Source = "DifferenceObject"
          Object = $obj
          IsCommon = $true
        }
      } elseif ($AllowDuplicates) {
        $result += [PsCustomObject]@{
          Source = "DifferenceObject"
          Object = $obj
          IsCommon = $true
        }
      }
    }
  }
  return $result
}

function Get-UnixTimestamp($d) {
  return [System.Math]::Round(($d - (Get-Date "1970-01-01")).TotalMilliseconds)
}

Export-ModuleMember -Function Get-ReportPluginRoot
Export-ModuleMember -Function ConvertTo-Base64Image
Export-ModuleMember -Function Get-ResourceFiles
Export-ModuleMember -Function Get-UnixTimestamp