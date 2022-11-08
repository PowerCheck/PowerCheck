
# Start of Settings

# End of Settings

Get-DnsClient | Select-Object InterfaceAlias,ConnectionSpecificSuffix,@{n='SearchList';e={$_.ConnectionSpecificSuffixSearchList -join ","}},RegisterThisConnectionsAddress

$Title = "DNS"
$Header = "DNS"
$Comments = "Interface DNS settings"
$Display = "Table"
$Author = "Luis Tavares"
$PluginVersion = 1.0
$PluginCategory = "Category"

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $Title, $Header, $Comments, $Display, $Author, $PluginVersion, $PluginCategory, $TableFormat
