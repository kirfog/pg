New-Item -Path C:\pgbackup\$((Get-Date).ToString('yyyyMMdd')).log

foreach ($s in psql -U postgres --list | select -Skip 3 | Select -SkipLast 7 ) {
$database = $s.split(" ")[1]
$database >> C:\pgbackup\$((Get-Date).ToString('yyyyMMdd')).log
Measure-Command -Expression { pg_dump -U postgres -F c -b -f C:\pgbackup\$database$((Get-Date).ToString('yyyyMMdd')).bak $database} >> C:\pgbackup\$((Get-Date).ToString('yyyyMMdd')).log
}

Send-MailMessage -To admin@domain.com -Subject PGBACKUP -Attachments C:\pgbackup\$((Get-Date).ToString('yyyyMMdd')).log -from admin@domain.com -SmtpServer smtp.domain.com

if (Test-Path C:\pgbackup\$database$((Get-Date).ToString('yyyyMMdd')).bak) {
    Get-ChildItem -Path  C:\pgbackup\ -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt (Get-Date).AddDays(-10) } | Remove-Item -Force
}