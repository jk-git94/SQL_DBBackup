<# Define Timestamp & Log filename #>
function Get-TimeStamp {
    
    return "{0:MM/dd/yy} {0:HH:mm:ss}" -f (Get-Date)
    
}

$filename = "$env:computername-SQLBCP_logs.txt"

<# Define DB and Backup Drives #>
$Data = [xml](Get-Content -path "$PSScriptRoot\config.xml" -Raw)

$MainDB = $Data.SelectSingleNode("//config//MainDB").InnerText
$RDPDB = $Data.SelectSingleNode("//config//RDPDB").InnerText
$BckDrive = $Data.SelectSingleNode("//config//BckDrive").InnerText
$SQLDB = $Data.SelectSingleNode("//config//SQLDB").InnerText
$PSScriptRoot = $BckDrive

if ($BckDrive -eq "") {
    Write-Output "$(Get-TimeStamp) Backup drive not provided. Drive location set to $($PSScriptRoot)" | Out-file "$PSScriptRoot\$filename" -append
    $BckDrive = $PSScriptRoot
}
else {
    Write-Output "$(Get-TimeStamp) Backup drive provided. Drive location set to $($PSScriptRoot)" | Out-file "$PSScriptRoot\$filename" -append
}

<# Define SMTP Details #>
$smtpUsername = $Data.SelectSingleNode("//config//MailFrom").InnerText
$smtpPasswd = $Data.SelectSingleNode("//config//MailPassword").InnerText
$smtpPassword = ConvertTo-SecureString -String $smtpPasswd -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $smtpUsername, $smtpPassword

<# Define Email Parameters #>
<# Define Secure SMTP #>
$SecureParams = @{
    From = $Data.SelectSingleNode("//config//From").InnerText
    To = $Data.SelectSingleNode("//config//To").InnerText
    Subject = $Data.SelectSingleNode("//config//Subject").InnerText
    Body = "Hello Admin,<br><br>This email update is regarding succcessful Database Backup for $($MainDB) and $($RDPDB) at $(Get-TimeStamp) on Backup drive path $BckDrive.<br><br><br><br><p style='font-size: 12px;'>This is an auto-generated e-mail from ARCON PAM. Please do not reply to this e-mail. It has been sent from an e-mail account that may not be monitored. In case of any assistance or query please contact ARCON PAM Administrator.</p>"
    SmtpServer = $Data.SelectSingleNode("//config//SmtpServer").InnerText
    Port = $Data.SelectSingleNode("//config//Port").InnerText
    UseSsl = $true
    Credential = $Credential
}
<# Define Non-Secure SMTP #>
$UnSecureParams = @{
    From = $Data.SelectSingleNode("//config//From").InnerText
    To = $Data.SelectSingleNode("//config//To").InnerText
    Subject = $Data.SelectSingleNode("//config//Subject").InnerText
    Body = "Hello Admin,<br><br>This email update is regarding succcessful Database Backup for $($MainDB) and $($RDPDB) at $(Get-TimeStamp) on Backup drive path $BckDrive.<br><br><br><br><p style='font-size: 12px;'>This is an auto-generated e-mail from ARCON PAM. Please do not reply to this e-mail. It has been sent from an e-mail account that may not be monitored. In case of any assistance or query please contact ARCON PAM Administrator.</p>"
    SmtpServer = $Data.SelectSingleNode("//config//SmtpServer").InnerText
    Port = $Data.SelectSingleNode("//config//Port").InnerText
}

<# Define SMTP Level#>
$SMTPSecurity = $Data.SelectSingleNode("//config//Security").InnerText <# Mention $SecureParams or $UnSecureParams #>

<# ARCOSDB Backup #>
Write-Output "$(Get-TimeStamp) Starting with the script" | Out-file "$PSScriptRoot\$filename" -append
Remove-Item "$PSScriptRoot\$MainDB.BAK" -ErrorAction SilentlyContinue
Write-Output "$(Get-TimeStamp) Deleting old backup file for $($MainDB)" | Out-file "$PSScriptRoot\$filename" -append
Start-Sleep -Seconds 2
Write-Output "$(Get-TimeStamp) Started with backup for $($MainDB)" | Out-file "$PSScriptRoot\$filename" -append
Backup-SqlDatabase -ServerInstance $SQLDB -Database $MainDB -BackupFile "$BckDrive\$MainDB.BAK" -CompressionOption On
Write-Output "$(Get-TimeStamp) Completed backup." | Out-file "$PSScriptRoot\$filename" -append
Write-Output "$(Get-TimeStamp) -------------------------------------------" | Out-file "$PSScriptRoot\$filename" -append

<# ARCOSRDPDB Backup #>
Write-Output "$(Get-TimeStamp) Deleting old backup file for $($RDPDB)" | Out-file "$PSScriptRoot\$filename" -append
Start-Sleep -Seconds 2
Remove-Item "$PSScriptRoot\$RDPDB.BAK" -ErrorAction SilentlyContinue
Write-Output "$(Get-TimeStamp) Started with backup for $($RDPDB)" | Out-file "$PSScriptRoot\$filename" -append
Backup-SqlDatabase -ServerInstance $SQLDB -Database $RDPDB -BackupFile "$BckDrive\$RDPDB.BAK" -CompressionOption On
Write-Output "$(Get-TimeStamp) Completed backup." | Out-file "$PSScriptRoot\$filename" -append
Write-Output "$(Get-TimeStamp) -------------------------------------------" | Out-file "$PSScriptRoot\$filename" -append

<# Send Email #>
if ($SMTPSecurity -eq "Secure") {
    $SMTPSecurity = $SecureParams
    Send-MailMessage @SMTPSecurity
}
elseif ($SMTPSecurity -eq "Unsecure") {
    $SMTPSecurity = $UnSecureParams
    Send-MailMessage @SMTPSecurity
}
else {
    Write-Output "$(Get-TimeStamp) Invalid SMTP Configuration." | Out-file "$PSScriptRoot\$filename" -append
    Write-Output "$(Get-TimeStamp) -------------------------------------------" | Out-file "$PSScriptRoot\$filename" -append
}