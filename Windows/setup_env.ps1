param(
        [Parameter(Position=0)]
        [ValidateSet('min','complete')]
        [System.String]$setup = 'min'
)

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
# The root directory of the whole project
$projectRoot = $PWD.Path

# Whether to use git to clone SIGVerse projects
# Set to True if git can be found, and will prefer cloning over downloading .zips
$useGit = $false

# A directory to store temporary downloaded files
$tmp_dir = "$projectRoot\setup_tmp"
if ( !(Test-Path $tmp_dir) ) {
    new-item $tmp_dir -type directory
}

# The root directory to store non-SIGVerse dependencies in
$projectDepsRoot = "$projectRoot\extern"
if ( !(Test-Path $projectDepsRoot) ) {
    new-item $projectDepsRoot -type directory
}

# environment variables used to build the project
$build_vars = @{
    "OGRE_SDK"             = "";
    "GLEW_ROOT_PATH"       = "";
    "CEGUI_ROOT_PATH"      = "";
    "CEGUI_DEPS_ROOT"      = "";
    "LIBSSH2_ROOT_PATH"    = "";
    "OPENSSL_ROOT_DIR"     = "";
    "X3D_ROOT_PATH"        = "";
    "SIGSERVICE_ROOT_PATH" = "";
    "BOOST_ROOT"           = "";
    "FFMPEG_DEV_ROOT"      = "";
    "FFMPEG_SHARED_ROOT"   = "";
    "LIBOVR_ROOT_PATH"     = "";
    "OPENVR_ROOT_PATH"     = "";
    "VS_TOOLS_PATH"        = "";
}

if ($setup -eq 'complete') {
    $build_vars.Add("OPENCV_ROOT",      "");
    $build_vars.Add("PLUGIN_ROOT_PATH", "");
    $build_vars.Add("NEURON_SDK_ROOT",  "");
}

# These are used as an argument to CMake when generating project files
$vsVersionNames = @{
    "VS14" = "Visual Studio 14 2015";
    "VS12" = "Visual Studio 12 2013";
    "VS11" = "Visual Studio 11 2012";
    "VS10" = "Visual Studio 10 2010";
    "VS09" = "Visual Studio 9 2008"
}

# Find installed visual studio versions
$vsEnvVars = @()

foreach ($item in (dir Env:)) {
    if ($item.name -Match "VS[0-9]{1,3}COMNTOOLS") {
        $vsEnvVars = $vsEnvVars + $item
    }
}

# If no VS installation was found, bail
if ($vsEnvVars.length -eq 0) {
    echo 'No valid Version of Visual Studio was detected! Please ensure you have VS 2010 or later installed!'
    echo 'Exiting...'
    exit
}

echo 'Found the following Visual Studio installations:'
$iter = 1
foreach ($item in $vsEnvVars) {
    $shortName = $item.Key.Substring(0,4)
    if ($vsVersionNames.ContainsKey($shortName))
    {
        write-host [ $iter ] : $vsVersionNames[$shortName]
    }
    else
    {
        write-host [ $iter ] : Unknown VS Version: $iter.Key
    }
    $iter++
}

$vsVersion = ""
$vsToolsPath = ""

if ($vsEnvVars.length -gt 1) {
    do{
        $resp = Read-Host -prompt "Select Version (1-$($iter-1))"
        [int]$choice = $null
        [void][int32]::TryParse( $resp, [ref]$choice )
        if ( !$choice -Or $choice -lt 1 -Or $choice -ge $iter)
        {
          write-host "Please enter a number between 1 and $($iter-1)"
        }
        else
        {
            $vsVersion   = $vsVersionnames[$vsEnvVars[$choice-1].Key.Substring(0,4)]
            $vsToolsPath = $vsEnvVars[$choice-1].Value
            write-host "Selected: $vsVersion"
        }
      } until ($vsVersion.length -gt 0 -And $vsToolsPath.length -gt 0)
}
else {
    $vsVersion   = $vsVersionNames[$vsEnvVars[0].Key.Substring(0,4)]
    $vsToolsPath = $vsEnvVars[0].Value
    write-host "Selected: $vsVersion"
}

