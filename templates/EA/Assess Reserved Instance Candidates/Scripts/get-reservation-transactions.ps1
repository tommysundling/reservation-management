
# Do not change the parameters unless you know what you are doing (=it's not needed if you are following the Assessment guide)
param (
   [Parameter(Mandatory=$true)]
   [string]$BillingAccountId,
   [Parameter(Mandatory=$true)]
   $AuthenticationHeaders,

   # The end date should be the same date as the when the UsageDetails for the last where downloaded
   [datetime]$endDate = [datetime]::Today,
   # We go back 5 years and 1 month to ensure we catch the rare case where a 5-year reservation was purchased as a one-time purchase (could be reduced to 2 months if you are sure that all reservations are on monthly payments)
   [datetime]$startDate = $endDate.AddYears(-5).AddMonths(-1)
)



# RESERVATION TRANSACTIONS (to get region information)

$currentDate = $startDate
$results = $null

while ($currentDate -le $endDate) {
   $monthStart = [datetime]::ParseExact($currentDate.ToString("yyyy-MM-01"), "yyyy-MM-dd", $null)
   $monthEnd = $monthStart.AddMonths(1).AddDays(-1)
    
   if ($monthEnd -gt $endDate) {
      $monthEnd = $endDate
   }

   Write-Output "Processing Reservation Transactions from $($monthStart.ToString("yyyy-MM-dd")) to $($monthEnd.ToString("yyyy-MM-dd"))..."

   # Your code to process each month goes here
   $apiUrl = "https://management.azure.com/providers/Microsoft.Billing/billingAccounts/$($BillingAccountId)/providers/Microsoft.Consumption/reservationTransactions?api-version=2024-08-01&grain=daily&`$filter=properties/EventDate+ge+$($monthStart.ToString("yyyy-MM-dd"))+AND+properties/EventDate+le+$($monthEnd.ToString("yyyy-MM-dd"))"
   if($null -eq $results) {
      $results = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $AuthenticationHeaders
   } else {
      $results.value += (Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $AuthenticationHeaders).value
   }

   $results.value.Count

   $currentDate = $currentDate.AddMonths(1)
}

$reservationTransactionsJson = $results.value | ConvertTo-Json -AsArray -Depth 4
$reservationTransactionsJson | Out-File -FilePath "./Downloads/reservation-transactions.json"