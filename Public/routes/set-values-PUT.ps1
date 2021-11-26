## insert data
$scriptblock = {
    $p = newParametersObject
    $tableReference = newTableReference 

    If ($I = $WebEvent.Data.Values) {
        
        $valuesList = @(
            foreach ($r in $i) {
                foreach ($k in $r.Keys) {
                    '{0} = {1}' -f $k, $r[$k]
                    
                    }
                }
            )

        $valuesList = $valuesList -join ', '

        if ($whereClause = $webEvent.Data.Where) {
            $p.Query = 'UPDATE {0} SET {1} WHERE {2};' -f $tableReference, $valuesList, $whereClause
            }
        else {
            $p.Query = 'UPDATE {0} SET {1}' -f $tableReference, $valuesList
            }
        
        }

    $p = InvokeSqlQueryWrapper $p
    WritePodeJsonResponseWrapper $P

    } # End

$PodeRoute = @{
    Method = 'PATCH'
    Path = $RootAPIPath + '/:db/:table/'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Update values in the table'
    Tags = 'Table','Row'
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

    RequestBody = New-PodeOARequestBody -Required -ContentSchemas @{ 
        'application/json' = (
            New-PodeOAObjectProperty -Name 'Data' -Description 'Column=Value pairs to insert' -Required -Properties @(
                
                New-PodeOAObjectProperty -Name Values -Description 'Column=Value pairs to insert' -Array -Required -Properties @(
                    New-PodeOAStringProperty -Name 'Column' -Description 'Column name' -Required 
                    )
                
                New-PodeOAStringProperty -Name 'Where' -Description 'Where clause' 
                
                )
            )
        }
    }

Set-PodeOARequest @PodeOARequest


# add common OpenAPI responses
AddOpenAPICommonResponses $route


# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest
