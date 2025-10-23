# This script is the entry point for the collection of reservation data

# Load the parameters from the parameters file (not provided in the repository for security reasons, simply contains the parameter values)
# . "run-collection-scripts.parameters.ps1"
# Connect-AzAccount -UseDeviceAuthentication -Tenant $TenantId



param (
    [Parameter(Mandatory=$true)]
    [string]$BillingAccountId, # Example = "12345678",
    
    [Parameter(Mandatory=$true)]
    [string]$TenantId, # Example = "00000000-0000-0000-0000-000000000000",

    [bool]$SkipAzureLogin = $false
)

# Login to Azure if the -SkipAzureLogin parameter is not set
if ($SkipAzureLogin -eq $false) {
    Connect-AzAccount -TenantId $TenantId -UseDeviceAuthentication
}


function Get-AzureHeaders {
   # Get the access token
   $token = (Get-AzAccessToken).Token

   # Define the headers
   $headers = @{
      'Authorization' = "Bearer $token"
      'Content-Type' = 'application/json'
   }

   # Return the headers
   return $headers
}
$headers = Get-AzureHeaders


# Get the Instance size SKUs and filter out the ones that are not relevant for VM reservations
. .\Scripts\get-clean-instance-size-skus.ps1
# # Get the reservation summaries with utilization information
. .\Scripts\get-reservation-summaries-mca.ps1 -BillingAccountId $BillingAccountId -BillingProfileId $BillingProfileId -AuthenticationHeaders $headers
# # Get the reservation transactions with region information for the reservations
. .\Scripts\get-reservation-transactions-mca.ps1 -BillingAccountId $BillingAccountId -BillingProfileId $BillingProfileId -AuthenticationHeaders $headers
