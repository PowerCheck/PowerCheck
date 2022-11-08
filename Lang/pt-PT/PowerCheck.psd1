# culture="pt-PT"
ConvertFrom-StringData @'
  # PowerCheck
  pcStart = Executando os scripts do plugin
  pcStop = Concluida a execucat dos scripts
  pcDone = PowerCheck terminou
  pcJson = Gravando relatorio JSON para {0}
  pcHtml = Gravando relatorio HTML para {0}
  pcEmail = Enviando relatorio por email
  pcEndScriptGlobal = Executando PowerCheck EndScript.ps1
  pcEndScriptPlugin = Executando EndScript.ps1 do Plugin

  # ScriptList
  slTitle = Lista plugins
  slHeader = Lista plugins
  slComments = Lista completa dos scripts do Plugin
  
  # Time to run
  ttrTitle = Tempo de execucao
  ttrHeader = Tempo de execucao
  ttrComments = Os seguintes scripts demoraram mais de {0} segundos a executar, talvez possam ser optimizados or removidos se nao forem necessarios

  # Email
  emailBody = Ola,\n\nO relatorio {0} do PowerCheck acabou em {1} as {2}\n\nObrigado,\nThe PowerCheck Team

  # Misc
  search = Procurar...
  pluginRoot = Module root
'@