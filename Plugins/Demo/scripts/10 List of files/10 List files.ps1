
# Start of Settings

# End of Settings

Get-ChildItem | Select-Object Name,LastAccessTime,LastWriteTime

$Title = "File list"
$Header = "PowerCheck files"
$Comments = "List with files on current directory"
$Display = "Table"
$Author = "Luis Tavares"
$PluginVersion = 1.0
$PluginCategory = "Category"

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $Title, $Header, $Comments, $Display, $Author, $PluginVersion, $PluginCategory, $TableFormat
