function Invoke-CastMember {
  param (
    [Parameter(Mandatory=$true)] [Object]$ReportData,
    [Parameter(Mandatory=$true)] [Object]$JsonData,
    [Parameter(Mandatory=$false)] [Boolean]$GlobalCasterEnabled = $true
  )

  # Apply global casting
  if ($GlobalCasterEnabled) {
    for ($i = 0; $i -lt $ReportData.Result.Count; $i++) {
      if ($ReportData.Result[$i].Details) {

        $members = ($ReportData.Result[$i].Details | Get-Member -MemberType Property,NoteProperty,ScriptProperty)

        # Loop through all elements in the object
        for ($ii = 0; $ii -lt $ReportData.Result[$i].Details.Count; $ii++) {

          foreach ($member in $members) {
            # Cast element values depending on member type
            switch ($member.Definition.Split(" ")[0]) {
              "datetime" {
                $JsonData.Data[$i].Details[$ii].($member.Name) = Get-UnixTimestamp $ReportData.Result[$i].Details[$ii].($member.Name)
              }
              "timespan" {
                $JsonData.Data[$i].Details[$ii].($member.Name) = $ReportData.Result[$i].Details[$ii].($member.Name).ToString()
              }              
              "System.Net.IPAddress" {
                $JsonData.Data[$i].Details[$ii].($member.Name) = $ReportData.Result[$i].Details[$ii].($member.Name).IpAddressToString
              }
              Default {}
            }
          }

        }

        # Do not auto Cast PowerCheck core scripts
        if ($JsonData.Data[$i].Category -eq "PowerCheckCore") {
          return $JsonData
        }

        # If CastAs is false(not set), then change it to a PSCustomObject
        # so we can add elemets to it.
        $castAs = $JsonData.Data[$i].CastAs
        if ($false -eq $JsonData.Data[$i].CastAs) {
          $castAs = [PSCustomObject]@{}
        }

        # Map datetime properties to UnixTimestamp
        if ( ($unixTimestamp = $members.Where({$_.Definition -match "datetime"}) | Sort-Object Name -Unique ) ){
          if ($null -eq $JsonData.Data[$i].CastAs.UnixTimestamp) {
            $castAs | Add-Member -MemberType NoteProperty -Name UnixTimestamp -Value @($unixTimestamp.Name)
          }
        }

        # Set CastAs as back as $false if the object is empty
        if ( ($castAs | Get-Member -MemberType NoteProperty | Measure-Object).Count -eq 0 ) {
          $castAs = $false
        }

        $JsonData.Data[$i].CastAs = $castAs

      }
    }
  }

  # User defined casting
  for ($i = 0; $i -lt $ReportData.Result.Count; $i++) {
    if ($ReportData.Result[$i].Details) {
      if ($ReportData.Result[$i].CastAs) {
        foreach ($key in $ReportData.Result[$i].CastAs.Keys) {
          switch($key.ToLower()){
            "unixtimestamp" {
              for ($ii = 0; $ii -lt $ReportData.Result[$i].Details.Count; $ii++) {
                foreach ($member in $ReportData.Result[$i].CastAs.($key)) {
                  $JsonData.Data[$i].Details[$ii].($member) = Get-UnixTimestamp $ReportData.Result[$i].Details[$ii].($member)
                }
              }
            }
          }
        }
      }
    }
  }

  return $JsonData
}

Export-ModuleMember -Function Invoke-CastMember