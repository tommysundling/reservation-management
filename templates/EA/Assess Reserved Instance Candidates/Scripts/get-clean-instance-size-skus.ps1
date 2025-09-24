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
   # Filter out a duplicated row (will need to be updated if the source file changes)
   $filteredData = $filteredData | Select-Object -Skip 1 | Where-Object { $_.Sku -ne "Esv3_Type1" }

   "Total rows after cleanup: " + $filteredData.Count

   # Write the filtered data back to the file
   $filteredData | Export-Csv -Path "Downloads\isfratioblob.csv" -NoTypeInformation
