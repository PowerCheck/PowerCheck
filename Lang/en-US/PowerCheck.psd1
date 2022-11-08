# culture="en-US"
ConvertFrom-StringData @'
  # PowerCheck
  pcStart = PowerCheck is running plugin plugin scripts
  pcStop = PowerCheck finished running plugin scripts
  pcDone = PowerCheck done
  pcJson = Saving JSON report to {0}
  pcHtml = Saving HTML report to {0}
  pcEmail = Sending report via email
  pcEndScriptGlobal = Running PowerCheck EndScript.ps1
  pcEndScriptPlugin = Running Plugin EndScript.ps1

  # ScriptList
  slTitle = Script list
  slHeader = Script list
  slComments = List of scripts in the plugin
  
  # Time to run
  ttrTitle = Time to Run
  ttrHeader = Time to Run
  ttrComments = The following scripts took longer than {0} seconds to run, there may be a way to optimize these or remove them if not needed

  # Email
  emailBody = Hi,\n\n{0} PowerCheck report completed on {1} at {2}\n\nRegards,\nThe PowerCheck Team

  # Misc
  search = Search...
  pluginRoot = Module root
'@