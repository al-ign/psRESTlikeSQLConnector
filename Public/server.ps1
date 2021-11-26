
$podeServer = @{
    Threads = 40
    }

if ( $PSScriptRoot ) {
    Start-PodeServer -FilePath (Join-Path $PSScriptRoot run.ps1) @podeServer
    }
else {
    Start-PodeServer -FilePath ./run.ps1 @podeServer
    }
