
# Start of Settings

# End of Settings

Get-PSDrive -PSProvider FileSystem | Select-Object Name,Description,@{n='UsedGb';e={[Math]::Round($_.Used / 1024000000,2)}},@{n='FreeGb';e={[Math]::Round($_.Free / 1024000000,2)}}

$Title = "Disks"
$Header = "Disks"
$Comments = "System Disks"
$Display = "Table"
$Author = "Luis Tavares"
$PluginVersion = 1.0
$PluginCategory = "Category"

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $Title, $Header, $Comments, $Display, $Author, $PluginVersion, $PluginCategory, $TableFormat