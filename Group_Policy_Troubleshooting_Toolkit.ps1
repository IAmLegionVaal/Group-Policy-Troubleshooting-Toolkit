#requires -Version 5.1
<#
.SYNOPSIS
    Group Policy Troubleshooting Toolkit.
.DESCRIPTION
    Read-only GPResult and Group Policy event evidence collector.
#>
[CmdletBinding()]
param([string]$OutputPath,[int]$Hours=48)
$RunStamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Group_Policy_Reports'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
$gpHtml=Join-Path $OutputPath "gpresult_$RunStamp.html";$gpTxt=Join-Path $OutputPath "gpresult_$RunStamp.txt"
try{gpresult.exe /h $gpHtml /f|Out-Null}catch{}
try{gpresult.exe /r|Out-File $gpTxt -Encoding UTF8}catch{}
$start=(Get-Date).AddHours(-1*$Hours)
$events=Get-WinEvent -FilterHashtable @{LogName='System';StartTime=$start;Level=1,2,3} -ErrorAction SilentlyContinue|Where-Object{$_.ProviderName -match 'GroupPolicy|User Profile|Winlogon'}|Select-Object TimeCreated,Id,ProviderName,LevelDisplayName,Message
$events|Export-Csv (Join-Path $OutputPath "group_policy_events_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$context=[PSCustomObject]@{Computer=$env:COMPUTERNAME;User="$env:USERDOMAIN\$env:USERNAME";Generated=Get-Date;GPHtml=$gpHtml;GPText=$gpTxt;EventCount=@($events).Count}
$context|ConvertTo-Json -Depth 5|Set-Content (Join-Path $OutputPath "gp_context_$RunStamp.json") -Encoding UTF8
$html="<h1>Group Policy Troubleshooting - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Context</h2>$(@($context)|ConvertTo-Html -Fragment)<h2>Recent GP Related Events</h2>$($events|Select-Object -First 100|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Group Policy Troubleshooting'|Set-Content (Join-Path $OutputPath "group_policy_report_$RunStamp.html") -Encoding UTF8
$context|Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "`"$OutputPath`"" -ErrorAction SilentlyContinue
