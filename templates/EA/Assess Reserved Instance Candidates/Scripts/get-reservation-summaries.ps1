
# Do not change the parameters unless you know what you are doing (=it's not needed if you are following the Assessment guide)
param (
   [Parameter(Mandatory=$true)]
   [string]$BillingAccountId,
   [Parameter(Mandatory=$true)]
   $AuthenticationHeaders,

   # The end date should be the same date as the when the UsageDetails for the last where downloaded
   [datetime]$endDate = [datetime]::Today,
   [datetime]$startDate = $endDate.AddMonths(-3)
)



# RESERVATION SUMMARIES (to get utilization information)

$currentDate = $startDate
$results = $null

while ($currentDate -le $endDate) {
   $monthStart = [datetime]::ParseExact($currentDate.ToString("yyyy-MM-01"), "yyyy-MM-dd", $null)
   $monthEnd = $monthStart.AddMonths(1).AddDays(-1)
    
   if ($monthEnd -gt $endDate) {
      $monthEnd = $endDate
   }

   Write-Output "Processing Reservation Summaries from $($monthStart.ToString("yyyy-MM-dd")) to $($monthEnd.ToString("yyyy-MM-dd"))..."

   # Your code to process each month goes here
   $apiUrl = "https://management.azure.com/providers/Microsoft.Billing/billingAccounts/$($BillingAccountId)/providers/Microsoft.Consumption/reservationsummaries?api-version=2019-10-01&grain=daily&`$filter=properties/UsageDate+ge+$($monthStart.ToString("yyyy-MM-dd"))+AND+properties/UsageDate+le+$($monthEnd.ToString("yyyy-MM-dd"))"
   if($null -eq $results) {
      $results = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $AuthenticationHeaders
   } else {
      $results.value += (Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $AuthenticationHeaders).value
   }

   $results.value.Count

   $currentDate = $currentDate.AddMonths(1)
}

# Keep only the reservation summaries for VMs
$reservationSummaries = $results.value | Where-Object { $_.properties.kind -eq "Reservation" }

$reservationSummariesJson = $reservationSummaries | ConvertTo-Json -AsArray -Depth 4
$reservationSummariesJson | Out-File -FilePath "./Downloads/reservation-summaries.json"
