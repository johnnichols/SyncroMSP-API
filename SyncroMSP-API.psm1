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
        [Parameter(Mandatory)] [string] $subdomain,
        [string] $date_from,
        [string] $date_to,
        [bool] $mine,
        [int] $page
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/appointments"
    $method = "GET"

    $request_url = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters (Get-Command -Name $MyInvocation.InvocationName).Parameters;
    return $request_url
}

function Format-SyncroRequestUrl {
    param (
        [Parameter(Mandatory)] [string] $base_url,
        [Parameter(Mandatory)] [string] $endpoint,
        [Parameter(Mandatory)] [object[]] $parameters,
        [string] $body
    )   


    #Process Parameters
    foreach ($key in $parameters.keys) {
        $parameter = Get-Variable -Name $key -ErrorAction SilentlyContinue;
        if ($parameter) {
            write-host "$($parameter.name) : $($parameter.value)"
        }
    }

}

Export-ModuleMember -Function *