
# Start of Settings

# End of Settings

Get-NetAdapter | Select-Object IfAlias,IfDesc,MacAddress,Status,AdminStatus

$TableFormat = @{
  "Status" = @(
    @{"-eq 'Not Present'" = "row,class|critical"}
    @{"-eq 'Disconnected'" = "cell,class|warning"}
  )
}

$Title = "Network Adapters"
$Header = "Network Adapters"
$Comments = "Network adapter information"
$Display = "Table"
$Author = "Luis Tavares"
$PluginVersion = 1.0
$PluginCategory = "Category"

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $Title, $Header, $Comments, $Display, $Author, $PluginVersion, $PluginCategory, $TableFormat
