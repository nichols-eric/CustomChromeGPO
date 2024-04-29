# Iterate through each user's directory
Get-ChildItem -Path "$env:systemdrive\Users" -ErrorAction SilentlyContinue | ForEach-Object {
    # Array to hold all profile paths
    $profilePaths = @()
    
    # Add default profile path
    $defaultProfilePath = "$($_.FullName)\AppData\Local\Google\Chrome\User Data\Default\preferences"
    $profilePaths += $defaultProfilePath
    
    # Get additional profile paths
    $additionalProfilePaths = Get-ChildItem -Path "$($_.FullName)\AppData\Local\Google\Chrome\User Data\" -Directory -Filter "Profile *" -ErrorAction SilentlyContinue
    
    # Add additional profile paths to the array
    $additionalProfilePaths | ForEach-Object {
        $profilePaths += "$($_.FullName)\preferences"
    }

    # Loop through each profile path
    foreach ($path in $profilePaths) {
        # Check if preferences file exists
        if (Test-Path $path) {
            Write-Host "Working on $path"
            $prefs = Get-Content $path -Encoding utf8 | ConvertFrom-Json

            # Get the registry values under the key and their names
            $registryValues = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\newAllowFileAccess" -ErrorAction SilentlyContinue |
                              ForEach-Object { $_.PSObject.Properties } |
                              Where-Object { $_.Value -match '^\w{32}$' } |  # Assuming the values are 32-character strings
                              ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Value = $_.Value } }

            # Loop through each value in the registry
            foreach ($value in $registryValues) {
                # Check if the settings property exists and contains the registry value
                if ($prefs.extensions.settings -and $prefs.extensions.settings.$($value.Value) -ne $null) {
                    # Output whether the settings value exists
                    Write-Host "Extension settings for $($value.Value) exists for user $($_.Name) in profile $($path.Split('\')[-2])"

                    # Add newAllowFileAccess property only if settings already exist
                    if (-not $prefs.extensions.settings.$($value.Value).newAllowFileAccess) {
                        $prefs.extensions.settings.$($value.Value) | Add-Member -MemberType NoteProperty -Name newAllowFileAccess -Value $true -Force
                        Write-Host "Set 'newAllowFileAccess' to true for extension $($value.Value) for user $($_.Name) in profile $($path.Split('\')[-2])"
                    } else {
                        Write-Host "newAllowFileAccess is already set for extension $($value.Value) for user $($_.Name) in profile $($path.Split('\')[-2])"
                    }
                }
            }

            # Save the updated JSON back to the preferences file
            $prefs | ConvertTo-Json -Depth 100 | Set-Content $path -Encoding utf8
        }
    }
}
