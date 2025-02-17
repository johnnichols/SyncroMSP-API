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

# Helper function for getting a request url for the endpoints
function Format-SyncroRequestUrl {
    param (
        [Parameter(Mandatory)] [string] $base_url,
        [Parameter(Mandatory)] [string] $endpoint,
        [Parameter(Mandatory)] [hashtable] $parameters,
        [Parameter(Mandatory)] [ValidateSet("GET", "PUT", "POST", "DELETE")] [string] $method
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
                }
                elseif ($key -ne "subdomain") {
                    $body["$($key)"] = $parameter
                }
                
            }
        }

    }
    # Process parameters as url queries
    else {
        foreach ($key in $parameters.keys) {
            
            $parameter = $parameters[$key]
            
            $param_name = if ($parameter.PSObject.Properties.Match('name').Count) { $parameter.name } else { $key }
            $param_value = if ($parameter.PSObject.Properties.Match('value').Count) { $parameter.value } else { $parameter }
            
            if ($null -ne $param_value -and $param_value -ne '') {
                if ($param_name -eq "id") {
                    $id = $param_value
                    continue
                }
                if ($param_name -eq "subdomain") {
                    continue
                }
                if ($key_index -eq 0) {
                    $request_url += "?"
                }
                else {
                    $request_url += "&"
                }          
                
                $request_url += $param_name + "=" + $param_value
                
                
            }

            $key_index += 1
        }
    }

    
    if ($id) {
        $request_url += "/$id"
    }
    write-host $request_url
    $request = New-Object PsObject -Property @{ 
        request_url = $request_url;
        body        = $body;
    }

    return $request

}


function Invoke-SyncroApi {
    param(
        [Parameter(Mandatory = $true)]
        [string] $subdomain,
        
        [Parameter(Mandatory = $true)]
        [string] $endpoint,
        
        [Parameter(Mandatory = $false)]
        [hashtable] $parameters,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE')]
        [string] $method = 'GET'
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $endpoint -parameters $parameters -method $method
    
    $headers = @{
        "Authorization" = "Bearer $(Get-Secret -name $subdomain -AsPlainText)"
        "Content-Type"  = "application/json"
    }
    
    $splat = @{
        Uri     = $request.request_url
        Method  = $method
        Headers = $headers
    }
    
    if ($method -in 'POST', 'PUT' -and $request.body) {
        $splat['Body'] = $request.body | ConvertTo-Json
    }
    
    $response = Invoke-RestMethod @splat
    return $response
}


############### API End Points ###############

# Appointment Types

function Get-SyncroAppointmentTypes {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string] $subdomain,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [int] $id
    )
    
    $endpoint = "/appointment_types"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }

    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $endpoint -parameters $parameters -method $method
    
    if ($PSCmdlet.ParameterSetName -eq 'List') {
        return $response.appointment_types
    }
    else {
        return $response
    }
}
function New-SyncroAppointmentType {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [string] $name,
        [string] $email_instructions,
        [Parameter(Mandatory = $true)] [int] $location_type,
        [string] $location_hard_code
    )
    
    $endpoint = "/appointment_types"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $endpoint -parameters $parameters -method $method
    return $response
}


function Update-SyncroAppointmentType {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [long] $id,
        [string] $name,
        [string] $email_instructions,
        [int] $location_type,
        [string] $location_hard_code
    )
    
    $end_point = "/appointment_types"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}

function Remove-SyncroAppointmentType {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [long] $id
    )
    
    $end_point = "/appointment_types"
    $method = "DELETE"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}


#Appointments

function Get-SyncroAppointments {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string] $subdomain,

        [Parameter(ParameterSetName = 'List')]
        [int] $page,
        
        [Parameter(ParameterSetName = 'List')]
        [int] $customer_id,
        
        [Parameter(ParameterSetName = 'List')]
        [int] $user_id,
        
        [Parameter(ParameterSetName = 'List')]
        [datetime] $start_date,
        
        [Parameter(ParameterSetName = 'List')]
        [datetime] $end_date,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [long] $id
    )
    
    $end_point = "/appointments"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }

    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    
    if ($PSCmdlet.ParameterSetName -eq 'List') {
        return $response.appointments
    }
    else {
        return $response.appointment
    }
}

