function Import-Localization {
  param (
    [Parameter()] [String]$PowerCheckPath,
    [Parameter()] [String]$Culture = "en-US"
  )

  $mainLanguageFile = "PowerCheck"
  Import-LocalizedData -BaseDirectory "$PowerCheckPath\lang" -BindingVariable LangDefault -FileName $mainLanguageFile -UICulture en-US -ErrorAction SilentlyContinue
  if ($Culture -ne "en-US") {
    Import-LocalizedData -BaseDirectory "$PowerCheckPath\lang" -BindingVariable LangUser -FileName $mainLanguageFile -UICulture $Culture -ErrorAction SilentlyContinue
  }

  # Merge default messages from en-US into the user language if they are missing.
  if ($Culture -ne "en-US") {
    foreach ($key in $LangDefault.Keys) {
      if ($langUser.Keys -notcontains $key) {
        $langUser.($key) = $LangDefault.($key)
      }
    }
    return $LangUser
  }

  return $LangDefault

}

function Import-PluginLocalization {
  param (
    [Parameter(Mandatory=$false)] [String]$Culture = "en-US",
    [Parameter(Mandatory=$true)] [String]$PluginRoot
  )

  $data = @{}
  foreach($file in Get-ChildItem -Path "$PluginRoot\lang\$Culture" -Include *.psd1 -Recurse) {
    Import-LocalizedData -BaseDirectory "$PluginRoot\lang\$Culture" -FileName $file.Name -BindingVariable lang -UICulture $Culture
    $data.($file.Name.Split(".")[0]) = $lang
  }

  return $data
}

Export-ModuleMember -Function Import-Localization
Export-ModuleMember -Function Import-PluginLocalization