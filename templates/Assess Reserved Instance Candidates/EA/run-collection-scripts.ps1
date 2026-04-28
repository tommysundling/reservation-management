# This script requires PowerShell 7.5 or higher. Please install the latest version of PowerShell from https://aka.ms/powershell
#Requires -Version 7.5 
# Load shared utility functions
. "$PSScriptRoot\Scripts\utility-functions.ps1"


### Variables ##########################################################
$modulesLoaded = Confirm-PowerShellModules @(@("Az.Accounts","5.2.0"),@("Az.Billing","2.2.0"))

# Load parameters (BillingAccountId, TenantId, BillingProfileId, SkipAzureLogin) from the parameters file
. "$PSScriptRoot\run-collection-scripts.parameters.ps1"
# Verify required parameters were supplied by the parameters file
$parametersValid = Confirm-RequiredParameters -parameterNames @('BillingAccountId','BillingProfileId','TenantId') -source "'$PSScriptRoot\run-collection-scripts.parameters.ps1'"

 
### Main Script #########################################################
if (($modulesLoaded -and $parametersValid) -eq $true)
{
    if (-not $SkipAzureLogin)
    {
        #Connect to Azure by prompting interactive user
        [void](Connect-AzAccount -TenantId $TenantId -Verbose:$false -WarningAction SilentlyContinue) | Out-Null
    }
 
    Write-Output "Logged On User:`t`t$((Get-AzContext).Account.Id)"
    Write-Output "BillingAccount Id:`t$BillingAccountId"
    Write-Output "BillingProfile Id:`t$BillingProfileId"
    Write-Output "Tenant Id:`t`t$TenantId"
    Write-Output ""
    Write-Output "Execution will continue in 5 seconds.  Press Ctrl + C to cancel."
    Start-Sleep -Seconds 5
 
    #Check/Create Folder structure
    $downloadsFolder = "$($PSScriptRoot)\Downloads"

    if ((Confirm-Directory $downloadsFolder) -eq $true)
    {
        $headers = Get-AzureHeaders

        # Get the Instance size SKUs and filter out the ones that are not relevant for VM reservations
        . .\Scripts\get-clean-instance-size-skus.ps1

        # Get the reservation summaries with utilization information
        . .\Scripts\get-reservation-summaries.ps1 -BillingAccountId $BillingAccountId -BillingProfileId $BillingProfileId -AuthenticationHeaders $headers

        # Get the reservation transactions with region information for the reservations
        . .\Scripts\get-reservation-transactions.ps1 -BillingAccountId $BillingAccountId -BillingProfileId $BillingProfileId -AuthenticationHeaders $headers
    }
}