function New-SyncroAppointment {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [string] $summary,
        [string] $description,
        [Parameter(Mandatory = $true)] [datetime] $start_at,
        [datetime] $end_at,
        [int] $appointment_type_id,
        [int] $customer_id,
        [int] $user_id,
        [int[]] $user_ids,
        [int] $ticket_id,
        [string] $location,
        [bool] $do_not_email,
        [bool] $email_customer,
        [string] $appointment_duration,
        [bool] $all_day
    )
    
    $end_point = "/appointments"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response.appointment
}

function Update-SyncroAppointment {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [long] $id,
        [string] $summary,
        [string] $description,
        [Parameter(Mandatory = $true)] [datetime] $start_at,
        [datetime] $end_at,
        [int] $appointment_type_id,
        [int] $customer_id,
        [int] $user_id,
        [int[]] $user_ids,
        [int] $ticket_id,
        [string] $location,
        [bool] $email_customer,
        [string] $appointment_duration,
        [bool] $all_day
    )
    
    $end_point = "/appointments"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response.appointment
}

function Remove-SyncroAppointment {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [long] $id
    )
    
    $end_point = "/appointments"
    $method = "DELETE"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}

# Assets

function Get-SyncroAssets {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string] $subdomain,

        [Parameter(ParameterSetName = 'List')]
        [bool] $snmp_enabled,
        
        [Parameter(ParameterSetName = 'List')]
        [int] $customer_id,
        
        [Parameter(ParameterSetName = 'List')]
        [int] $asset_type_id,
        
        [Parameter(ParameterSetName = 'List')]
        [string] $query,
        
        [Parameter(ParameterSetName = 'List')]
        [int] $page,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [int] $id
    )
    
    $end_point = "/customer_assets"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }

    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    
    if ($PSCmdlet.ParameterSetName -eq 'List') {
        return $response.assets
    }
    else {
        return $response
    }
}

function New-SyncroAsset {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [string] $name,
        [string] $asset_type_name,
        [int] $asset_type_id,
        [hashtable] $properties,
        [int] $customer_id,
        [string] $asset_serial
    )
    
    $end_point = "/customer_assets"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response.asset
}

function Update-SyncroAsset {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id,
        [Parameter(Mandatory = $true)] [string] $name,
        [string] $asset_type_name,
        [int] $asset_type_id,
        [hashtable] $properties,
        [int] $customer_id,
        [string] $asset_serial
    )
    
    $end_point = "/customer_assets"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response.asset
}

# Contact

function Get-SyncroContacts {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string] $subdomain,

        [Parameter(ParameterSetName = 'List')]
        [int] $customer_id,
        
        [Parameter(ParameterSetName = 'List')]
        [int] $page,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [int] $id
    )
    
    $end_point = "/contacts"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }

    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    
    if ($PSCmdlet.ParameterSetName -eq 'List') {
        return $response.contacts
    }
    else {
        return $response
    }
}

function New-SyncroContact {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $customer_id,
        [string] $name,
        [string] $address1,
        [string] $address2,
        [string] $city,
        [string] $state,
        [string] $zip,
        [string] $email,
        [string] $phone,
        [string] $mobile,
        [string] $notes
    )
    
    $end_point = "/contacts"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}

function Update-SyncroContact {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id,
        [Parameter(Mandatory = $true)] [string] $name,
        [int] $customer_id,
        [string] $address1,
        [string] $address2,
        [string] $city,
        [string] $state,
        [string] $zip,
        [string] $email,
        [string] $phone,
        [string] $mobile,
        [string] $notes
    )
    
    $end_point = "/contacts"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}

function Remove-SyncroContact {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id
    )
    
    $end_point = "/contacts"
    $method = "DELETE"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}

# Contracts

function Get-SyncroContracts {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string] $subdomain,

        [Parameter(ParameterSetName = 'List')]
        [int] $customer_id,
        
        [Parameter(ParameterSetName = 'List')]
        [int] $page,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [int] $id
    )
    
    $end_point = "/contracts"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }

    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    
    if ($PSCmdlet.ParameterSetName -eq 'List') {
        return $response.contracts
    }
    else {
        return $response
    }
}

function New-SyncroContract {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $customer_id,
        [Parameter(Mandatory = $true)] [string] $title,
        [string] $description,
        [datetime] $start_date,
        [datetime] $end_date,
        [decimal] $price,
        [string] $frequency,
        [bool] $automatically_renew,
        [bool] $send_invoice_automatically,
        [bool] $active
    )
    
    $end_point = "/contracts"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}

