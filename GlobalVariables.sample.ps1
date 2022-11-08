# You can change the following defaults by altering the below settings:

# Set the following to true to enable the setup wizard for first time run
$SetupWizard = $false

# Start of Settings
# Language culture to use
$Culture = "en-US"

# Report header
$ReportTitle = "PowerCheck report"
# Would you like the report displayed in the local browser once completed?
$DisplaytoScreen = $true
# Display the report even if it is empty?
$DisplayReportEvenIfEmpty = $false
# Use the following item to define if an email report should be sent once completed
$SendEmail = $false
# Please Specify the SMTP server address (and optional port) [servername(:port)]
$SMTPSRV = "smtpserver.domain.local"
# Would you like to use SSL to send email?
$EmailSSL = $false
# Please specify the email address who will send the vCheck report
$EmailFrom = "powercheck@domain.local"
# Please specify the email address(es) who will receive the vCheck report (separate multiple addresses with comma)
$EmailTo = "reports@domain.local"
# Please specify the email address(es) who will be CCd to receive the vCheck report (separate multiple addresses with comma)
$EmailCc = ""
# Please specify an email subject
$EmailSubject = "PowerCheck Report"
# Send the report by e-mail even if it is empty?
$EmailReportEvenIfEmpty = $true
# Email format [html|text]
$EmailBodyFormat = "html"
# Source of for the body of the email if client doesn't support HTML or EmailBodyFormat is text [default|report|file]
$EmailBodyTextSource = "default"
# If you would prefer the HTML file as an attachment then enable the following
$SendAttachment = $false
# Set the style template to use
$Style = "Clarity"
# Path to the banner image, set to false to use the default banner
$Banner = $false
# Do you want to include plugin details in the report?
$ReportOnScriptList = $true
# List Enabled scripts first in Plugin Report?
$ListEnabledScriptsFirst = $true
# Set the following setting to $true to see how long each script takes to run as part of the report
$ReportOnTimeToRun = $true
# Report on scripts that take longer than the following amount of seconds
$ScriptRuntimeSeconds = 30
# Display the name of the directory that contains a group of scripts
$ScriptGroupShowName = $true
# Remove any numbers prefixing the name of plugin group directory name
$ScriptGroupRemoveIndex = $true
# Save a copy of the report to the Reports folder
$KeepReport = $true
# _POWERCHECK_, _PLUGIN_ (for relative paths to PowerCheck or Plugin location), Full or UNC path where to save the html report file
$ReportsFolderPath = "_POWERCHECK_\Reports"
# HTML report filename format
$ReportFilenameFormat = "_DATE_-PowerCheck-_PLUGIN_"
# Save report data as JSON
$ExportJson = $true
# _POWERCHECK_, _PLUGIN_ (for relative paths to PowerCheck or Plugin location), Full or UNC path where to save the JSON file
$JsonFilePath = "_POWERCHECK_\Reports"
# JSON report filename format
$JsonFilenameFormat = "_DATE_-PowerCheck-_PLUGIN_"
# End of Settings

# End of Global Variables

# Suppress UseDeclaredVarsMoreThanAssignments warnning in VS Code
$null = $SetupWizard, $Culture,
$ReportTitle, $DisplaytoScreen, $DisplayReportEvenIfEmpty, `
$SendEmail, $SMTPSRV, $EmailSSL, $EmailFrom, $EmailTo, $EmailCc,
$EmailSubject, $EmailReportEvenIfEmpty, $EmailBodyFormat, $EmailBodyTextSource, $SendAttachment, `
$Style, $Banner, `
$ReportOnScriptList, $ListEnabledScriptsFirst, $ReportOnTimeToRun, $ScriptRuntimeSeconds, $ScriptGroupShowName, $ScriptGroupRemoveIndex, `
$KeepReport, $ReportsFolderPath, $ReportFilenameFormat, `
$ExportJson, $JsonFilePath, $JsonFilenameFormat
