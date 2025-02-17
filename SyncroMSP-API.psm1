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
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/appointment_types"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    
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
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/appointment_types"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body ($request.body | convertTo-Json) -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText } -ContentType "application/json"
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    return $response
}

function Update-SyncroAppointmentType {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id,
        [string] $name,
        [string] $email_instructions,
        [int] $location_type,
        [string] $location_hard_code
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/appointment_types"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body ($request.body | convertTo-Json) -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText } -ContentType "application/json"
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    return $response
}

function Remove-SyncroAppointmentType {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/appointment_types"
    $method = "DELETE"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    
    return $response
}

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
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/appointments"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body ($request.body | convertTo-Json) -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText } -ContentType "application/json"
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    return $response
}

function Update-SyncroAppointment {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id,
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
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/appointments"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body ($request.body | convertTo-Json) -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText } -ContentType "application/json"
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    return $response
}
function Remove-SyncroAppointment {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/appointments"
    $method = "DELETE"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    
    return $response
}


## Asset

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
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/customer_assets"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    
    if ($PSCmdlet.ParameterSetName -eq 'List') {
        return $response.assets
    }
    else {
        return $response.asset
    }
}

function New-SyncroAsset {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByTypeName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByTypeId')]
        [string] $subdomain,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByTypeName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByTypeId')]
        [string] $name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByTypeName')]
        [string] $asset_type_name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByTypeId')]
        [int] $asset_type_id,

        [hashtable] $properties,
        [int] $customer_id,
        [string] $asset_serial
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/customer_assets"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body ($request.body | convertTo-Json) -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText } -ContentType "application/json"
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    return $response
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
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/customer_assets"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body ($request.body | convertTo-Json) -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText } -ContentType "application/json"
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    return $response
}
# Call
function Get-SyncroCallerId {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [string] $did,
        [bool] $outbound
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/callerid"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    
    return $response
}

# Contacts

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
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/contacts"
    $method = "GET"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    
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
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/contacts"
    $method = "POST"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body ($request.body | convertTo-Json) -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText } -ContentType "application/json"
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    return $response.contact
}

function Update-SyncroContact {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id,
        [int] $customer_id,
        [Parameter(Mandatory = $true)] [string] $name,
        [string] $address1,
        [string] $address2,
        [string] $city,
        [string] $state,
        [string] $zip,
        [string] $email,
        [string] $phone,
        [string] $title,
        [string] $mobile,
        [string] $notes
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/contacts"
    $method = "PUT"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    
    if ($request.body) {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -body ($request.body | convertTo-Json) -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText } -ContentType "application/json"
    }
    else {
        $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    }
    
    return $response.contact
}

function Remove-SyncroContact {
    param(
        [Parameter(Mandatory = $true)] [string] $subdomain,
        [Parameter(Mandatory = $true)] [int] $id
    )
    
    $base_url = "https://$subdomain.syncromsp.com/api/v1"
    $end_point = "/contacts"
    $method = "DELETE"

    $parameters = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'verbose' -and $key -ne 'debug' -and $key -ne 'erroraction' -and $key -ne 'warningaction' -and $key -ne 'informationaction' -and $key -ne 'errorvariable' -and $key -ne 'warningvariable' -and $key -ne 'informationvariable' -and $key -ne 'outbuffer' -and $key -ne 'pipelinevariable') {
            $parameters[$key] = $PSBoundParameters[$key]
        }
    }
    
    $request = Format-SyncroRequestUrl -base_url $base_url -endpoint $end_point -parameters $parameters -method $method
    $response = Invoke-RestMethod -Uri $request.request_url -Method $method -Headers @{"Authorization" = Get-Secret -name $subdomain -AsPlainText }
    
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