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

        $dateTimeMembers = ($ReportData.Result[$i].Details | Get-Member -MemberType NoteProperty,Property).Where({$_.Definition -match "datetime"}).Name | Sort-Object -Unique
        for ($ii = 0; $ii -lt $ReportData.Result[$i].Details.Count; $ii++) {

          # Cast from PowerShell DateTime to UnixTimestamp
          foreach ($member in $dateTimeMembers) {
            $JsonData.Data[$i].Details[$ii].($member) = Get-UnixTimestamp $ReportData.Result[$i].Details[$ii].($member)
          }

        }
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