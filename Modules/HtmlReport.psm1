Add-Type -AssemblyName System.Web

function Get-HtmlReport {
  param (
    [Parameter(Mandatory=$true)] [ValidateSet("html", "email")][String]$Format,
    [Parameter(Mandatory=$true)] [Object]$GlobalVars,
    [Parameter(Mandatory=$true)] [Object]$ResourceFiles,
    [Parameter(Mandatory=$true)] [Object]$ReportData,
    [Parameter()] [Object]$Localization,
    [Parameter()] [String]$ReportPath,
    [Parameter()] [String]$ReportFilename,
    [Parameter()] [Switch]$ReturnHtml,
    [Parameter()] [String]$PowerCheckPath
  )

  # If Format is email, should images added inline or embedded (cid:....)
  $inlineImageAttachments = $true
  $attachments = @()
  $searchBar = $null
  $toc = $null
  $data = ($ReportData.Result | Where-Object { $_.Details.Count -gt 0})

  # What image to use for the banner
  $bannerfilename = $ResourceFiles.Styles.GetFile("banner") | Select-Object -Last 1
  if ($GlobalVars.Banner)  {
    if (Test-Path -LiteralPath $GlobalVars.Banner -ErrorAction SilentlyContinue) {
      $bannerfilename = $GlobalVars.Banner
    }
  }

  # Added images inline or embedded
  if ( $inlineImageAttachments ) {
    $banner = ConvertTo-Base64Image -Filename $bannerfilename
  } else {
    $banner = $null
    $attachments += New-Object System.Net.Mail.Attachment($bannerfilename)
  }

  # If the report format is HTML, then include favicon, searchbar and table of contents
  if ($Format -eq "html") {
    if (Test-Path -Path $PowerCheckPath\Resources\searchbar.html) {
      $searchBar = Get-Content -Path $PowerCheckPath\Resources\searchbar.html -Raw
    }
    $toc = Get-HtmlTOC -ReportData $data -GlobalVars $GlobalVars
  }

  $xmlKeys = [PSCustomObject]@{
    "report-header" = "PowerCheck"
    "report-title" = $GlobalVars.ReportTitle
    # As no content manipulation is done with TOC, we can use as plain HTML
    "navlist" = $toc
    "footer" = ("<p>PowerCheck {0} by <a href='https://github.com/irsheep/PowerCheck' target='_blank'>Luis Tavares</a> generated on {1}, on the {2} at {3}</p>" -f $GlobalVars.Version, $env:COMPUTERNAME, $ReportData.StartDate.ToLongDateString(), $ReportData.StartDate.ToLongTimeString() )
  }

  # Get the HTML template file converting it to an XML document
  $xml = [xml](Get-Content $ResourceFiles.Styles.GetFile("main.html"))
  $head = $xml.html.head
  $body = $xml.html.body

  if ($Format -eq "email") {
    Remove-ElementChild -XmlElement ([ref]$head) -XPathSelector "//*[@rel='icon']"
  }

  # Embed header resource files
  $head.title = $GlobalVars.ReportTitle
  $head.link.ForEach({
    $resFile = ($_.href.Split("/"))[-1]
    if ($_.rel -eq "icon") {
      $_.href = ("{0}" -f (ConvertTo-Base64Image -Filename $ResourceFiles.Favicon))
    } elseif ($_.rel -eq "stylesheet") {
      $new = $xml.CreateElement("style")
      $new.SetAttribute("type","text/css")
      $new.InnerText = Get-Content -Path $ResourceFiles.Styles.GetFile("$resFile") -Raw -Encoding UTF8
      $null = $head.ReplaceChild($new, $_)
    }
  })

  # Check for the banner in the CSS styles and replace it with its base64 encoded string
  # the banner has to be defined as 'background-image: url(...)' in a banner class(.banner)
  $head.style.foreach({
    $bannerMatches = $_.InnerText | Select-String "(?smi).banner\s*?{.*?background-image\s*?:\s*?url\(['""](?<banner>.+?)['""]\s*?\)"
    if ($null -ne $bannerMatches) {
      $bannerUrl = $bannerMatches.matches.Groups.Where({$_.Name -eq "banner"}).Value
      if ( $inlineImageAttachments ) {
        $_.InnerText = $_.InnerText -replace "$bannerUrl", $banner
      } else {
        # Banner might not always be index 0, but will do for now
        $_.InnerText =  $_.InnerText -replace "$bannerUrl", ("cid:{0}" -f $attachments[0].ContentId) 
      } 
    }
  })

  # Remove elements from the document
  Remove-ElementChild -XmlElement ([ref]$body) -XPathSelector "//*[@powercheck='element:sample']"
  if ($Format -eq "email") {
    Remove-ElementChild -XmlElement ([ref]$body) -XPathSelector "//*[@powercheck='element:menu']"
  }

  # Replace text in the required XML nodes
  $body.SelectNodes("//*[@powercheck]").ForEach({
    $node = $_
    $node.powercheck.split(" ").ForEach({
      switch -Wildcard ($_) {
        # Replace/add value to node inner text
        'val:*' {
          ($key, $val) = $_.Split(":")
          $node.InnerText = $xmlKeys.($val)
        }
      }
    })
  })

  # Add plugin report data to the xml document
  $pluginReportData = Get-HtmlReportContent -ReportData $data -ResourceFiles $ResourceFiles -GlobalVars $GlobalVars -PluginList $xml.html.body.SelectSingleNode("//*[@powercheck='element:scripts-list']")
  $pluginListElement = $xml.html.body.SelectSingleNode("//*[@powercheck='element:scripts-list']")
  $pluginListElement.RemoveAll()
  foreach ($reportElement in $pluginReportData) {
    $null = $pluginListElement.AppendChild($reportElement)
  }

  # Add the footer, this could be done with SelectSingleNode,
  # but this way avoids checking if the footer exists
  $xml.html.body.SelectNodes("//footer").ForEach({
    $_.InnerText = $xmlKeys.footer
  })

  # Removes all powercheck and xmlns attributes
  $xml.SelectNodes("//*[@powercheck|xmlns]").ForEach({
    $_.RemoveAttribute("powercheck")
    $_.RemoveAttribute("xmlns")
  })

  $html = [System.Web.HttpUtility]::HtmlDecode($xml.html.OuterXml)

  # Due to the contents of the searchbar.html it cannot be handled as XML
  # so we replace the <search /> node with its content in the HTML string
  $searchBar = $searchBar -replace "searchBarInput.placeholder\s*?=\s*?['""].*?['""]\s*?;", ("searchBarInput.placeholder = ""{0}"";" -f $Localization.Search)
  $html = $html -replace "<searchbar\s*?/?\s*?>", $searchBar

  if (-not $ReturnHtml) {
    $ReportPath = (Resolve-Path -Path $ReportPath).Path
    if (Test-Path -Path $ReportPath) {
      $html | Out-File ("{0}\{1}" -f $ReportPath.TrimEnd("\"), $ReportFilename)
    }
  } else {
    return [PSCustomObject]@{
      html = $html
      attachments = $attachments
    }
  }

}

function Get-HtmlReportContent {
  param (
    [Parameter(Mandatory=$true)] [Object]$ReportData,
    [Parameter(Mandatory=$true)] [Object]$ResourceFiles,
    [Parameter(Mandatory=$true)] [Object]$GlobalVars,
    [Parameter(Mandatory=$false)] [System.Xml.XmlElement]$PluginList
  )

  $i = 1
  $scriptGroupName = ""
  $scriptGroupNameShow = $false

  # $xmltemplate = $PluginList.Clone()
  $xmlfragment = $xml.CreateDocumentFragment()

  foreach ($plugin in $ReportData | Where-Object {$_.Display -ne "None" -and $null -ne $_.Details}) {
    $html = $plugin.Details | ConvertTo-Html -Fragment -As $plugin.Display
    $xmlData = [xml]$html

    $headers = $html | Select-String "(?smi)<tr>(<th>(.*?)<\/th>)*<\/tr>"
    $rows = $html | Select-String "(?smi)<tr>(<td>(.*?)<\/td>)*<\/tr>"

    $tableFormat = $plugin.TableFormat
    if ($tableFormat) {
      # Fields (Keys) in TableFormat
      foreach ($fieldName in $tableFormat.Keys) {
        $colIndex = [array]::IndexOf($headers.Matches[0].Groups[2].Captures.Value, $fieldName)
        # Conditions in TableFormat for the current field
        foreach ($formatObject in $tableFormat.($fieldName)) {
          $formatCondition = $formatObject.Keys[0]
          foreach ($row in $rows.Matches) {
            $value = $row.Groups[2].Captures[$colIndex].Value
            if ($value -notmatch "^[0-9\.]+$") { [String]$value = """$value""" }
            if ( Invoke-Expression ("{0} {1}" -f $value, [String]$formatCondition) ) {
              ($element, $code) =  $formatObject.Values[0].Split(",")
              ($attributeName, $attributeValue) = $code.Split("|")
              if ($element -eq "row") {
                $xmlData.Table.SelectNodes( ("/table/tr/td[{0}][text()={1}]" -f ($colIndex+1), $value) ).ParentNode.SetAttribute($attributeName, $attributeValue)
              }
              elseif ($element -eq "cell") {
                $xmlData.Table.SelectNodes( ("/table/tr/td[{0}][text()={1}]" -f ($colIndex+1), $value) ).SetAttribute($attributeName, $attributeValue)
              }
            }
          }
        }
      }
      $tableFormat = $false
    }

    # Set the proper format if the plugin display mode is list
    if ($plugin.Display.ToLower() -eq "list") {
      $xmlData.Table.SelectNodes( "/table" ).SetAttribute("class", "list")
      # ConvertTo-Html as List adds ":" to the first column, this removes it
      $xmlData.SelectNodes("/table/tr/td[1]").ForEach({
        $_.InnerText = $_.InnerText.TrimEnd(":")
      })
    }

    # Add the header with the plugin name
    if ($plugin.Script -and $GlobalVars.ScriptGroupShowName) {
      if ( $plugin.Script.Split("\")[0] -ne $scriptGroupName -and -not $scriptGroupNameShow ) {
        $scriptGroupName = $plugin.Script.Split("\")[0]
        $scriptGroupNameShow = $true
      }
    } else {
      if ($scriptGroupName -ne "PowerCheck" -and $GlobalVars.ScriptGroupShowName) {
        $scriptGroupName = "PowerCheck"
        $scriptGroupNameShow = $true
      }
    }

    $attributeMap = @{
      'group-name' = $(&{if(-not $GlobalVars.ScriptGroupRemoveIndex){$scriptGroupName}else{$scriptGroupName -replace "^\d+\s+?", ""}})
      'script-header' = $plugin.Header
      'script-comments' = $plugin.Comments
    }

    # Search for 'powercheck' attributes in the nodes
    # and preform the action.
    $pluginListClone = $PluginList.Clone()
    $pluginListClone.SelectNodes("//*[@powercheck]").ForEach({
      $node = $_
      $node.powercheck.split(" ").ForEach({
        switch -Wildcard ($_) {
          # Replace/add value to node inner text
          'val:*' {
            ($key, $val) = $_.Split(":")
            if ($val -ne "script-data") {
              $node.InnerText = $attributeMap.($val)

              # Show only the first group name header
              if ($val -eq "group-name" -and -not $scriptGroupNameShow) {
                $node.SetAttribute("style", "display:none")
                $node.SetAttribute("powercheck", "delete")
              }
            } else {
              # Insert the table with plugin data into the XML document
              $node.SetAttribute("script-groupid", $i)
              $null = $node.AppendChild($pluginListClone.OwnerDocument.ImportNode($xmlData.Table, $true))
            }
          }
          # Adds custom attributes to the node
          'attr:*' {
            ($key, $attr, $val) = $_.Split(":")
            if ($attr -eq "script-groupid") {
              $node.SetAttribute("script-groupid", $i)
            } elseif ($val -eq "script-id") {
              $node.SetAttribute($attr, "script-$i")
            } else {
              $node.SetAttribute($attr, $val)
            }
          }
        }
      })
    })

    # Adds nodes to main document
    $pluginListClone.SelectNodes("*").ForEach({
      $null = $xmlfragment.AppendChild($_)
    })

    # Removes all nodes with the delete attribute
    $pluginListClone.SelectNodes("//*[@powercheck='delete']").ForEach({
      $xmlfragment.RemoveChild($_)
    })

    $scriptGroupNameShow = $false
    $i ++
  }

  return $xmlfragment
}

function Get-HtmlTOC {
  param (
    [Parameter(Mandatory=$true)] [Object]$ReportData,
    [Parameter(Mandatory=$true)] [Object]$GlobalVars
  )

  $li = ""
  $i = 1
  $scriptGroupNameShow = $false
  foreach ($scriptData in $ReportData | Where-Object {$_.Display -ne "None" -and $null -ne $_.Details} | Select-Object Name,Title,Script) {

    # Add the header with the plugin name
    if ($scriptData.Script -and $GlobalVars.ScriptGroupShowName) {
      if ($scriptData.Script.Split("\")[0] -ne $scriptGroupName -and -not $scriptGroupNameShow) {
        $scriptGroupName = $scriptData.Script.Split("\")[0]
        $li += ("<li class='nav-list-header'>{0}</li>" -f $(&{if(-not $GlobalVars.ScriptGroupRemoveIndex){$scriptGroupName}else{$scriptGroupName -replace "^\d+\s+?", ""}}))
        $scriptGroupNameShow = $true
      }
    } else {
      if ($scriptGroupName -ne "PowerCheck" -and $GlobalVars.ScriptGroupShowName) {
        $li += "<li class='nav-list-header'>PowerCheck</li>"
        $scriptGroupName = "PowerCheck"
        $scriptGroupNameShow = $true
      }
    }
    $scriptGroupNameShow = $false

    $li += ("<li><a class='nav-link' href='#script-{0}'>{1}</a></li>" -f $i, $scriptData.Title)
    $i ++
  }

  return $li
}

function Remove-ElementChild() {
  param (
    [Parameter()] [ref]$XmlElement,
    [Parameter()] [String]$XPathSelector
  )

  $node = $XmlElement.Value.SelectSingleNode($XPathSelector)
  if ($node) {
    $parent = $node.ParentNode
    $null = $parent.RemoveChild($node)
  }

}

Export-ModuleMember -Function Get-HtmlReport