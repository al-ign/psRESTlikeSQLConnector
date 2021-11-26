$scriptblock = {
    ## get data from the table
        $p = newParametersObject
        $tableReference = newTableReference 
        $columnReference = newColumnReference

        # default query so it wouldn't errorout (though it should be)
        #$p.Query = 'SELECT {1} FROM {0} LIMIT 0' -f $tableReference, $columnReference

        # Get all rows
        if ($WebEvent.Query['getallrows']) {
            $p.Query = 'SELECT {1} FROM {0}' -f $tableReference, $columnReference
            }

        # advanced query - careful, a full scale sql injection vuln
        if ($q = $WebEvent.Query['query']) {
            if ($q -match '^\"(.+)\"$') {
                $q = $Matches[1]
                }
            $p.Query = 'SELECT {1} FROM {0} {2}' -f $tableReference, $columnReference, $q
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


        # 
        if ($p.Query -notmatch '(\s*\;\s*)$') {
            $p.Query = '{0};'-f $p.Query
            }


        $p = InvokeSqlQueryWrapper $p
        WritePodeJsonResponseWrapper $P
        } # end API

$PodeRoute = @{
    Method = 'GET'
    Path = $RootAPIPath + '/:db/:table/'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Perform a query on the table'
    Tags = 'Query','Table'
    }

Set-PodeOARouteInfo @PodeOARouteInfo

# OpenAPI Parameters info
$PodeOARequest = @{
    Route = $route
    Parameters = @(
        New-PodeOAStringProperty -Name 'db' -Required -Description 'Database name' | ConvertTo-PodeOAParameter -In Path
        New-PodeOAStringProperty -Name 'table' -Required -Description 'Table name' | ConvertTo-PodeOAParameter -In Path    
        New-PodeOAStringProperty -Name 'query' -Description 'An SQL query to execute' | ConvertTo-PodeOAParameter -In Query
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
