[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [ValidateSet('Computer','User','Both')][string]$Target='Both',
 [switch]$ForceUpdate,
 [switch]$ResetLocalPolicyCache,
 [switch]$RestartNetlogon,
 [switch]$RepairWmiRepository,
 [switch]$DryRun,[switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'GroupPolicyRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.txt';$after=Join-Path $run 'after.txt';$backup=Join-Path $run 'backup';New-Item -ItemType Directory $backup -Force|Out-Null
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State($path){$lines=@("Collected: $(Get-Date -Format o)");$lines+=(& gpresult.exe /r /scope computer 2>&1|Out-String);$lines+=(& gpresult.exe /r /scope user 2>&1|Out-String);$lines+=(Get-WinEvent -LogName 'Microsoft-Windows-GroupPolicy/Operational' -MaxEvents 100 -ErrorAction SilentlyContinue|Select-Object TimeCreated,Id,LevelDisplayName,Message|Format-List|Out-String);$lines|Set-Content $path -Encoding UTF8}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
if(-not($ForceUpdate -or $ResetLocalPolicyCache -or $RestartNetlogon -or $RepairWmiRepository)){Write-Error 'Choose at least one repair action.';exit 2}
if(-not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell.';exit 4}
State $before
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected Group Policy repairs? Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
if($RestartNetlogon){Act 'Restarting Netlogon service' {Restart-Service Netlogon -Force -ErrorAction Stop}}
if($RepairWmiRepository){Act 'Verifying WMI repository' {& winmgmt.exe /verifyrepository|Out-File (Join-Path $run 'wmi-verify.txt');if($LASTEXITCODE -ne 0){throw "verifyrepository exited $LASTEXITCODE"}};Act 'Salvaging WMI repository' {& winmgmt.exe /salvagerepository|Out-File (Join-Path $run 'wmi-salvage.txt');if($LASTEXITCODE -ne 0){throw "salvagerepository exited $LASTEXITCODE"}}}
if($ResetLocalPolicyCache){foreach($folder in @("$env:SystemRoot\System32\GroupPolicy","$env:SystemRoot\System32\GroupPolicyUsers")){if(Test-Path $folder){$name=Split-Path $folder -Leaf;Act "Backing up $name" {Copy-Item $folder (Join-Path $backup $name) -Recurse -Force};Act "Resetting local policy cache $name" {Rename-Item $folder "$folder.bak.$(Get-Date -Format yyyyMMddHHmmss)"}}}}
if($ForceUpdate -or $ResetLocalPolicyCache){$args=if($Target -eq 'Both'){@('/force')}else{@("/target:$($Target.ToLowerInvariant())",'/force')};Act "Refreshing Group Policy for $Target" {& gpupdate.exe @args|Out-File (Join-Path $run 'gpupdate.txt');if($LASTEXITCODE -ne 0){throw "gpupdate exited $LASTEXITCODE"}}}
Start-Sleep 3;State $after
if($script:Failures){Log "Completed with $script:Failures failure(s).";exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
