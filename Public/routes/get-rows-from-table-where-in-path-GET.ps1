$scriptblock = {
    ## get data from the table
        $p = newParametersObject
        $tableReference = newTableReference 
        $columnReference = newColumnReference


    if ($WebEvent.Parameters['col'] -and $WebEvent.Parameters['value']) {
        $Where = '{0} = {1}' -f $WebEvent.Parameters['col'], $WebEvent.Parameters['value']
        $p.Query = 'SELECT {1} FROM {0} WHERE {2}' -f $tableReference, $columnReference, $Where
        }
                
    # add a limit statement
    if ($WebEvent.Query['limit']) {
        try {
            $p.Query = '{0} LIMIT {1}' -f $p.Query, [int]($WebEvent.Query['limit'])
            }
        catch {
            $_ | Write-PodeErrorLog
            'Illegal value for "LIMIT" was passed, ignoring: {0}' -f $WebEvent.Query['limit'] | Write-PodeErrorLog
            }
        }

    $p = InvokeSqlQueryWrapper $p
    WritePodeJsonResponseWrapper $P
    } # end API

$PodeRoute = @{
    Method = 'GET'
    Path = $RootAPIPath + '/:db/:table/:col/:value'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Get rows from the table where :col = :value'
    Tags = 'Row','Table'
    }

Set-PodeOARouteInfo @PodeOARouteInfo

# OpenAPI Parameters info
$PodeOARequest = @{
    Route = $route
    Parameters = @(
        New-PodeOAStringProperty -Name 'db' -Required -Description 'Database name' | ConvertTo-PodeOAParameter -In Path
        New-PodeOAStringProperty -Name 'table' -Required -Description 'Table name' | ConvertTo-PodeOAParameter -In Path    
        New-PodeOAStringProperty -Name 'col' -Description 'Column name for WHERE clause' | ConvertTo-PodeOAParameter -In Path
        New-PodeOAStringProperty -Name 'value' -Description 'Value for WHERE clause' | ConvertTo-PodeOAParameter -In Path  
        New-PodeOAStringProperty -Name 'columns' -Description 'Return only columns' | ConvertTo-PodeOAParameter -In Query

        $openAPICommonHeaders
        )
    }

Set-PodeOARequest @PodeOARequest

$PodeOAResponse = @{
    Route = $route 
    StatusCode = 400
    Description = 'No query was received'
    }
<#
Add-PodeOAResponse @PodeOAResponse
#>

# add common OpenAPI responses
AddOpenAPICommonResponses $route

# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest, PodeOAResponse
