# SIGVerse-Setup/Linux
======================

## Overview
The scripts here will set up and configure the necessary dependencies to build and run [SIGServer](https://github.com/noirb/sigverse-SIGServer) and, optionally, custom controllers (including those in the [Plugins](https://github.com/noirb/sigverse-plugin) repo).

## Instructions
1. Create a directory in which you want to store all of your SIGVerse projects
2. From that directory, run the `setup.sh` script. Specify the argument `complete` if you want to build everything necessary for custom controllers in addition to the server itself.
3. You may be prompted for a password in order to apt-get install some dependencies, and you will need to click through the Xj3D GUI installer
4. Done! :D

For example:
```bash
~$ mkdir sigverse && cd sigverse
~$ git clone https://github.com/noirb/sigverse-setup.git
~$ ./sigverse-setup/Linux/setup.sh complete
```

The `setup.sh` script will:

1. Download and install the dependencies SIGServer relies on
2. Clone SIGServer into the current directory, then build and install it.
3. Update your .bashrc to put SIGServer's bin directory in your PATH, and set an environment variable used by many SIGVerse scripts
4. If you ran `setup.sh complete`, it will also clone the [Plugins](https://github.com/noirb/sigverse-plugin) project and build the `sigplugin` library, which is necessary for building any custom controllers, and it will also copy the shape files from the [model](https://github.com/SIGVerse/model) repo into the SIGServer installation directory, so these shapes can be used in your custom worlds and controllers.

## Notes
The setup script will currently only configure SIGServer with the default settings. This should be fine for most people, but you should also be aware that it will install SIGServer into `~/sigverse-2.3.x`

It should also be noted that this script was developed with Ubuntu in mind, and it may be possible that some things need to be changed for other distributions (e.g. the names of the packages installed by apt-get).
