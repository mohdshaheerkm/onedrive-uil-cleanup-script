<#
.SYNOPSIS
    OneDrive / SharePoint UserInfoList (UIL) cleanup script

.DESCRIPTION
    Resolves access issues for users recreated with the same UPN by removing
    stale User Information List (UIL) entries from specific OneDrive sites.

.NOTES
    - Runs only on specified sharers (scoped execution)
    - Automatically grants and revokes Site Collection Admin (SCA)
    - Supports dry-run using -ReportOnly
    - Sends report via SMTP

.AUTHOR
    Mohammed Shaheer Ashraf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$AdminUPN,

    [Parameter(Mandatory=$true)]
    [string]$AffectedUserUPN,

    [Parameter(Mandatory=$true)]
    [string[]]$SharerUPNs,

    [switch]$ReportOnly
)

# ================= CONFIG =================

# SharePoint Admin URL (modify as needed)
$AdminUrl = "https://your-tenant-admin.sharepoint.com"

# Email recipients
$MailTo = @(
    "admin@yourdomain.com",
    "m365-team@yourdomain.com"
)

# SMTP settings (modify as per your environment)
$SmtpServer = "smtp.yourdomain.com"
$SmtpPort   = 25
$UseSsl     = $false

# Output location
$BasePath = "C:\Scripts\OneDrive"

# ==========================================

# Create output folder
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$WorkDir   = Join-Path $BasePath "UIL_Cleanup_$TimeStamp"
New-Item -Path $WorkDir -ItemType Directory -Force | Out-Null

$CsvLog   = Join-Path $WorkDir "Actions.csv"
$RunLog   = Join-Path $WorkDir "Run.log"
$BodyFile = Join-Path $WorkDir "EmailBody.txt"

$Results = New-Object System.Collections.Generic.List[object]

# ---------- Logging ----------
function Add-Result {
    param($Sharer,$Site,$Status,$Details)

    $obj = [pscustomobject]@{
        Time        = Get-Date
        SharerUPN   = $Sharer
        OneDriveUrl = $Site
        Status      = $Status
        Details     = $Details
    }

    $Results.Add($obj) | Out-Null
    Add-Content -Path $RunLog -Value "$(Get-Date) | $Sharer | $Site | $Status | $Details"
}

# ---------- SMTP Mail ----------
function Send-MailSMTP {
    param($Subject,$Body,$Attachments)

    $msg = New-Object System.Net.Mail.MailMessage
    $msg.From = $AdminUPN

    foreach ($r in $MailTo) {
        $msg.To.Add($r)
    }

    $msg.Subject = $Subject
    $msg.Body    = $Body

    foreach ($a in $Attachments) {
        if (Test-Path $a) {
            $msg.Attachments.Add($a) | Out-Null
        }
    }

    $smtp = New-Object System.Net.Mail.SmtpClient($SmtpServer,$SmtpPort)
    $smtp.EnableSsl = $UseSsl
    $smtp.UseDefaultCredentials = $true
    $smtp.Send($msg)
}

# ================= EXECUTION =================

Write-Host "Connecting to SharePoint Admin Center..." -ForegroundColor Cyan
Connect-SPOService -Url $AdminUrl

Write-Host "Loading OneDrive sites..." -ForegroundColor Cyan
$PersonalSites = Get-SPOSite -IncludePersonalSite $true -Limit All |
                 Where-Object { $_.Url -like "*-my.sharepoint.com/personal/*" }

# Build lookup
$ODLookup = @{}
foreach ($p in $PersonalSites) {
    if (-not $ODLookup.ContainsKey($p.Owner)) {
        $ODLookup[$p.Owner] = $p.Url
    }
}

# Process each sharer
foreach ($sharer in $SharerUPNs) {

    Write-Host "`nProcessing: $sharer" -ForegroundColor Yellow

    if (-not $ODLookup.ContainsKey($sharer)) {
        Add-Result $sharer "" "ONEDRIVE_NOT_FOUND" "No personal site found"
        continue
    }

    $SiteUrl = $ODLookup[$sharer]
    Add-Result $sharer $SiteUrl "ONEDRIVE_FOUND" "Site located"

    $SCAAdded = $false

    try {
        # Grant SCA
        if (-not $ReportOnly) {
            Set-SPOUser -Site $SiteUrl -LoginName $AdminUPN -IsSiteCollectionAdmin $true
            $SCAAdded = $true
            Add-Result $sharer $SiteUrl "SCA_GRANTED" "Temporary admin access granted"
        }

        # Check UIL
        $UserPresent = $false
        try {
            Get-SPOUser -Site $SiteUrl -LoginName $AffectedUserUPN -ErrorAction Stop | Out-Null
            $UserPresent = $true
        } catch {}

        if ($UserPresent) {
            Add-Result $sharer $SiteUrl "UIL_FOUND" "User exists in UserInfoList"

            if (-not $ReportOnly) {
                Remove-SPOUser -Site $SiteUrl -LoginName $AffectedUserUPN -Confirm:$false
                Add-Result $sharer $SiteUrl "UIL_REMOVED_SUCCESS" "Stale entry removed"
            }
        }
        else {
            Add-Result $sharer $SiteUrl "UIL_NOT_PRESENT" "No stale entry found"
        }
    }
    catch {
        Add-Result $sharer $SiteUrl "ERROR_PROCESSING" $_.Exception.Message
    }
    finally {
        # Revoke SCA
        if ($SCAAdded -and -not $ReportOnly) {
            try {
                Set-SPOUser -Site $SiteUrl -LoginName $AdminUPN -IsSiteCollectionAdmin $false
                Add-Result $sharer $SiteUrl "SCA_REVOKED" "Admin access removed"
            } catch {
                Add-Result $sharer $SiteUrl "ERROR_SCA_REVOKE" $_.Exception.Message
            }
        }
    }
}

# Save logs
$Results | Export-Csv $CsvLog -NoTypeInformation

# ---------- Email Body ----------
$body = @()
$body += "OneDrive UIL Cleanup Report"
$body += "----------------------------------------"
$body += "Admin: $AdminUPN"
$body += "User : $AffectedUserUPN"
$body += "Mode : $ReportOnly"
$body += "Path : $WorkDir"
$body += ""

foreach ($r in $Results) {
    $body += "$($r.Time) | $($r.SharerUPN) | $($r.Status)"
}

$body += ""
$body += "IMPORTANT: Re-share content after cleanup."

$FinalBody = $body -join "`r`n"
Set-Content $BodyFile $FinalBody

Send-MailSMTP `
    -Subject "OneDrive UIL Cleanup - $AffectedUserUPN" `
    -Body $FinalBody `
    -Attachments @($CsvLog)

Write-Host "`nCompleted. Output: $WorkDir" -ForegroundColor Green
