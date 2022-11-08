# You can change the following defaults by altering the below settings:

# Set the following to true to enable the setup wizard for first time run
$SetupWizard = $false

# Start of Settings
# Report header
$ReportTitle = "PowerCheck Demo"
# End of Settings

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $SetupWizard, $Culture,
$ReportTitle, $DisplaytoScreen, $DisplayReportEvenIfEmpty, `
$SendEmail, $SMTPSRV, $EmailSSL, $EmailFrom, $EmailTo, $EmailCc,
$EmailSubject, $EmailReportEvenIfEmpty, $EmailBodyFormat, $EmailBodyTextSource, $SendAttachment, `
$Style, $Banner, `
$ReportOnPlugins, $ListEnabledPluginsFirst, $TimeToRun, $PluginSeconds, $PluginGroupShowName, $PluginGroupRemoveIndex, `
$KeepReport, $ReportsFolderPath, $ReportFilenameFormat, `
$ExportJson, $JsonFilePath, $JsonFilenameFormat
