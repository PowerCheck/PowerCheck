
# Start of Settings

# End of Settings

Get-Date | Select-Object DayOfWeek,Day,Month,Year,TimeOfDay

$Title = "Time"
$Header = "Time and date"
$Comments = "Script run time"
$Display = "Table"
$Author = "Luis Tavares"
$PluginVersion = 1.0
$PluginCategory = "Category"

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $Title, $Header, $Comments, $Display, $Author, $PluginVersion, $PluginCategory, $TableFormat
