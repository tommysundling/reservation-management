# Description: This script downloads the CSV file with the SKU data for InstanceFlexibilitySizes and filters out the SKUs that are not relevant for VM reservations.

# Parameters

   # Set the destination path for the CSV file
   param (
      [string]$destinationPath = "Downloads\isfratioblob.csv"
   )


# SCRIPT

   # Download the CSV file with the SKU data for InstanceFlexibilitySizes. This file is used to filter out the SKUs that are not relevant for VM reservations.
   $url = "https://aka.ms/isf" # This URL will always point to the latest version of the file, download and review if it's the first time you're running this script
   Invoke-WebRequest -Uri $url -OutFile $destinationPath
   # Output the destination path
   Write-Output "File downloaded to $destinationPath"


   # Import the CSV file
   $data = Import-Csv -Path "Downloads\isfratioblob.csv"


   "Total rows before cleanup: " + $data.Count

   # We make a choice to filter out ISOLATED SKUs to avoid duplicates, note that these could potentially be reserved if they are of significant numbers
   $filteredData = $data | Where-Object { $_ -notlike "*Isolated*" }
   # Filter out rows containing Skus we're not interested in for VM reservations
   $filteredData = $filteredData | Where-Object { $_ -notlike "*Classic Auxiliary Logs Analysis*" }
   $filteredData = $filteredData | Where-Object { $_ -notlike "*Provisioned Throughput - Managed*" }
   $filteredData = $filteredData | Where-Object { $_ -notlike "*OpenAI_Provisioned_Throughput*" }
   $filteredData = $filteredData | Where-Object { $_ -notlike "*Per node Std*" }
   $filteredData = $filteredData | Where-Object { $_ -notlike "*AutofitGroup-AtActualPrice*" }
   $filteredData = $filteredData | Where-Object { $_ -notlike "*_Managed*" }
   $filteredData = $filteredData | Where-Object { $_ -notlike "*Overage*" }
   $filteredData = $filteredData | Where-Object { $_ -notlike "*vCPU*" }
   
   
   function Remove-DuplicateRows {
      param (
         [Parameter(Mandatory)]
         [array]$InputData,
         [string]$SkuPattern
      )
      # Find all rows where the Sku matches the given pattern (e.g., "Esv3_Type1")
      $patternRows = $InputData | Where-Object { $_ -like "*$SkuPattern*" }
      if ($patternRows.Count -le 1) {
         Write-Host "No duplicates found for pattern $SkuPattern."
         # If there are no duplicates, return the input data as is
         return $InputData
      }
      Write-Host "Found duplicates for pattern $SkuPattern, total rows: " + $patternRows.Count

      # Select only the first matching row to keep
      $singlePattern = $patternRows | Select-Object -First 1
      # Remove all rows matching the pattern from the input data
      $filtered = $InputData | Where-Object { $_ -notlike "*$SkuPattern*" }
      # Add back the single matching row so only one remains
      $result = $filtered + $singlePattern
      Write-Host "Removed duplicates for pattern $SkuPattern, remaining rows: " + $result.Count
      return $result
   }

   # Filter out duplicated rows (data quality issue in the source file)
   Write-Host "Removing duplicate rows..."
   $filteredData = Remove-DuplicateRows -InputData $filteredData -SkuPattern "Esv3_Type1"
   $filteredData = Remove-DuplicateRows -InputData $filteredData -SkuPattern "Standard_B8ms"
   $filteredData = Remove-DuplicateRows -InputData $filteredData -SkuPattern "Standard_E104id_v5"
   $filteredData = Remove-DuplicateRows -InputData $filteredData -SkuPattern "Standard_E104i_v5"
   $filteredData = Remove-DuplicateRows -InputData $filteredData -SkuPattern "Standard_E96ads_v6"
   Write-Host "Duplicate row removal complete.`n"

   "Total rows after cleanup: " + $filteredData.Count

   # Write the filtered data back to the file
   $filteredData | Export-Csv -Path "Downloads\isfratioblob.csv" -NoTypeInformation
