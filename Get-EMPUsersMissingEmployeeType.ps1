# =====================================================================
# SCRIPT NAME: Get-EMPUsersMissingEmployeeType.ps1
# AUTHOR: Kevin Estrada
# DATE: 2026-03-25
# DESCRIPTION:
#   This script performs a read-only audit of Active Directory to identify
#   employee accounts (Description = "EMP") that are missing employeeType.
#
#   It searches within a specified OU and exports a CSV report containing:
#       - Name
#       - OU Path (directory location)
#
#   NOTE:
#   All environment-specific values (domain, server, OU) are placeholders.
#
# REQUIREMENTS:
#   - RSAT Active Directory module installed
#   - Domain connectivity
#
# =====================================================================


# ===============================
# CONFIGURATION (UPDATE FOR YOUR ENVIRONMENT)
# ===============================
$OutputCsv  = "C:\Reports\EMP_Users_Missing_EmployeeType.csv"
$SearchBase = "OU=Users,DC=yourdomain,DC=com"
$Server     = "your-domain-controller.yourdomain.com"


# ===============================
# GET EMP USERS MISSING EMPLOYEETYPE
# ===============================
try {
    $Results = Get-ADUser `
        -Server $Server `
        -Filter * `
        -SearchBase $SearchBase `
        -Properties Description, employeeType, DistinguishedName, Name `
        -ErrorAction Stop |

        Where-Object {
            $_.Description -eq "EMP" -and
            [string]::IsNullOrWhiteSpace($_.employeeType)
        } |

        ForEach-Object {
            [PSCustomObject]@{
                Name   = $_.Name
                OUPath = ($_.DistinguishedName -replace '^CN=.*?,', '')
            }
        }
}
catch {
    Write-Host "Active Directory query failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    return
}


# ===============================
# EXPORT CSV
# ===============================
$Results |
    Sort-Object OUPath, Name |
    Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host "Report exported to: $OutputCsv" -ForegroundColor Green
