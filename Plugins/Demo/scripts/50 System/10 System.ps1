
# Start of Settings

# End of Settings

Get-ComputerInfo | Select-Object `
WindowsBuildLabEx, `
WindowsProductName, `
WindowsCurrentVersion, `
CsNumberOfProcessors, `
CsNumberOfLogicalProcessors, `
CsPhyicallyInstalledMemory, `
OsArchitecture, `
KeyboardLayout `

$Title = "OS Info"
$Header = "OS Info"
$Comments = "Operative System and Hardware info"
$Display = "List"
$Author = "Luis Tavares"
$PluginVersion = 1.0
$PluginCategory = "Category"

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $Title, $Header, $Comments, $Display, $Author, $PluginVersion, $PluginCategory, $TableFormat
