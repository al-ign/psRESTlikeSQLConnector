## insert data
$scriptblock = {
    $p = newParametersObject
    $tableReference = newTableReference 


    If ($Where = $WebEvent.Data.Where) {
        $p.Query = 'DELETE FROM {0} WHERE {1}' -f $tableReference, $Where
        }

    switch ($p.Provider) {
        'MySql' {
            $p.Query = '{0}; SELECT ROW_COUNT();' -f $p.Query
            }

        }

    $p = InvokeSqlQueryWrapper $p
    WritePodeJsonResponseWrapper $P

    } # End

$PodeRoute = @{
    Method = 'DELETE'
    Path = $RootAPIPath + '/:db/:table/'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Delete rows from the table'
    Tags = 'Table','Row','Delete'
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
        $openAPICommonHeaders
        ) 
    RequestBody = New-PodeOARequestBody -Required -ContentSchemas @{ 
        'application/json' = (
            New-PodeOAStringProperty -Name 'Where' -Description 'WHERE clause'
            )
        }
    }

Set-PodeOARequest @PodeOARequest


# add common OpenAPI responses
AddOpenAPICommonResponses $route


# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest
