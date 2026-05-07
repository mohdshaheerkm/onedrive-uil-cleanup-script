**OneDrive UIL Cleanup Script**

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
![Microsoft 365](https://img.shields.io/badge/Microsoft%20365-M365-green)
![License](https://img.shields.io/badge/License-MIT-yellow)



**Overview**
This repository contains a PowerShell script to resolve OneDrive and SharePoint access issues caused by User Information List (UIL) mismatch.
This issue occurs when a user is deleted and later recreated with the same User Principal Name (UPN). Even though permissions appear correct, the user may still receive "Access Denied" errors.

**Problem**
When a user is recreated:
Azure AD assigns a new Object ID and SharePoint still retains the old identity in the User Information List (UIL)
As a result: Files appear shared User cannot access them.

**Solution**
This script removes stale UIL entries from specific OneDrive sites for the provided sharer users.
The approach is:
 - Identify OneDrive sites of the sharers
 - Check if affected user exists in UIL
 - Remove the stale entry if found
 - Maintain logs and send email report

**Before / After**

Before:
User has access but gets "Access Denied"

After:
User access restored after UIL cleanup and re-sharing


**Features**
 - Scoped execution limited to selected sharers
 - Safe for enterprise environments
 - Automatic Site Collection Admin grant and revoke
 - SMTP based email reporting without Outlook dependency
 - Detailed logging with CSV and log files
 - Dry run supported using the ReportOnly parameter

**How It Works**
For each sharer the script performs the following:
 - Locate the OneDrive personal site
 - Grant temporary admin access
 - Check UserInfoList (UIL)
 - Remove stale user entry if found
 - Revoke admin access
 - Log results and send email

**Usage**
Example command
.\OneDrive-Profile-UIL-Cleanup.ps1
-AdminUPN admin@tenant.onmicrosoft.com
-AffectedUserUPN user@domain.com
-SharerUPNs user1@domain.com,user2@domain.com

Dry run recommended before execution
.\OneDrive-Profile-UIL-Cleanup.ps1
-AdminUPN admin@tenant.onmicrosoft.com
-AffectedUserUPN user@domain.com
-SharerUPNs user1@domain.com,user2@domain.com
-ReportOnly

**Output**
Each run creates a folder in the following path:
E:\Scripts\OneDrive\UIL_Cleanup_
This folder contains:
 - Actions.csv detailed audit log
 - Run.log execution trace
 - Email report sent via SMTP

**Email Reporting**
The script sends a summary email including:
 - Status per sharer
 - Success and failure states
 - Execution details

**Status Codes**
The script outputs the following statuses:
ONEDRIVE_FOUND
SCA_GRANTED
UIL_FOUND
UIL_REMOVED_SUCCESS
UIL_NOT_PRESENT
SCA_REVOKED
ERROR

**Important Notes**
The script does not re share files automatically
After cleanup content must be shared again manually
Always run using ReportOnly before production execution

**Requirements**
SharePoint Online Management Shell
Admin permissions
SMTP relay access

**Use Cases**
Re onboarded user access issues
OneDrive sharing problems
SharePoint User ID mismatch

**Author**
Mohammed Shaheer Ashraf
IT Consultant Microsoft 365 Azure Hybrid Infrastructure

**Disclaimer**
Test the script in a controlled environment before using in production


## Tags

powerShell  
microsoft365  
sharepoint  
onedrive  
automation
