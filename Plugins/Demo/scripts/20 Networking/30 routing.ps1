
# Start of Settings

# End of Settings

Get-NetRoute -State Alive | Select-Object InterfaceAlias,AddressFamily,DestinationPrefix,NextHop,RouteMetric | Sort-Object RouteMetric,AddressFamily

$Title = "Routing"
$Header = "Routing"
$Comments = "Route table"
$Display = "Table"
$Author = "Luis Tavares"
$PluginVersion = 1.0
$PluginCategory = "Category"

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $Title, $Header, $Comments, $Display, $Author, $PluginVersion, $PluginCategory, $TableFormat
