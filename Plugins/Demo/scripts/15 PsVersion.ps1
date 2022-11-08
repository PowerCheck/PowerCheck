
# Start of Settings

# End of Settings

$data = New-Object -TypeName psobject
foreach ( $k in $PSVersionTable.Keys) {
  $data | Add-Member -MemberType NoteProperty -Name $k -Value ($PSVersionTable.($k) -Join ", ")
}
$data

$Title = "PS Version "
$Header = "PowerShell version"
$Comments = "PowerShell version details"
$Display = "List"
$Author = "Luis Tavares"
$PluginVersion = 1.0
$PluginCategory = "Category"

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $Title, $Header, $Comments, $Display, $Author, $PluginVersion, $PluginCategory, $TableFormat
