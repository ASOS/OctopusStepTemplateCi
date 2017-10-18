function Import-PowerShellGalleryModule
{

    param
    (

        [Parameter(Mandatory=$true)]
        [string] $Name,

        [Parameter(Mandatory=$true)]
        [version] $Version,

        [Parameter(Mandatory=$true)]
        [string] $InstallRoot,

        [Parameter(Mandatory=$true)]
        [string] $ModulePath

    )

    $moduleRoot = $InstallRoot;
    $moduleRoot = [System.IO.Path]::Combine($moduleRoot, $Name);
    $moduleRoot = [System.IO.Path]::Combine($moduleRoot, $Version);

    if( -not [System.IO.Directory]::Exists($moduleRoot) )
    {

        if( -not [System.IO.Directory]::Exists($InstallRoot) )
        {
            [void] [System.IO.Directory]::CreateDirectory($InstallRoot);
        }

        #Save-Module -Name $Name -Path $InstallRoot -RequiredVersion $Version;

        $downloadUri = "https://www.powershellgallery.com/api/v2/package/$Name/$Version";
        $webResponse = Invoke-WebRequest $downloadUri;
	$nupkgBytes  = $webResponse.Content;

        $nupkgFilename = [System.IO.Path]::Combine($InstallRoot, "$($Name.ToLowerInvariant()).$Version.zip");

	[System.IO.File]::WriteAllBytes($nupkgFilename, $nupkgBytes);

        Expand-Archive -LiteralPath $nupkgFilename -DestinationPath $moduleRoot;

    }

    $module = [System.IO.Path]::Combine($moduleRoot, $ModulePath);

    Import-Module -Name $module -ErrorAction "Stop";

}
