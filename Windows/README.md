# SIGVerse-Setup/Windows
=============

## Overview
The scripts here will set up and configure the dependencies necessary to build and run [SIGViewer](https://github.com/noirb/sigverse-SIGViewer) and, optionally, many of the [exampled Plugins](https://github.com/noirb/sigverse-plugin).

## Dependencies
Before you begin you must install and configure the following:

* Visual Studio 2010 or greater (recommended: [VS 2015](https://www.visualstudio.com/downloads/download-visual-studio-vs))
* [Java JDK](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
* [CMake](https://cmake.org/download/)
* [7-Zip](http://www.7-zip.org/)
* [PowerShell 2.0+](https://msdn.microsoft.com/en-us/powershell/) (should be included by default on Win7+)
* (optional) [Git For Windows](https://git-scm.com/download/win)

## Instructions
1. Create a directory to serve as your "SIGVerse Root". This will be where all of the SIGVerse projects and their respective dependencies live.
2. Launch Powershell and navigate to your SIGVerse Root directory
3. Run the script `setup_env.ps1` from your SIGVerse Root directory. The script takes one argument, either `min` or `complete`. Use `min` if you ONLY want to run SIGViewer and don't plan on using any other SIGVerse components. Use `complete` if you also want the script to setup and configure the dependencies necessary for the [Plugin projects](https://github.com/noirb/sigverse-plugin).

e.g. 

```
PS C:\SIGVerse\> .\sigverse-setup\Windows\setup_env.ps1 complete
```

When the script finishes, you should find a shortcut in your SIGVerse Root directory. This will open a console window with your build environment all set up. Launch Visual Studio from this window to ensure it launches with the correct settings and environment:

To Open Visual Studio:
```
devenv
```

To Open a Specific Project:
```
devenv <path to .sln>

e.g.
devenv .\SIGViewer\SIGViewer.sln
```


## Notes

The script will scan for any installed Visual Studio installations, along with the other dependencies mentioned above, then allow you to confirm that it has everything right before starting.

It will then download (or clone if you have Git installed in your PATH) all the SIGVerse projects and their dependencies and set them up **in the directory you ran the script from**.

Once everything has been downloaded, it will confirm with you the paths to be used in building SIGVerse projects. If everything looks good and you continue, it will then automatically compile any libraries which need to be built.

Finally, it will place a shortcut in your SIGVerse Root directory which you can use any time to launch a console window with the correct build environment to build all your SIGVerse projects. *Use this shortcut whenever opening a Visual Studio project!* After opening the shortcut, run the command `devenv` to open Visual Studio, or `devenv <path to .sln>` to open a specific project.

If you change any of the dependencies (upgrading to a newer version, for example), you should be able to re-run the script from your SIGVerse Root directory without needing to start over from scratch. When it finds an existing directory it recognizes, it will prompt you to either keep and use it or delete it and use a fresh copy the script obtains. **NOTE:** All the (y/n) prompts *default* to **n**!


## Troubleshooting

> When I try to run the setup script I get an error saying, "the execution of scripts is disabled on this system"

Powershell defaults to a policy of not allowing any user-provided scripts to run. To fix this:

1. Run Powershell as Administrator
2. Execute the command: `Set-ExecutionPolicy RemoteSigned`

This setting will apply to all future Powershell sessions. You do not need to run the setup scripts as Administrator (and the recommendation is not to do so).

> When the script is compiling some dependencies, it seems to hang after the build completes

This is an issue with some combinations of Visual Studio and Windows versions. You can work around it in two ways:

1. Launch Visual Studio before you run the setup script and leave it in the background.
2. After a build completes and it appears to hang, kill `vshub.exe` in the task manager.

> I ran the setup script, but when I try to build anything I get lots of missing header and .lib errors

You need to launch Visual Studio from the shortcut placed in your SIGVerse Root directory. Open the shortcut, then in the console window which opens execute:

`devenv`

Or:

`devenv <path to .sln>`

> I get errors when trying to build a Debug version of a project, but not a Release version

Currently the setup script only configures everything for Release builds. Enabling Debug builds requires rebuilding many of the dependencies in debug mode as well. If there's demand, the scripts may be updated to handle both Debug and Release.

## Known Issues
* Only x86 Release builds are supported through these scripts. SIGViewer does not support 64-bit at the moment, but a Debug build environment could be useful.
