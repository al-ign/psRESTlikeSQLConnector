{
    # required
    Import-Module PSminSQL
    Register-Assemblies
    
    # endpoint parameters
    $PodeEndPoint = @{
        Address = 'localhost'
        Port = 8080
        Protocol = 'Http'
        }


    #default prefix for all routes
    $RootAPIPath = '/dbapi/v1'

    $badsqlchars = ';',"'",'--'

    # create endpoint
    Add-PodeEndpoint @PodeEndPoint

    # Verbose output, does a little with Pode though...
    $VerbosePreference = 2 

    # Enable Logging
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging -Levels Error, Warning, Informational, Verbose 

    # OpenAPI support
    Enable-PodeOpenApi -Title 'psRESTlikeSQLConnector' -Version 0.0.0.3 -Path ($RootAPIPath + '/openapi')
    Enable-PodeOpenApiViewer -Type Swagger -Path ($RootAPIPath + '/swagger')
    
    # broken in Pode 4.2.4?
    #Enable-PodeOpenApiViewer -Type ReDoc  -Path ($RootAPIPath + '/redoc')

  
    # default parameters
    $defaultParameters = @{
        Port = 3306
        Provider = 'MySql'
        Host = 'localhost'
        }
 

    # some OpenAPI common things
    $openAPICommonHeaders = @(
        New-PodeOAStringProperty -Name 'X-Host' -Description 'SQL server address' -Default $defaultParameters.Host | ConvertTo-PodeOAParameter -In Header
        New-PodeOAIntProperty    -Name 'X-Port' -Description 'SQL server port' -Default $defaultParameters.Port | ConvertTo-PodeOAParameter -In Header
        New-PodeOAStringProperty -Name 'X-Provider' -Description 'SQL .NET Provider' -Default $defaultParameters.Provider | ConvertTo-PodeOAParameter -In Header
        New-PodeOAStringProperty -Name 'X-ConnectionString' -Description 'Connection String' | ConvertTo-PodeOAParameter -In Header
        New-PodeOAStringProperty -Name 'X-DebugOutput' -Description 'Enable debug output' | ConvertTo-PodeOAParameter -In Header
        New-PodeOAStringProperty -Name 'X-DoNotProcessSQL' -Description 'Do not process SQL query' | ConvertTo-PodeOAParameter -In Header
        )

    function AddOpenAPICommonResponses {
    param ($route)
        $openAPICommonResponses = @(
            @{
                Route = $route 
                StatusCode = 523
                Description = 'Unable to connect to the specified SQL server'
                }
            @{
                Route = $route 
                StatusCode = 489
                Description = 'Wrong connection parameters'
                }
            @{
                Route = $route 
                StatusCode = 488
                Description = 'Error in SQL syntax'
                }
            @{
                Route = $route 
                StatusCode = 403
                Description = 'Access denied'
                }
            
            )
        foreach ($thisResponse in $openAPICommonResponses) {
            Add-PodeOAResponse @thisResponse
            }
        }

    # basic "pass-thru" authentication with username and password as is (because they are needed to be passed to SQL)
    New-PodeAuthScheme -Basic | Add-PodeAuth -Name 'BasicAuth' -Sessionless  -ScriptBlock {
        param($username, $password)
        return @{
            User = @{
                Username = $username
                Password = $password
                }
            }
        }


    # Invoke-SqlQuery wrapper so it wouldn't need to be repeated at the every route
    # session/headers and other parameters are directly inherited at the runtime

    function InvokeSqlQueryWrapper {
        param (
            $Object
            )

        # do the thing only if it makes sense to do
        if ($Object.DoNotProcessSQL) {

            $Object.Error = 'Success'
            $Object.HTTPCode = 202
            $Object.errorMessage = "Do not process SQL was requested"
            }
       
        elseif ($Object.ShouldProcessSQL) {
            try {

                $Object.Error = 'Failed to invoke SQL query'
                $Object.HTTPCode = 500

                # splat
                $InvokeSqlQuery = @{
                    Provider = $Object.Provider
                    Query = $Object.Query
                    ConnectionString = $Object.ConnectionString
                    }
            
                $Object.Result = Invoke-SqlQuery @InvokeSqlQuery -ErrorAction Stop

                $Object.Error = 'Success'
                $Object.HTTPCode = 200
                }

            Catch {
                # Write down a proper error message
                $Object.errorMessage = $_.Exception.Message

                # alter HTTP status response code based on some regex magik
                $Object.HTTPCode = switch -Regex ($Object.errorMessage) {
            
                    '(error).+(SQL).+(syntax)' {488}
                    '(Authentication).+(failed)' {403}
                    'Unable to connect' {523}
                    'Query was empty' {488}
                    
                    default {
                        $Object.HTTPCode
                        }
                    }
            
                if ($Object.Debug) {
                    'InvokeSqlQueryWrapper debug output' | Out-Default
                    $Object | out-default
                    $_ | Write-PodeErrorLog
                    }
                }

            finally {
                # nothing here because $Object is returned anyway
                }

            } # end if object.shouldprocess

        # return object
        $Object

        }

    # Wrapper for the default JSON response writer
    function WritePodeJsonResponseWrapper {
        param ($Object)

        if ($Object.Debug) {
            'WritePodeJsonResponseWrapper debug output' | out-default
            $Object | Out-Default
            
            Write-PodeJsonResponse -Value $Object -StatusCode $Object.HTTPCode
            }
        else {
            if ($Object.Error -eq 'Success') {
                if ($null -eq $Object.Result) {
                    Write-PodeJsonResponse -Value ($true|ConvertTo-Json) -StatusCode $Object.HTTPCode
                    }
                else {
                    Write-PodeJsonResponse -Value $Object.Result -StatusCode $Object.HTTPCode
                    }
                }
            else {
                Write-PodeJsonResponse -Value (
                    [ordered]@{
                        #Result = $Object.Result
                        Error = $Object.Error
                        ErrorMessage = $Object.errorMessage
                        }
                    ) -StatusCode $Object.HTTPCode
            
                }
            }
        }


    # some helper functions

    # defaults
    function newParametersObject {
        #'newParametersObject debug output' | Out-Default
        #$defaultParameters | out-default

        $Object = [ordered]@{
            Provider = 'MySql'
            Query = $null
            ConnectionString = $null
            HTTPCode = 500
            ShouldProcessSQL = $false
            DoNotProcessSQL = $false
            Error = $null
            ErrorMessage = $null
            Debug = $false
            Result = $null
            }

        # enable debug output 
        if (
            $WebEvent.Request.Headers['X-DebugOutput'] -or ($WebEvent.Query['debug'])
            ) {
            $Object.Debug = $true
            }

        # do not process sql query
        if (
            $WebEvent.Request.Headers['X-DoNotProcessSQL'] -or ($WebEvent.Query['DoNotProcessSQL'])
            ) {
            $Object.DoNotProcessSQL = $true
            }

        # override sql provider if specified
        if ($WebEvent.Request.Headers['X-Provider']) {
            $Object.Provider = $WebEvent.Request.Headers['X-Provider']
            }

        # use connection string if specified, otherwise construct it
        if ($WebEvent.Request.Headers['X-ConnectionString']) {
            
            $Object.ConnectionString = $WebEvent.Request.Headers['X-ConnectionString']
            $Object.Error = 'Using specified connection string'
            $Object.ShouldProcessSQL = $true
            $Object.HTTPCode = 200
            }
        else {
            try {
                $Object.HTTPCode = 489
                $Object.Error = 'Failed to create connection string'
                $Object.ConnectionString = CreateConnectParams -ErrorAction Stop
                $Object.Error = 'Succesfully created connection string'
                $Object.ShouldProcessSQL = $true
                $Object.HTTPCode = 200
                }
            Catch {
                # Write down a proper error message
                $Object.errorMessage = $_.Exception.Message
            
                # alter HTTP response status code based on some regex magik
                $Object.HTTPCode = switch -Regex ($Object.errorMessage) {
            
                    default {
                        $Object.HTTPCode
                        }
                    }

                if ($Object.Debug) {
                    'newParameterObject debug output' | Out-Default
                    $Object | out-default
                    $_ | Write-PodeErrorLog
                    }
            
                }
            } # endif $WebEvent.Request.Headers['X-ConnectionString']
             
        #return
        $Object
        }

    # functions to create ConnectionString
    function CreateConnectString {
    [cmdletbinding()]
        param (
            $Server = 'localhost',
            [ValidateRange(1,65535)][int]$Port = 3306,
            $Username = 'root',
            $Password = 'root'
            )

        switch -Regex ($Object.Provider) {
            'MySql' {
                'Server={0};port={1};user={2};password={3};' -f $server, $port, $username, $password
                }

            default {
                'Server={0};port={1};user={2};password={3};' -f $server, $port, $username, $password
                }
            }
        }

    function CreateConnectParams {
    [cmdletbinding()]
    param()
        $ConnectionStringSplat = @{
            Username = $WebEvent.Auth.User.Username
            Password = $WebEvent.Auth.User.Password
            Server = 'localhost'
            Port = 3306
            }
        
        if ($WebEvent.Request.Headers['X-Host']) {
            $ConnectionStringSplat.Server = $WebEvent.Request.Headers['X-Host']
            }

        if ($WebEvent.Request.Headers['X-Port']) {
            $ConnectionStringSplat.Port = $WebEvent.Request.Headers['X-Port']
            }

        $connectionString = CreateConnectString @ConnectionStringSplat
        
        if ($Object.Debug) {
            'CreateConnectParams: {0}' -f $connectionString  | Out-Default
            }

        $connectionString
        }

    # construct a column reference for SELECT etc  
    function newColumnReference {
        if ($WebEvent.Query['columns']) {
            $WebEvent.Query['columns']
            }
        else {
            '*'
            }
        }

    # construct a table reference (because we always know the db and table) by the path
    function newTableReference {
            '{0}.{1}' -f $WebEvent.Parameters['db'], $WebEvent.Parameters['table']
        }


    ## ROUTES ###

    #load routes from ./routes

    Use-PodeRoutes (Join-path . Routes)


} # End Server Initialization