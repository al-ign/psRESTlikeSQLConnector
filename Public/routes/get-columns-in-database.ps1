## get list of columns from the table

$scriptblock = {
    $p = newParametersObject
    $tableReference = newTableReference 
    $columnReference = newColumnReference
        
    $p.Query = "SHOW FIELDS FROM {0}" -f $tableReference
        
    $p = InvokeSqlQueryWrapper $p
    WritePodeJsonResponseWrapper $P

    }

$PodeRoute = @{
    Method = 'GET'
    Path = $RootAPIPath + '/:db/:table/columns'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Retrieve a list of columns in the table'
    Tags = 'Table','Column'
    }

Set-PodeOARouteInfo @PodeOARouteInfo

# OpenAPI Parameters info
$PodeOARequest = @{
    Route = $route
    Parameters = @(
        New-PodeOAStringProperty -Name 'db' -Required -Description 'Database name' | ConvertTo-PodeOAParameter -In Path
        New-PodeOAStringProperty -Name 'table' -Required -Description 'Table name' | ConvertTo-PodeOAParameter -In Path    
        $openAPICommonHeaders
        ) 
    }

Set-PodeOARequest @PodeOARequest

# add common OpenAPI responses
AddOpenAPICommonResponses $route

# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest
