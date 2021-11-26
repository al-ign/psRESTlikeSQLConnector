## insert data
$scriptblock = {
    $p = newParametersObject
    $tableReference = newTableReference 

    If ($I = $WebEvent.Data.Values) {
    <#
        $columnList = @()
        $valuesList = @()
        foreach ($r in $i) {
            $columnList += $r.Keys
            $valuesList += "'{0}'" -f $r[$r.Keys]
            }
            
        $columnList = $columnList -join ', '
        $valuesList = $valuesList -join ', '

        $p.Query = 'INSERT INTO {0} ({1}) VALUES ({2})' -f $tableReference,$columnList,$valuesList
    #>

        $columnList = @()
        $valuesList = @()

        foreach ($r in $i) {
            foreach ($k in $r.Keys) {
                $columnList += $k            
                $valuesList += $r[$k]
                }
            }
            
        $columnList = $columnList -join ', '
        $valuesList = $valuesList -join ', '

        $p.Query = 'INSERT INTO {0} ({1}) VALUES ({2})' -f $tableReference, $columnList, $valuesList

        }
    
    switch ($p.Provider) {
        'MySql' {
            #$p.Query = '{0}; SELECT ROW_COUNT();' -f $p.Query
            }

        }

    # WARNING
    # by default a success insert doesn't return anything which confuses Pode json wrapper returning error because there is nothing to return in 'Result'
    $p = InvokeSqlQueryWrapper $p
    WritePodeJsonResponseWrapper $P

    } # End

$PodeRoute = @{
    Method = 'POST'
    Path = $RootAPIPath + '/:db/:table/'
    Authentication = 'BasicAuth'
    ScriptBlock = $scriptblock
    }

$route = Add-PodeRoute -PassThru @PodeRoute

# OpenAPI Route info
$PodeOARouteInfo = @{
    Route = $route
    Summary = 'Insert values in to the table'
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
            New-PodeOAObjectProperty -Name 'Values' -Description 'Column=Value pairs to insert' -Required -Properties @(
                #New-PodeOAStringProperty -Name 'Data'
                New-PodeOAObjectProperty -Name 'Values' -Description 'Values' -Required -Properties @(
                    New-PodeOAStringProperty -Name 'Column' -Description 'Column name' -Required
                    )
                )
            )
        }
    }

Set-PodeOARequest @PodeOARequest


# add common OpenAPI responses
AddOpenAPICommonResponses $route


# cleanup
Remove-Variable scriptblock, PodeRoute, PodeOARouteInfo, PodeOARequest
