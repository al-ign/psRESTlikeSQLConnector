## list databases on server
$scriptblock = {
    $p = newParametersObject
    $p.Query = 'SHOW DATABASES;'

    $p = InvokeSqlQueryWrapper $p
    WritePodeJsonResponseWrapper $P

    } ### end API

#Add-PodeRoute -Method GET -Path ($RootAPIPath + '/databases') -Authentication 'BasicAuth' -ScriptBlock {

$PodeRoute = @{
    Method = 'GET'
    Path = $RootAPIPath + '/databases'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Retrieve a list of databases'
    Tags = 'Database'
    }

Set-PodeOARouteInfo @PodeOARouteInfo

# OpenAPI Parameters info
$PodeOARequest = @{
    Route = $route
    Parameters = @(
        $openAPICommonHeaders
        )
    }

Set-PodeOARequest @PodeOARequest

# add common OpenAPI responses
AddOpenAPICommonResponses $route

# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest
