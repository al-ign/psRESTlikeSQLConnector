$scriptblock = {
        
    $podeRoutes = Get-PodeRoute | select Method,
        @{N='OpenApiPath';E={$_.OpenApi.Path}}, 
        Authentication, 
        @{N='Metrics';E={$_.Metrics.Requests.Total}},
        @{N='LogicFile';E={$_.Logic.File}} `
        | Sort-Object OpenApiPath `
        | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        
    if (
        ($WebEvent.ContentType -eq 'application/json') -or 
        ($WebEvent.Request.Headers.Accept -eq 'application/json')
        ) {
        Write-PodeJsonResponse -Value $podeRoutes
        }
    else {
        Write-PodeHtmlResponse -Value $podeRoutes
        }
    'WebEvent ' |  Out-Default
    $WebEvent | Out-Default
    'WebEvent.Request ' |  Out-Default
    $WebEvent.Request | Out-Default
    'WebEvent.Request.Headers ' |  Out-Default
    $WebEvent.Request.Headers | Out-Default
    }


#Set-PodeOARouteInfo -Summary 'Retrieve a list of routes' -Tags 'Routes' 

#Add-PodeRoute -Method GET -Path  ($RootAPIPath + '/routes')  -ScriptBlock {


$PodeRoute = @{
    Method = 'GET'
    Path = $RootAPIPath + '/routes'
    #Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Retrieve a list of routes'
    Tags = 'Route'
    }

Set-PodeOARouteInfo @PodeOARouteInfo

# OpenAPI Parameters info
$PodeOARequest = @{
    Route = $route
    Parameters = @(
        #$openAPICommonHeaders
        )
    }

Set-PodeOARequest @PodeOARequest


$ResponseSchema = New-PodeOAObjectProperty -Properties @(
    (New-PodeOAStringProperty -Name 'Method'),
    (New-PodeOAStringProperty -Name 'OpenApiPath'),
    (New-PodeOAStringProperty -Name 'Authentication'),
    (New-PodeOAIntProperty -Name 'Metrics' -Description 'How many times this route was executed'),
    (New-PodeOAStringProperty -Name 'LogicFile' -Description 'Source file')
     
    )


$PodeOAResponse = @{
    Route = $route 
    StatusCode = 200
    Description = 'Basic information about routes'
    ContentSchemas = @{
        'application/json' = $ResponseSchema
        'text/html' = $ResponseSchema
        }
    }

Add-PodeOAResponse @PodeOAResponse


# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest, PodeOAResponse, ResponseSchema
