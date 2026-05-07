🚀 OneDrive UIL Cleanup Script
📌 Overview
This repository contains a PowerShell script designed to resolve OneDrive / SharePoint access issues caused by UserInfoList (UIL) mismatch.
This issue commonly occurs when a user is:

Offboarded (account deleted), and
Re-onboarded with the same UPN

Even though the user appears to have access, they encounter Access Denied due to internal identity mismatch in SharePoint.

⚠️ Problem Explanation
When a user is recreated:

Azure AD assigns a new Object ID
SharePoint still retains the old ID in the UserInfoList (UIL)

Result:

Files appear shared ✅
User cannot open them ❌


✅ Solution Approach
This script:

Identifies OneDrive sites of specific users (sharers)
Removes the stale UIL entry for the affected user
Keeps execution scoped and safe
Maintains audit trail and reporting


⚙️ Features
✔ Scoped execution (specific sharers only)
✔ Safe for enterprise use
✔ Automatic Site Collection Admin (SCA) handling
✔ SMTP email reporting (no Outlook dependency)
✔ Detailed logging (CSV + logs)
✔ Dry-run support using -ReportOnly

🖥️ How It Works
For each sharer:

Locate OneDrive personal site
Grant temporary admin access
Check if affected user exists in UIL
Remove stale entry if found
Revoke admin access
Log results and send email report


▶️ Usage
Example command:
.\OneDrive-Profile-UIL-Cleanup.ps1
-AdminUPN "admin@tenant.onmicrosoft.com"
-AffectedUserUPN "user@domain.com"
-SharerUPNs "user1@domain.com","user2@domain.com"

Dry run (recommended first):
.\OneDrive-Profile-UIL-Cleanup.ps1
-AdminUPN "admin@tenant.onmicrosoft.com"
-AffectedUserUPN "user@domain.com"
-SharerUPNs "user1@domain.com","user2@domain.com"
-ReportOnly

📊 Output
Each run creates a folder:
E:\Scripts\OneDrive\UIL_Cleanup_
Containing:

Actions.csv → detailed status report
Run.log → execution trace

Email report is sent via SMTP with full summary.

📧 Email Reporting
The script sends an email containing:

Execution summary
Status per sharer
Success / failure indicators


🔐 Security Considerations

No tenant-wide operations
Executes only on provided sharers
Does not automatically reassign permissions


⚠️ Important Note
After cleanup:
➡ Files must be re-shared manually
This is by design due to Microsoft security controls.

🧪 Status Codes

ONEDRIVE_FOUND
SCA_GRANTED
UIL_FOUND
UIL_REMOVED_SUCCESS
UIL_NOT_PRESENT
SCA_REVOKED
ERROR_*


🧩 Use Cases

Re-onboarded user access issues
OneDrive sharing problems
SharePoint User ID mismatch scenarios


📌 Requirements

SharePoint Online Management Shell
Admin permissions
SMTP relay access


👤 Author
Mohammed Shaheer Ashraf
IT Consultant – Microsoft 365 / Azure / Hybrid Infrastructure

⚠️ Disclaimer
This script should be tested in a controlled environment before production use.
