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
        [int] $id
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
    write-host $parameters
    Write-Host "Parameters: $($parameters.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" })"
    # Debug output to check the type of parameters
    Write-Host "Type of parameters: $($parameters.GetType().FullName)"
    $request_url = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters #(Get-Command -Name $MyInvocation.InvocationName).Parameters;
    
    $token = Get-Secret -name $subdomain -AsPlainText

    $headers = @{
        "Authorization" = "$token" 
    }

    $response = Invoke-RestMethod -Uri $request_url -Method $method -Headers $headers
    return $response
}

function Format-SyncroRequestUrl {
    param (
        [Parameter(Mandatory)] [string] $base_url,
        [Parameter(Mandatory)] [string] $endpoint,
        [Parameter(Mandatory)] [hashtable] $parameters,
        [string] $body
    )   

    $key_index = 0
    $request_url = $base_url + $endpoint
    #Process Parameters
    foreach ($key in $parameters.keys) {

        $parameter = $parameters[$key] #= Get-Variable -Name $key -ErrorAction SilentlyContinue;
        if ($null -ne $value -and $value -ne '') {#$parameter -and $parameter.name -and -not [string]::IsNullOrEmpty($parameter.value)) {
            if ($key_index -eq 0) {
                $request_url += "?"
            } else {
                $request_url += "&"
            }
            $request_url += $parameter.name + "=" + $parameter.value
            #write-host "$($parameter.name) : $($parameter.value)"
        }

        $key_index += 1
    }
    return $request_url

}

Export-ModuleMember -Function *