function Update-SyncroContract {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id,
        [string] $title,
        [string] $description,
        [datetime] $start_date,
        [datetime] $end_date,
        [decimal] $price,
        [string] $frequency,
        [bool] $automatically_renew,
        [bool] $send_invoice_automatically,
        [bool] $active
    )
    
    $end_point = "/contracts"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}

function Remove-SyncroContract {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id
    )
    
    $end_point = "/contracts"
    $method = "DELETE"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}

# Customer

function Get-SyncroCustomers {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string] $subdomain,

        [Parameter(ParameterSetName = 'List')]
        [string] $query,
        
        [Parameter(ParameterSetName = 'List')]
        [int] $page,
        
        [Parameter(ParameterSetName = 'List')]
        [string] $business_name,
        
        [Parameter(ParameterSetName = 'List')]
        [string] $email,
        
        [Parameter(ParameterSetName = 'List')]
        [string] $phone,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [int] $id
    )
    
    $end_point = "/customers"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }

    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    
    if ($PSCmdlet.ParameterSetName -eq 'List') {
        return $response.customers
    }
    else {
        return $response.customer
    }
}

function New-SyncroCustomer {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [string] $business_name,
        [string] $firstname,
        [string] $lastname,
        [string] $email,
        [string] $phone,
        [string] $mobile,
        [string] $address,
        [string] $address2,
        [string] $city,
        [string] $state,
        [string] $zip,
        [string] $notes,
        [bool] $referred_by,
        [bool] $allow_portal,
        [bool] $portal_access,
        [bool] $portal_access_template,
        [string] $tax_rate,
        [string] $notification_email,
        [string] $invoice_cc_emails,
        [string] $invoice_term_id,
        [bool] $no_tax,
        [bool] $print_notes_on_invoice,
        [hashtable] $properties
    )
    
    $end_point = "/customers"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response.customer
}

function Update-SyncroCustomer {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id,
        [string] $business_name,
        [string] $firstname,
        [string] $lastname,
        [string] $email,
        [string] $phone,
        [string] $mobile,
        [string] $address,
        [string] $address2,
        [string] $city,
        [string] $state,
        [string] $zip,
        [string] $notes,
        [bool] $referred_by,
        [bool] $allow_portal,
        [bool] $portal_access,
        [bool] $portal_access_template,
        [string] $tax_rate,
        [string] $notification_email,
        [string] $invoice_cc_emails,
        [string] $invoice_term_id,
        [bool] $no_tax,
        [bool] $print_notes_on_invoice,
        [hashtable] $properties
    )
    
    $end_point = "/customers"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response.customer
}

function Remove-SyncroCustomer {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id
    )
    
    $end_point = "/customers"
    $method = "DELETE"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
}

# Estimate

function Get-SyncroEstimates {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string] $subdomain,

        [Parameter(ParameterSetName = 'List')]
        [int] $customer_id,
        
        [Parameter(ParameterSetName = 'List')]
        [string] $number,
        
        [Parameter(ParameterSetName = 'List')]
        [string] $status,
        
        [Parameter(ParameterSetName = 'List')]
        [int] $page,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [int] $id
    )
    
    $end_point = "/estimates"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }

    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    
    if ($PSCmdlet.ParameterSetName -eq 'List') {
        return $response.estimates
    }
    else {
        return $response.estimate
    }
}

function New-SyncroEstimate {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $customer_id,
        [string] $number,
        [string] $status,
        [datetime] $date,
        [string] $note,
        [string] $po_number,
        [string] $terms,
        [bool] $sent,
        [bool] $viewed,
        [bool] $accepted,
        [bool] $declined,
        [array] $line_items,
        [decimal] $tax_rate,
        [bool] $no_tax,
        [bool] $no_charge,
        [string] $ticket_id
    )
    
    $end_point = "/estimates"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response.estimate
}

function Update-SyncroEstimate {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id,
        [int] $customer_id,
        [string] $number,
        [string] $status,
        [datetime] $date,
        [string] $note,
        [string] $po_number,
        [string] $terms,
        [bool] $sent,
        [bool] $viewed,
        [bool] $accepted,
        [bool] $declined,
        [array] $line_items,
        [decimal] $tax_rate,
        [bool] $no_tax,
        [bool] $no_charge,
        [string] $ticket_id
    )
    
    $end_point = "/estimates"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response.estimate
}

function Remove-SyncroEstimate {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id
    )
    
    $end_point = "/estimates"
    $method = "DELETE"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $response = Invoke-SyncroApi -subdomain $subdomain -endpoint $end_point -parameters $parameters -method $method
    return $response
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








Export-ModuleMember -Function *