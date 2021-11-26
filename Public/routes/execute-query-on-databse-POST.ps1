#########

## this is not safe by any means. disable/delete this if you don't need it in your app
## POST method, supply 'application/json' content type and JSON {"Query":"SQL STATEMENT"}
$scriptblock = {

    $p = newParametersObject
    $tableReference = newTableReference 
    $columnReference = newColumnReference
     
    If ($q = $WebEvent.Data.Query) {
        $p.Query = 'SELECT {0} FROM {1} {2}' -f $columnReference, $tableReference, $q
        }
    else {
            $p.ShouldProcessSQL = $false
            $p.Error = 'Failed to invoke SQL query'
            $p.ErrorMessage = 'Query was requested but wasn''t supplied in the body'
            $P.HTTPCode = 500
        }


    $p = InvokeSqlQueryWrapper $p
    WritePodeJsonResponseWrapper $P

    } # end API


$PodeRoute = @{
    Method = 'POST'
    Path = $RootAPIPath + '/:db/:table/query'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Perform query on database'
    Tags = 'Query','Table'
    }

Set-PodeOARouteInfo @PodeOARouteInfo

# OpenAPI Parameters info
$PodeOARequest = @{
    Route = $route
    Parameters = @(
        #New-PodeOAStringProperty -Name 'query' -Required -Description 'SQL Query' | ConvertTo-PodeOAParameter -In Query
        #New-PodeOAStringProperty -Name 'table' -Required -Description 'Table name' | ConvertTo-PodeOAParameter -In Path
        New-PodeOAStringProperty -Name 'db' -Required -Description 'Database name' | ConvertTo-PodeOAParameter -In Path
        New-PodeOAStringProperty -Name 'table' -Required -Description 'Table name' | ConvertTo-PodeOAParameter -In Path    
        $openAPICommonHeaders
        ) 
    RequestBody = New-PodeOARequestBody -Required -ContentSchemas @{ 
        'application/json' = (
            New-PodeOAObjectProperty -Name 'SQL query' -Description 'An SQL query to execute' -Properties @(
                New-PodeOAStringProperty -Name 'Query' -Description 'An SQL query to execute'
                )
            )
        }
    }

Set-PodeOARequest @PodeOARequest


# add common OpenAPI responses
AddOpenAPICommonResponses $route

# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest
