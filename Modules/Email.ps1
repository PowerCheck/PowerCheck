param (
  [Parameter()] [String]$HtmlBody,
  [Parameter()] [String]$TextBody,
  [Parameter()] [String]$File,
  [Parameter()] [String]$SMTPSRV,
  [Parameter()] [Boolean]$EmailSSL,
  [Parameter()] [String]$EmailFrom,
  [Parameter()] [String]$EmailTo,
  [Parameter()] [String]$EmailCc,
  [Parameter()] [String]$EmailSubject,
  [Parameter()] [String]$SmtpUsername,
  [Parameter()] [ValidateSet("html", "text")][String]$EmailBodyFormat,
  [Parameter()] [Boolean]$SendAttachment,
  [Parameter()] [SecureString]$SmtpPassword,
  [Parameter()] [System.Net.Mail.Attachment[]]$Attachments
)

if ( -not ($emptyReport -and !$EmailReportEvenIfEmpty) ) {
  $email = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo)

  if ($EmailCc -ne "") {
    $email.CC.Add($EmailCc)
  }
  $email.Subject = $EmailSubject

  $email.IsBodyHtml = $false

  if ($EmailBodyFormat -eq "html") {

    $email.IsBodyHtml = $true

    if ($EmailBodyTextSource -ne "none") {
      $alternateMailViewPlain = [System.Net.Mail.AlternateView]::CreateAlternateViewFromString($TextBody, 'text/plain')
      $alternateMailViewPlain.TransferEncoding = [System.Net.Mime.TransferEncoding]::QuotedPrintable
      $email.AlternateViews.Add($alternateMailViewPlain)
    }

    $alternateMailViewHtml = [System.Net.Mail.AlternateView]::CreateAlternateViewFromString($HtmlBody, $null, "text/html")
    $alternateMailViewHtml.TransferEncoding = [System.Net.Mime.TransferEncoding]::QuotedPrintable
    if ($Attachments) {
        foreach ($attachment in $Attachments) {
          $linkedResource = New-Object System.Net.Mail.LinkedResource($attachment.ContentStream, $attachment.ContentType)
          $linkedResource.ContentType.MediaType = "image/png"
          $linkedResource.ContentType.Name = $attachment.Name
          $linkedResource.TransferEncoding = $attachment.TransferEncoding
          $linkedResource.ContentLink = ("cid:{0}" -f $attachment.ContentId)
          $alternateMailViewHtml.LinkedResources.Add($linkedResource)
        }
    }
    $email.AlternateViews.Add($alternateMailViewHtml)

  } else { 
    $email.Body = $TextBody
  }

  if ($SendAttachment -and $File) {
    $attachment = New-Object System.Net.Mail.Attachment($File)
    $email.Attachments.Add($attachment)
  }

  $smtpClient = New-Object System.Net.Mail.SmtpClient
  ($smtpHost, $smtpPort) = $SMTPSRV.Split(":")
  $smtpClient.Host = $smtpHost
  if ($smtpPort) {
    $smtpClient.Port = $smtpPort
  }
  if ($EmailSSL) {
    $smtpClient.EnableSsl = $true
  }
  $smtpClient.UseDefaultCredentials = $false
  # $smtpClient.Credentials = New-Object System.Net.NetworkCredential("$SmtpUsername", "$SmtpPassword")
  $smtpClient.Send($email)

  if ($SendAttachment) {
    $attachment.Dispose()
  }
  $email.Dispose()

}