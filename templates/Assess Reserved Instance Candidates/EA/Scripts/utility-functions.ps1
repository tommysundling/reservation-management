
#/ <summary>
#/ Gets the Azure headers for authentication and content type. 
#/ This function retrieves an access token for the specified resource URL and constructs the necessary headers for making authenticated requests to Azure services. 
#/ The token is checked to ensure it is in plain text format, and if it is a secure string, it is converted to plain text before being included in the headers. 
#/ The resulting headers include the Authorization header with the Bearer token and the Content-Type header set to application/json.
#/ </summary>
Function Get-AzureHeaders([String]$AuthenticationAudience = "https://management.azure.com/") {
    #  Retrieve an access token for the specified audience
    $token = (Get-AzAccessToken -ResourceUrl $AuthenticationAudience).Token
 
    # Check if the token is in plain text and if it's not then convert it
    # This is required by the billing api
 
    if ($token -is [System.Security.SecureString]) {
        $token = [System.Net.NetworkCredential]::new("", $token).Password
    }
 
    # Define the headers
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json'
    }
 
    # Return the headers
    return $headers
}


#/ <summary>
#/ Ensures each [name, version] module in $modules is installed (for the current user) and imported at the required version.
#/ Returns $true on success, or $false if any step throws.
#/ </summary>
Function Confirm-PowerShellModules([Array]$modules) {
    # Verify if modules are installed locally and if not install them for the current user
    $loadModules = $false
    try {
        foreach ($module in $modules)
        {
            if (-not (Get-Module -ListAvailable -Name $module[0] | Where-Object {$_.Version -eq [System.Version]$module[1]}))
            {
                Write-Output "Installing module $($module[0]) version $($module[1])"
                Install-Module -Name $module[0] -RequiredVersion $module[1] -Force -Scope CurrentUser
            }
            Write-Output "Loading module $($module[0]) version $($module[1])"
            Import-Module $module[0] -RequiredVersion $module[1]
        }
        $loadModules = $true
    }
    catch {
        $loadModules = $false
    }
 
    Return $loadModules
}


#/ <summary>
#/ Ensures the specified folder exists, creating it if missing. Returns $true if the folder exists (or was created), $false on error.
#/ </summary>
Function Confirm-Directory([String]$folder)
{
    $pathExists = $false
    try {
        if(-not (Test-Path $folder -PathType Container))
        {
            New-Item -Path $folder -ItemType Directory -Force
            $pathExists = $true
        }
        else
        {
            $pathExists = $true
        }
    }
    catch {
        Write-Output "Failed to check/create folder.  Error: $($_.Exception.Message)"
    }
    return $pathExists
}


#/ <summary>
#/ Validates that each named variable in the caller's scope has a non-null / non-whitespace value.
#/ Accepts an array of parameter names (strings) and an optional source description used in error messages.
#/ Writes an error for each missing value and returns $true if all are present, $false otherwise.
#/ </summary>
Function Confirm-RequiredParameters([String[]]$parameterNames, [String]$source = "the parameters file")
{
    $allValid = $true
    foreach ($name in $parameterNames)
    {
        $value = (Get-Variable -Name $name -Scope 1 -ErrorAction SilentlyContinue).Value
        if ([string]::IsNullOrWhiteSpace($value))
        {
            Write-Error "$name was not set by $source. Please populate it and re-run."
            $allValid = $false
        }
    }
    return $allValid
}