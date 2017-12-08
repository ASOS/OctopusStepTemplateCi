function Invoke-NuGetInstall
{

    param
    (

        [Parameter(Mandatory=$true)]
        [string] $NuGet,

        [Parameter(Mandatory=$false)]
        [string] $Source,

        [Parameter(Mandatory=$false)]
        [string] $PackageId,

        [Parameter(Mandatory=$false)]
        [version] $Version,

        [Parameter(Mandatory=$false)]
        [string] $OutputDirectory,

        [Parameter(Mandatory=$false)]
        [switch] $ExcludeVersion

    )

    write-host "installing nuget package '$PackageId'";

    $cmdLine = $NuGet;

    $cmdArgs = @( "Install", $PackageId );

    if( $PSBoundParameters.ContainsKey("Source") )
    {
        $cmdArgs += @( "-Source", "`"$Source`"" );
    }

    if( $PSBoundParameters.ContainsKey("OutputDirectory") )
    {
        $cmdArgs += @( "-OutputDirectory", "`"$OutputDirectory`"" );
    }

    if( $PSBoundParameters.ContainsKey("Version") )
    {
        $cmdArgs += @( "-Version", $Version.ToString() );
    }

    if( $ExcludeVersion )
    {
        $cmdArgs += "-ExcludeVersion";
    }

    write-host "cmdLine = '$cmdLine'";
    write-host "cmdArgs = ";
    write-host ($cmdArgs | fl * | out-string);

    $process = Start-Process -FilePath $cmdLine -ArgumentList $cmdArgs -Wait -NoNewWindow -PassThru;

    if( $process.ExitCode -ne 0 )
    {
        throw new-object System.InvalidOperationException("process terminated with exit code $($process.ExitCode)");
    }

}