# if we're using VS 2015 or 2013, OGRE SDK must be manually downloaded...
if ($vsVersion -eq "Visual Studio 14 2015")
{
    write-host "--"
    write-host "Please download the OGRE SDK for your compiler from here: http://ogre3d.org/forums/viewtopic.php?t=69274"
    write-host "And extract it into the directory: $projectDepsRoot\OGRE-SDK-1.9.0-vc140-x86-12.03.2016"
    write-host "--"
    Read-Host "Press enter to continue once this is done..."
    $build_vars.Set_Item("OGRE_SDK", "$projectDepsRoot\OGRE-SDK-1.9.0-vc140-x86-12.03.2016")
}
if ($vsVersion -eq "Visual Studio 12 2013")
{
    write-host "--"
    write-host "Please download the OGRE SDK for your compiler from here: http://ogre3d.org/forums/viewtopic.php?t=69274"
    write-host "And extract it into the directory: $projectDepsRoot\OGRE-SDK-1.9.0-vc120-x86-12.03.2016"
    write-host "--"
    Read-Host "Press enter to continue once this is done..."
    $build_vars.Set_Item("OGRE_SDK", "$projectDepsRoot\OGRE-SDK-1.9.0-vc120-x86-12.03.2016")
}

# Find 7-Zip
$7zPath = ''
foreach ($path in (($Env:path).split(";"))) {
    if ($path -like "*7-Zip*" ) {
        $7zPath = $path
    }
}
# if it wasn't in the PATH, go hunting in program files...
if (!$7zPath) {
    echo "7-Zip not found in PATH. Searching for installation directory."
    if (Test-Path "$Env:ProgramFiles\7-Zip") {
        $7zPath = "$Env:ProgramFiles\7-Zip"
    }
    elseif (Test-Path "${Env:ProgramFiles(x86)}\7-Zip") {
        $7zPath = "${Env:ProgramFiles(x86)}\7-Zip"
    }
    # if it wasn't found, ask the user for a path in case they have a portable copy
    else {
        echo "ERROR: Could not find 7-Zip!"
        echo "Please enter the path to your 7-Zip directory (ctrl+C to cancel)"
        $7zPath = Read-Host -prompt "7-Zip Path"
    }
}
$7zX = "& ""$7zPath\7z.exe"" x -y"

# Find CMake
$cmakePath = ''
foreach ($path in (($Env:path).split(";"))) {
    if ($path -like "*CMake*" ) {
        $cmakePath = $path
    }
}
if (!$cmakePath) {
    echo "CMake not found in PATH. Searching for installation directory."
    foreach ($path in (dir ${Env:ProgramFiles(x86)})) {
        if ($path -like "*CMake*") {
            $cmakePath = "${Env:ProgramFiles(x86)}\$path\bin"
        }
    }
    foreach ($path in (dir $Env:ProgramFiles)) {
        if ($path -like "*CMake*") {
            $cmakePath = "$($Env:ProgramFiles)\$path\bin"
        }
    }
}
if (!$cmakePath) {
    echo "ERROR: Could not find CMake!"
    echo "Please enter the path to your CMake installation directory (ctrl+C to cancel)"
    $cmakePath = Read-Host -prompt "CMake Path"
}
$cmake = """$cmakePath\cmake.exe"""

# Find Git
$gitPath = ''
foreach ($path in (($Env:path).split(";"))) {
    if ($path -like "*git*" ) {
        $gitPath = "$path\git.exe"
        $useGit = $true
    }
}

$build_vars.Set_Item("VS_TOOLS_PATH", $vsToolsPath)

echo ""
echo ""
echo "Current working directory: $projectRoot"
echo "========================================================="
echo "    Setup type:                          $setup"
echo "    Temporary files will be copied to:   $tmp_dir"
echo "    SIGVerse projects will be set up in: $projectRoot"
echo "    Dependencies will be set up in:      $projectDepsRoot"
echo "    Visual Studio:"
echo "                  Version: $vsVersion"
echo "                  Tools:   $($build_vars.Get_Item(""VS_TOOLS_PATH""))"
echo "    7-Zip Directory:                     $7zPath"
echo "    CMake Directory:                     $cmakePath"
echo "    Use Git for SIGVerse projects:       $useGit"
if ($useGit) {
echo "    Git Path:                            $gitPath"
}
echo "========================================================="

if ( !((Read-Host -Prompt "Proceed with this configuration? (y/n)").ToLower().StartsWith("y")) ) {
    exit
}

# Locations to download dependencies from
    # SIGVERSE Projects
$SIGViewer_www  = "https://github.com/noirb/sigverse-SIGViewer/archive/master.zip"
$SIGViewer_git  = "https://github.com/noirb/sigverse-SIGViewer.git"
$SIGService_www = "https://github.com/noirb/sigverse-SIGService/archive/master.zip"
$SIGService_git = "https://github.com/noirb/sigverse-SIGService.git"
$X3D_www        = "https://github.com/noirb/sigverse-x3d/archive/master.zip"
$X3D_git        = "https://github.com/noirb/sigverse-x3d.git"
$SIGPlugin_www  = "https://github.com/noirb/sigverse-plugin/archive/master.zip"
$SIGPlugin_git  = "https://github.com/noirb/sigverse-plugin.git"

    # EXTERNAL DEPENDENCIES
