## this is not safe by any means. disable/delete this if you don't need it in your app
## GET method, supply ?query="SQL STATEMENT" to process
    
$scriptblock = {
   
    $p = newParametersObject

    if ($q = $WebEvent.Query['Query']) {

        # remove double quotes around the query value (SQL don't like it)
        if ($q -match '^\"(.+)\"$') {
            $q = $Matches[1]
            }
        $p.Query = $q
        }
    else {
        $p.ShouldProcessSQL = $false
        $p.Error = 'Failed to invoke SQL query'
        $p.ErrorMessage = 'Query was requested but wasn''t supplied in the query'
        $P.HTTPCode = 400
        }
        $RootAPIPath + '/query' + ' debug' | Out-Default
        $WebEvent.Query | Out-Default
    $p = InvokeSqlQueryWrapper $p
    WritePodeJsonResponseWrapper $P

    } # end API

$PodeRoute = @{
    Method = 'GET'
    Path = $RootAPIPath + '/query'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Perform a query'
    Tags = 'Query'
    }

Set-PodeOARouteInfo @PodeOARouteInfo

# OpenAPI Parameters info
$PodeOARequest = @{
    Route = $route
    Parameters = @(
        New-PodeOAStringProperty -Name 'query' -Required -Description 'SQL query to execute' | ConvertTo-PodeOAParameter -In Query
        $openAPICommonHeaders
        )
    }

Set-PodeOARequest @PodeOARequest

$PodeOAResponse = @{
    Route = $route 
    StatusCode = 400
    Description = 'No query was received'
    }

Add-PodeOAResponse @PodeOAResponse

# add common OpenAPI responses
AddOpenAPICommonResponses $route

# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest, PodeOAResponse
