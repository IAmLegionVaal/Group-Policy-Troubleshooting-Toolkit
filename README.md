# Group Policy Troubleshooting Toolkit

A PowerShell toolkit for Group Policy troubleshooting, escalation evidence and selected guarded repairs.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Group_Policy_Troubleshooting_Toolkit.ps1
```

## Repair script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Group_Policy_Repair_Toolkit.ps1 -ForceUpdate -DryRun
```

Examples:

```powershell
.\Group_Policy_Repair_Toolkit.ps1 -ForceUpdate -Target Both
.\Group_Policy_Repair_Toolkit.ps1 -RestartNetlogon -ForceUpdate
.\Group_Policy_Repair_Toolkit.ps1 -RepairWmiRepository -ForceUpdate
.\Group_Policy_Repair_Toolkit.ps1 -ResetLocalPolicyCache -ForceUpdate
```

## What the repair does

- Restarts Netlogon when policy retrieval depends on domain connectivity.
- Verifies and salvages the WMI repository using supported Windows operations.
- Backs up and resets local Group Policy cache folders.
- Refreshes Computer, User or both policy scopes with `gpupdate`.
- Captures `gpresult` and Group Policy event evidence before and after repair.
- Supports `-DryRun`, confirmation prompts, logs and clear exit codes.

## Safety

Resetting local policy cache can temporarily remove locally cached policy until refresh completes. The tool does not edit domain GPOs, security filters, links, permissions or Active Directory objects.

## Author

Dewald Pretorius — L2 IT Support Engineer