$CEGUI_www      = "http://prdownloads.sourceforge.net/crayzedsgui/cegui-0.8.7.zip"
$CEGUI_deps_www = "http://prdownloads.sourceforge.net/crayzedsgui/cegui-deps-0.8.x-src.zip"
$libSSH2_www    = "https://www.libssh2.org/download/libssh2-1.7.0.tar.gz"
                  # OpenSSL rehosted here due to google code being discontinued. Original URL:  "https://openssl-for-windows.googlecode.com/files/openssl-0.9.8k_WIN32.zip"
$openSSL_www    = "http://noirbear.com/tools/openssl-0.9.8k_WIN32.zip"
$boost_www      = "http://downloads.sourceforge.net/project/boost/boost/1.61.0/boost_1_61_0.zip"
$libovr_www     = "https://static.oculus.com/sdk-downloads/1.7.0/Public/1470946240/ovr_sdk_win_1.7.0_public.zip"
$openvr_www     = "https://github.com/ValveSoftware/openvr/archive/master.zip"
$glew_www       = "http://downloads.sourceforge.net/project/glew/glew/2.0.0/glew-2.0.0-win32.zip"
$ffmpeg_sha_www = "https://ffmpeg.zeranoe.com/builds/win32/shared/ffmpeg-20160912-bc7066f-win32-shared.zip"
$ffmpeg_dev_www = "https://ffmpeg.zeranoe.com/builds/win32/dev/ffmpeg-20160912-bc7066f-win32-dev.zip"

    # OPTIONAL DEPENDENCIES (used by plugins)
$opencv_www     = "http://downloads.sourceforge.net/project/opencvlibrary/opencv-win/2.4.13/opencv-2.4.13.exe"
$neuron_sdk_www = "https://neuronmocap.com/sites/default/files/software/NeuronDataReader%20SDK%20b15.zip"

# set download URL for Ogre only if we're using VS 2010 or 2012
if ($vsVersion -eq "Visual Studio 11 2012")
{
	$Ogre_SDK_www   = "http://downloads.sourceforge.net/project/ogre/ogre/1.9/1.9/OgreSDK_vc11_v1-9-0.exe"
}
if ($vsVersion -eq "Visual Studio 10 2010")
{
	$Ogre_SDK_www   = "http://downloads.sourceforge.net/project/ogre/ogre/1.9/1.9/OgreSDK_vc10_v1-9-0.exe"
}

function doDownload
{
    param( [string]$url, [string]$destDir, [string]$destFile, [System.Net.WebClient]$wc )
    
    if ( Test-Path "$destDir\$destFile" ) {
        $conf = Read-Host -Prompt "An existing $destFile was found! Download a fresh copy? (y/n)"
        if ( $conf.ToLower().StartsWith("y") ) {
            echo "Downloading $destFile..."
            $wc.DownloadFile($url, "$destDir\$destFile");
        }
    }
    else {
        echo "Downloading $destFile..."
        $wc.DownloadFile($url, "$destDir\$destFile");
    }
}

function doClone
{
    param( [string]$url, [string]$destDir, [string]$git )
    
    if ( Test-Path $destDir ) {
        $conf = Read-Host -Prompt "An existing $destDir was found! Delete and clone again from scratch? (y/n)"
        if ( $conf.ToLower().Startswith("y") ) {
            echo "Deleting $destDir..."
            remove-item $destDir -recurse -force
            echo "Cloning $url into: $destDir..."
            iex "& '$git' clone --recursive $url $destDir"
        }
    }
    else {
        echo "Cloning $url into: $destDir..."
        iex "& '$git' clone --recursive $url $destDir"
    }
}

function doExtract
{
    param( [string]$file, [string]$destDir, [string]$unzip )

    Write-Host "Extracting '$file' into '$destDir' ..."
    $resultFile = 'none'
    if (!(Test-Path $destDir) )
    {
        new-item $destDir -type directory
    }

    $dir_contents = Get-ChildItem($destDir) | Select-Object FullName

    iex "$unzip -o$destDir $file" | Out-Null
    
    $new_dir_contents = Get-ChildItem($destDir) | Select-Object FullName

    foreach ($item in ($new_dir_contents)) {
        $match_found = $False
        foreach ($olditem in ($dir_contents)) {
            if ( $olditem.FullName -eq $item.FullName ) {
                $match_found = $True
                break;
            }
        }
        
        if ($match_found) {
            continue
        }
        else {
            $resultFile = $item.FullName
            break;
        }
    }
    
    return $resultFile
}

