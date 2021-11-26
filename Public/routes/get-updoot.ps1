    ## hehe funny give updoot
    Add-PodeRoute -Method GET -Path $RootAPIPath -ScriptBlock {
        Write-PodeJsonResponse -Value (
            @{
                'Hello there' = 'General Kenobi'
                Date = Get-date
                }
            ) -StatusCode 405
        } ## end API route
