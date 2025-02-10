# Set API Key in PowerShell secret vault for use in API Requests
function Set-SyncroAPIKey {
    param(
        [Parameter(Mandatory)] [string] $subdomain
    )
    
    $vault_name = "SyncroMSP-API"
    $vault = Get-SecretVault -name $vault_name -ErrorAction SilentlyContinue
    
    if ($null -eq $vault) {
        Register-SecretVault -name $vault_name -Module "Microsoft.PowerShell.SecretStore"
    }

    try {
        set-secret -name $subdomain -Vault $vault_name
    }
    catch {
        write-error "Failed to set Syncro API Key!"
    }
    
    
}

# Return the API Key from the secret store
function Get-SyncroAPIKey {
    param(
        [Parameter(Mandatory)] [string] $subdomain,
        [switch]$AsPlainText
    )
    if ($AsPlainText) {
        Get-Secret -name $subdomain -Vault SyncroMSP-API -AsPlainText
    }
    else {
        Get-Secret -name $subdomain -Vault SyncroMSP-API
    }
    
}

# API End Points

## Appointment

function Get-SyncroAppointments {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByFilters')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string] $subdomain,

        [Parameter(ParameterSetName = 'ByFilters')]
        [string] $date_from,

        [Parameter(ParameterSetName = 'ByFilters')]
        [string] $date_to,

        [Parameter(ParameterSetName = 'ByFilters')]
        [bool] $mine,

        [Parameter(ParameterSetName = 'ByFilters')]
        [int] $page,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [long] $id
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/appointments"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key] #.ToString()
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method

    # Add body to http request if the format function includes it
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body $request.body -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    # response object singular or plural
    if ($response.($end_point.trimStart('/'))) {
        return $response.($end_point.trimStart('/'))
    }
    elseif ($response.($end_point.trimStart('/').trimEnd('s'))) {
        return $response.($end_point.trimStart('/').trimEnd('s'))
    }
}

# WIKI 
function Add-SyncroWikiPage {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        
        [string] $name,
        [string] $slug,
        [Parameter(Mandatory = $true)] [string] $body,

        [int] $customer_id,
        [int] $asset_id,
        
        [string] $visibilty    
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/wiki_pages"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key] #.ToString()
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    
    #write-output ($request.request_url)
    #write-output ($request.body | ConvertTo-Json -Depth 10)
    
    # Add body to http request if the format function includes it
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body ($request.body | convertTo-Json) -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText } -ContentType "application/json"
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    # response object singular or plural
    if ($response.($end_point.trimStart('/'))) {
        return $response.($end_point.trimStart('/'))
    }
    elseif ($response.($end_point.trimStart('/').trimEnd('s'))) {
        return $response.($end_point.trimStart('/').trimEnd('s'))
    }
}






function Format-SyncroRequestUrl {
    param (
        [Parameter(Mandatory)] [string] $base_url,
        [Parameter(Mandatory)] [string] $endpoint,
        [Parameter(Mandatory)] [hashtable] $parameters,
        [Parameter(Mandatory)] [ValidateSet("GET","PUT","POST","DELETE")] [string] $method
    )   

    $key_index = 0
    $request_url = $base_url + $endpoint
    
    # Put and Post requests will need other paramenters defined in the body
    if ($method -eq "PUT" -or $method -eq "POST") {
        
        $body = @{}
        foreach ($key in $parameters.keys) {
            $parameter = $parameters[$key]
        
            if ($null -ne $parameter -and $parameter -ne '') {
                if ($key -eq "id") {
                    $id = $parameter
                } elseif ($key -ne "subdomain") {
                    $body["$($key)"] = $parameter
                }
                
            }
        }

    }
    # Process parameters as url queries
    else {
        foreach ($key in $parameters.keys) {

            $parameter = $parameters[$key]
            if ($null -ne $value -and $value -ne '') {
                if ($key_index -eq 0) {
                    $request_url += "?"
                }
                else {
                    $request_url += "&"
                }
                if ($parameter.name -eq "id") {
                    $id = $parameter.value
                }
                $request_url += $parameter.name + "=" + $parameter.value
                #write-host "$($parameter.name) : $($parameter.value)"
            }

            $key_index += 1
        }
    }

    
    if ($id) {
        $request_url += "/$id"
    }

    $request = New-Object PsObject -Property @{ 
        request_url = $request_url;
        body        = $body;
    }

    return $request

}

Export-ModuleMember -Function *