# check for existing code
foreach ($item in (dir $projectRoot)) {
    if ($item.Name.ToLower() -like "*sigviewer*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the SIGViewer source directory? (y/n)"
        if (!($conf.ToLower().StartsWith("y"))) {
            remove-item "$projectRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*sigservice*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the SIGService source directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("SIGSERVICE_ROOT_PATH", "$projectRoot\$($item.Name)")
        } else {
            remove-item "$projectRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*x3d*") {
        echo "Existing directory found: $($item.Name)"
        $conf = read-Host -prompt "Should this be used as-is as the X3D source directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("X3D_ROOT_PATH", "$projectRoot\$($item.Name)")
        } else {
            remove-item "$projectRoot\$($item.Name)" -recurse -force
        }
    }
    elseif (($setup -eq 'complete') -and ($item.Name.ToLower() -like "*plugin*")) {
        echo "Existing directory found: $($item.Name)"
        $conf = read-Host -prompt "Should this be used as-is as the Sigverse Plugin source directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("PLUGIN_ROOT_PATH", "$projectRoot\$($item.Name)")
        } else {
            remove-item "$projectRoot\$($item.Name)" -recurse -force
        }
    }
}
foreach ($item in (dir $projectDepsRoot)) {
    if ($item.Name.ToLower() -like "*ogre*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the Ogre SDK directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("OGRE_SDK", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*cegui-[0-9]*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the CEGUI source directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("CEGUI_ROOT_PATH", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*cegui-dep*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the CEGUI DEPS directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("CEGUI_DEPS_ROOT", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*libssh2*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the libSSH2 directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("LIBSSH2_ROOT_PATH", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*openssl*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the OpenSSL directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("OPENSSL_ROOT_DIR", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*boost*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the Boost source directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("BOOST_ROOT", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*oculussdk*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the Oculus SDK directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("LIBOVR_ROOT_PATH", "$projectDepsRoot\$($item.Name)\LibOVR")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*openvr*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the OpenVR SDK directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("OPENVR_ROOT_PATH", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*glew*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the GLEW root directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("GLEW_ROOT_PATH", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*ffmpeg*dev*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the ffmeg-dev directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("FFMPEG_DEV_ROOT", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif ($item.Name.ToLower() -like "*ffmpeg*shared*") {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the ffmeg-shared directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("FFMPEG_SHARED_ROOT", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif (($setup -eq 'complete') -and ($item.Name.ToLower() -like "*opencv*")) {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the OpenCV source directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("OPENCV_ROOT", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
    elseif (($setup -eq 'complete') -and ($item.Name.ToLower() -like "*NeuronDataReader*")) {
        echo "Existing directory found: $($item.Name)"
        $conf = Read-Host -prompt "Should this be used as-is as the Perception Neuron DataReader SDK directory? (y/n)"
        if (($conf.ToLower().StartsWith("y"))) {
            $build_vars.Set_Item("NEURON_SDK_ROOT", "$projectDepsRoot\$($item.Name)")
        } else {
            remove-item "$projectDepsRoot\$($item.Name)" -recurse -force
        }
    }
}


$net = new-object System.Net.WebClient

# download all essential dependencies
if ($useGit)
{
    doClone -url $SIGViewer_git  -destDir "$projectRoot\SIGViewer"  -git $gitPath
    doClone -url $SIGService_git -destDir "$projectRoot\SIGService" -git $gitPath
    $build_vars.Set_Item("SIGSERVICE_ROOT_PATH", "$projectRoot\SIGService")
    doClone -url $X3D_git        -destDir "$projectRoot\X3D"        -git $gitPath
    $build_vars.Set_Item("X3D_ROOT_PATH", "$projectRoot\X3D")
}
else
{
    doDownload -url $SIGViewer_www  -destFile "sigviewer.zip"  -destDir $tmp_dir -wc $net
    doDownload -url $SIGService_www -destFile "sigservice.zip" -destDir $tmp_dir -wc $net
    doDownload -url $X3D_www        -destFile "x3d.zip"        -destDir $tmp_dir -wc $net
}

doDownload -url $CEGUI_www      -destFile $CEGUI_www.Substring($CEGUI_www.LastIndexOf("/") + 1)           -destDir $tmp_dir -wc $net
doDownload -url $CEGUI_deps_www -destFile $CEGUI_deps_www.Substring($CEGUI_deps_www.LastIndexOf("/") + 1) -destDir $tmp_dir -wc $net
doDownload -url $libSSH2_www    -destFile $libSSH2_www.Substring($libSSH2_www.LastIndexOf("/") + 1)       -destDir $tmp_dir -wc $net
doDownload -url $openSSL_www    -destFile $openSSL_www.Substring($openSSL_www.LastIndexOf("/") + 1)       -destDir $tmp_dir -wc $net
doDownload -url $boost_www      -destFile $boost_www.Substring($boost_www.LastIndexOf("/") + 1)           -destDir $tmp_dir -wc $net
doDownload -url $libovr_www     -destFile $libovr_www.Substring($libovr_www.LastIndexOf("/") + 1)         -destDir $tmp_dir -wc $net
doDownload -url $openvr_www     -destFile "openvr_sdk.zip"                                                -destDir $tmp_dir -wc $net
doDownload -url $glew_www       -destFile $glew_www.Substring($glew_www.LastIndexOf("/") + 1)             -destDir $tmp_dir -wc $net
doDownload -url $ffmpeg_sha_www -destFile $ffmpeg_sha_www.Substring($ffmpeg_sha_www.LastIndexOf("/") + 1) -destDir $tmp_dir -wc $net
doDownload -url $ffmpeg_dev_www -destFile $ffmpeg_dev_www.Substring($ffmpeg_dev_www.LastIndexOf("/") + 1) -destDir $tmp_dir -wc $net

# only download Ogre if we're using VS 2012 or earlier
if ($vsVersion -eq "Visual Studio 10 2010" -Or $vsVersion -eq "Visual Studio 11 2012")
{
	doDownload -url $Ogre_SDK_www   -destFile $Ogre_SDK_www.Substring($Ogre_SDK_www.LastIndexOf("/") + 1)     -destDir $tmp_dir -wc $net
}

# download additional dependencies if complete build was specified
if ($setup -eq 'complete') {
    if ($useGit) {
        doClone -url $SIGPlugin_git -destDir "$projectRoot\SIGPlugin" -git $gitPath
        $build_vars.Set_Item("PLUGIN_ROOT_PATH", "$projectRoot\SIGPlugin")
    }
    else {
        doDownload -url $SIGPlugin_www  -destFile "sigPlugin.zip"                                             -destDir $tmp_dir -wc $net
    }
    doDownload -url $opencv_www     -destFile $opencv_www.Substring($opencv_www.LastIndexOf("/") + 1)         -destDir $tmp_dir -wc $net
    doDownload -url $neuron_sdk_www -destFile $neuron_sdk_www.Substring($neuron_sdk_www.LastIndexOf("/") + 1) -destDir $tmp_dir -wc $net
}




# extract archives for any code not found above
if (!($build_vars.Get_Item("SIGSERVICE_ROOT_PATH"))) {
    $path_result = doExtract -file $tmp_dir\sigservice.zip -destDir $projectRoot -unzip $7zX
    $build_vars.Set_Item("SIGSERVICE_ROOT_PATH", $path_result)
}

if (!($build_vars.Get_Item("X3D_ROOT_PATH"))) {
    $path_result = doExtract -file $tmp_dir\x3d.zip -destDir $projectRoot -unzip $7zX
    $build_vars.Set_Item("X3D_ROOT_PATH", $path_result)
}

if (!($build_vars.Get_Item("OGRE_SDK"))) {
    $path_result = doExtract -file $tmp_dir\($Ogre_SDK_www.Substring($Ogre_SDK_www.LastIndexOf("/") + 1)) -destDir $projectDepsRoot -unzip $7zX
    $build_vars.Set_Item("OGRE_SDK", $path_result)
}

if (!($build_vars.Get_Item("CEGUI_ROOT_PATH"))) {
    $path_result = doExtract -file $tmp_dir\$($CEGUI_www.Substring($CEGUI_www.LastIndexOf("/") + 1)) -destDir $projectDepsRoot -unzip $7zX
    $build_vars.Set_Item("CEGUI_ROOT_PATH", $path_result)
}

if (!($build_vars.Get_Item("CEGUI_DEPS_ROOT"))) {
    $path_result = doExtract -file $tmp_dir\$($CEGUI_deps_www.Substring($CEGUI_deps_www.LastIndexOf("/") + 1)) -destDir $projectDepsRoot -unzip $7zX
    $build_vars.Set_Item("CEGUI_DEPS_ROOT", $path_result)
}

if (!($build_vars.Get_Item("GLEW_ROOT_PATH"))) {
    $path_result = doExtract -file $tmp_dir\$($glew_www.Substring($glew_www.LastIndexOf("/") + 1)) -destDir $projectDepsRoot -unzip $7zX
    $build_vars.Set_Item("GLEW_ROOT_PATH", $path_result)
}

if (!($build_vars.Get_Item("FFMPEG_SHARED_ROOT"))) {
    $path_result = doExtract -file $tmp_dir\$($ffmpeg_sha_www.Substring($ffmpeg_sha_www.LastIndexOf("/") + 1)) -destDir $projectDepsRoot -unzip $7zX
    $build_vars.Set_Item("FFMPEG_SHARED_ROOT", $path_result)
}

if (!($build_vars.Get_Item("FFMPEG_DEV_ROOT"))) {
    $path_result = doExtract -file $tmp_dir\$($ffmpeg_dev_www.Substring($ffmpeg_dev_www.LastIndexOf("/") + 1)) -destDir $projectDepsRoot -unzip $7zX
    $build_vars.Set_Item("FFMPEG_DEV_ROOT", $path_result)
}

if (!($build_vars.Get_Item("LIBSSH2_ROOT_PATH"))) {
    $tar_result = doExtract -file $tmp_dir\$($libSSH2_www.Substring($libSSH2_www.LastIndexOf("/") + 1)) -destDir $tmp_dir -unzip $7zX
    $path_result = doExtract -file $tar_result -destDir $projectDepsRoot -unzip $7zX
    remove-item $tar_result
    $build_vars.Set_Item("LIBSSH2_ROOT_PATH", $path_result)
}

if (!($build_vars.Get_Item("OPENSSL_ROOT_DIR"))) {
    $filename = "$($openSSL_www.Substring($openSSL_www.LastIndexOf(""/"") + 1))"
    $dirname = $filename.substring(0, $filename.length-4)
    $path_result = doExtract -file $tmp_dir\$filename -destDir $projectDepsRoot\$dirname -unzip $7zX
    $build_vars.Set_Item("OPENSSL_ROOT_DIR", "$projectDepsRoot\$dirname")
}

if (!($build_vars.Get_Item("BOOST_ROOT"))) {
    $path_result = doExtract -file $tmp_dir\$($boost_www.Substring($boost_www.LastIndexOf("/") + 1)) -destDir $projectDepsRoot -unzip $7zX
    Write-Host "Extracted $boost_dir"
    $build_vars.Set_Item("BOOST_ROOT", $path_result)
}

if (!($build_vars.Get_Item("LIBOVR_ROOT_PATH"))) {
    $path_result = doExtract -file $tmp_dir\$($libovr_www.Substring($libovr_www.LastIndexOf("/") + 1)) -destDir $projectDepsRoot -unzip $7zX
    $build_vars.Set_Item("LIBOVR_ROOT_PATH", "$path_result\LibOVR")
}

if (!($build_vars.Get_Item("OPENVR_ROOT_PATH"))) {
    $path_result = doExtract -file "$tmp_dir\openvr_sdk.zip" -destDir $projectDepsRoot -unzip $7zX
    $build_vars.Set_Item("OPENVR_ROOT_PATH", $path_result)
}

# Extra dependencies for complete build
if ($setup -eq 'complete') {
    if (!($build_vars.Get_Item("PLUGIN_ROOT_PATH"))) {
        $path_result = doExtract -file "$tmp_dir\sigPlugin.zip" -destDir $projectRoot -unzip $7zX
        $build_vars.Set_Item("PLUGIN_ROOT_PATH", $path_result)
    }

    if (!($build_vars.Get_Item("OPENCV_ROOT"))) {
        $path_result = doExtract -file $tmp_dir\$($opencv_www.Substring($opencv_www.LastIndexOf("/") +1)) -destDir $projectDepsRoot -unzip $7zX
        $build_vars.Set_Item("OPENCV_ROOT", $path_result)
    }
    
    if (!($build_vars.Get_Item("NEURON_SDK_ROOT"))) {
        $path_result = doExtract -file $tmp_dir\$($neuron_sdk_www.Substring($neuron_sdk_www.LastIndexOf("/") + 1)) -destDir $projectDepsRoot -unzip $7zX
        $build_vars.Set_Item("NEURON_SDK_ROOT", $path_result)
    }
}

echo ''
echo '=============================='
echo '     BUILD CONFIGURATION      '
echo '=============================='
echo "    Project Root:`t   $projectRoot"
echo "    CMake:       `t   $cmakePath"
foreach ($item in $build_vars.GetEnumerator()) {
    "{0, -3} {1, -22} {2, -80}" -f `
    "", $($item.Name + ":"), $item.Value
}
echo "    Visual Studio:"
echo "                  Version: $vsVersion"
echo "                  Tools:   $($build_vars.Get_Item(""VS_TOOLS_PATH""))"
echo ''
$t = Read-Host "Press Enter to continue (CTRL+C to exit)..."

$dev_script = "$scriptPath\scripts\setenv.bat"

sc $dev_script '' -en ASCII
ac $dev_script '@echo off'
ac $dev_script 'title S I G V E R S E  x86 Release'
ac $dev_script 'rem --------------------------------------------------------'
ac $dev_script 'rem This is a script-generated file! Edit at your own risk!'
ac $dev_script 'rem --------------------------------------------------------'
ac $dev_script "set SIGVERSE_ROOT=""$projectRoot"""
ac $dev_script 'echo Checking for JDK path...'
ac $dev_script "call $scriptPath\scripts\find_jdk.bat"

ac $dev_script "set CMAKE=$cmake"
ac $dev_script "set VS_VERSION=""$vsVersion"""

foreach ($item in $build_vars.GetEnumerator()) {
    ac $dev_script "set $($item.Name)=""$($item.Value)"""
    ac $dev_script "if not exist %$($item.Name)% ("
    ac $dev_script "  echo $($item.Name) directory could not be found: %$($item.Name)%"
    ac $dev_script "  goto error"
    ac $dev_script ")"
}

# Include paths used by VS
ac $dev_script "rem Include Paths:"
ac $dev_script "set SIGBUILD_SIGSERVICE_INC=$($build_vars.Get_Item(""SIGSERVICE_ROOT_PATH""))\Windows\SIGService"
ac $dev_script "set SIGBUILD_X3D_INC=$($build_vars.Get_Item(""X3D_ROOT_PATH""))\parser\cpp\X3DParser"
ac $dev_script "set SIGBUILD_OGRE_INC=$($build_vars.Get_Item(""OGRE_SDK""))\include"
ac $dev_script "set SIGBUILD_BOOST_INC=$($build_vars.Get_Item(""BOOST_ROOT""))"
ac $dev_script "set SIGBUILD_CEGUI_INC=$($build_vars.Get_Item(""CEGUI_ROOT_PATH""))\cegui\include"
ac $dev_script "set SIGBUILD_LIBSSH2_INC=$($build_vars.Get_Item(""LIBSSH2_ROOT_PATH""))\include"
ac $dev_script "set SIGBUILD_OPENSSL_INC=$($build_vars.Get_Item(""OPENSSL_ROOT_DIR""))\include"
ac $dev_script "set SIGBUILD_FFMPEG_INC=$($build_vars.Get_Item(""FFMPEG_DEV_ROOT""))\include"
ac $dev_script "set SIGBUILD_LIBOVR_INC=$($build_vars.Get_Item(""LIBOVR_ROOT_PATH""))\Include;$($build_vars.Get_Item(""LIBOVR_ROOT_PATH""))\LibOVRKernel\Src"
ac $dev_script "set SIGBUILD_OPENVR_INC=$($build_vars.Get_Item(""OPENVR_ROOT_PATH""))\headers"

if ($setup -eq 'complete') {
    ac $dev_script "set SIGBUILD_NEURONDATAREADER_INC=$($build_vars.Get_Item(""NEURON_SDK_ROOT""))\Windows\include"
}

# Lib paths used by VS
ac $dev_script "rem Library Paths:"
ac $dev_script "set SIGBUILD_SIGSERVICE_LIB=$($build_vars.Get_Item(""SIGSERVICE_ROOT_PATH""))\Windows\Release_2010"
ac $dev_script "set SIGBUILD_X3D_LIB=$($build_vars.Get_Item(""X3D_ROOT_PATH""))\parser\cpp\Release"
ac $dev_script "set SIGBUILD_OGRE_LIB=$($build_vars.Get_Item(""OGRE_SDK""))\lib"
ac $dev_script "set SIGBUILD_BOOST_LIB=$($build_vars.Get_Item(""BOOST_ROOT""))\stage\lib"
ac $dev_script "set SIGBUILD_CEGUI_LIB=$($build_vars.Get_Item(""CEGUI_ROOT_PATH""))\lib;$($build_vars.Get_Item(""CEGUI_ROOT_PATH""))\dependencies\lib\static"
ac $dev_script "set SIGBUILD_LIBSSH2_LIB=$($build_vars.Get_Item(""LIBSSH2_ROOT_PATH""))\build\src\Release"
ac $dev_script "set SIGBUILD_OPENSSL_LIB=$($build_vars.Get_Item(""OPENSSL_ROOT_DIR""))\lib"
ac $dev_script "set SIGBUILD_ZLIB_LIB=$($build_vars.Get_Item(""CEGUI_ROOT_PATH""))\dependencies\lib\static"
ac $dev_script "set SIGBUILD_FFMPEG_LIB=$($build_vars.Get_Item(""FFMPEG_DEV_ROOT""))\lib"
ac $dev_script "set SIGBUILD_FFMPEG_SHARED=$($build_vars.Get_Item(""FFMPEG_SHARED_ROOT""))\bin"
ac $dev_script "set SIGBUILD_LIBOVR_LIB=$($build_vars.Get_Item(""LIBOVR_ROOT_PATH""))\Lib\Windows\Win32\Release\VS2015"
ac $dev_script "set SIGBUILD_OPENVR_LIB=$($build_vars.Get_Item(""OPENVR_ROOT_PATH""))\lib\win32"
ac $dev_script "set SIGBUILD_GLEW_LIB=$($build_vars.Get_Item(""GLEW_ROOT_PATH""))\lib\Release\Win32"

if ($setup -eq 'complete') {
    ac $dev_script "set SIGBUILD_NEURONDATAREADER_LIB=$($build_vars.Get_Item(""NEURON_SDK_ROOT""))\Windows\lib\x86"
}

ac $dev_script "call %VS_TOOLS_PATH%\VsDevCmd.bat"

#ac $dev_script 'endlocal'
ac $dev_script 'if errorlevel 0 goto end'

ac $dev_script ':error'
ac $dev_script 'exit /B 1'

ac $dev_script ':end'

ac $dev_script "echo      __        __         _"
ac $dev_script "echo      \ \      / /   ___  ^| ^|   ___    ___    _ __ ___     ___"
ac $dev_script "echo       \ \ /\ / /   / _ \ ^| ^|  / __^|  / _ \  ^| '_ \` _ \   / _ \"
ac $dev_script "echo        \ V  V /   ^|  __/ ^| ^| ^| (__  ^| (_) ^| ^| ^| ^| ^| ^| ^| ^|  __/"
ac $dev_script "echo         \_/\_/     \___^| ^|_^|  \___^|  \___/  ^|_^| ^|_^| ^|_^|  \___^|"
ac $dev_script "echo   _               ____    ___    ____  __     __"
ac $dev_script "echo  ^| ^|_    ___     / ___^|  ^|_ _^|  / ___^| \ \   / /   ___   _ __   ___    ___"
ac $dev_script "echo  ^| __^|  / _ \    \___ \   ^| ^|  ^| ^|  _   \ \ / /   / _ \ ^| '__^| / __^|  / _ \"
ac $dev_script "echo  ^| ^|_  ^| (_) ^|    ___) ^|  ^| ^|  ^| ^|_^| ^|   \ V /   ^|  __/ ^| ^|    \__ \ ^|  __/"
ac $dev_script "echo   \__^|  \___/    ^|____/  ^|___^|  \____^|    \_/     \___^| ^|_^|    ^|___/  \___^|"
ac $dev_script "echo."
ac $dev_script "echo."

# make shortcut to setenv.bat
$WScriptShell = New-Object -ComObject WScript.Shell
$dev_script_shortcut = $WScriptShell.CreateShortcut("$projectRoot\SIGVerse_x86_Release.lnk")
$dev_script_shortcut.TargetPath = $env:ComSpec
$dev_script_shortcut.Arguments = "/K $dev_script"
$dev_script_shortcut.Save()

# Attempt to build all dependencies
cd "$scriptPath\scripts"
cmd /C 'build_boost.bat'
if ( $lastexitcode -ne 0) {
    echo 'ERROR: Boost build failed! Terminating build scripts'
    cd $projectRoot
    exit
}

cmd /C 'build_cegui.bat'
if ( $lastexitcode -ne 0) {
    echo 'ERROR: CEGUI build failed! Terminating build scripts'
    cd $projectRoot
    exit
}

cmd /C 'build_libssh2.bat'
if ( $lastexitcode -ne 0) {
    echo 'ERROR: LIBSSH2 build failed! Terminating build scripts'
    cd $projectRoot
    exit
}

cmd /C 'build_x3d.bat'
if ( $lastexitcode -ne 0) {
    echo 'ERROR: X3D build failed! Terminating build scripts'
    cd $projectRoot
    exit
}

cmd /C 'build_sigservice.bat'
if ( $lastexitcode -ne 0) {
    echo 'ERROR: SIGService build failed! Terminating build scripts'
    cd $projectRoot
    exit
}

if ($setup -eq 'complete') {
    cmd /C 'build_opencv.bat'
    if ( $lastexitcode -ne 0) {
        echo 'ERROR: OpenCV build failed! Terminating build scripts'
        cd $projectRoot
        exit
    }
}

echo ""
echo " ======================= "
echo " SIGVerse SETUP COMPLETE"
echo " ======================= "
echo ""
cd $projectRoot
