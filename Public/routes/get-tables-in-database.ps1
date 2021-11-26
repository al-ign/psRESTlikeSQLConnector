# list tables from a :db

$scriptblock = {
    $p = newParametersObject
    $p.Query = "SHOW TABLES FROM {0};" -f ($WebEvent.Parameters['db'])

    $p = InvokeSqlQueryWrapper $p
    WritePodeJsonResponseWrapper $P

    }

$PodeRoute = @{
    Method = 'GET'
    Path = $RootAPIPath + '/:db/tables'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Retrieve a list of tables in the database'
    Tags = 'Table'
    }

Set-PodeOARouteInfo @PodeOARouteInfo

# OpenAPI Parameters info
$PodeOARequest = @{
    Route = $route
    Parameters = @(
        New-PodeOAStringProperty -Name 'db' -Required -Description 'Database name' | ConvertTo-PodeOAParameter -In Path
        $openAPICommonHeaders
        )
    }

Set-PodeOARequest @PodeOARequest

# add common OpenAPI responses
AddOpenAPICommonResponses $route

# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest
