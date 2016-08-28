# sigverse-setup

## What is this?
Some scripts to help ease the setup and configuration of SIGVerse-related projects.

For Windows, the emphasis is on setting everything up to build and run [SIGViewer](https://github.com/noirb/sigverse-SIGViewer) and the Windows side of various [Plugins](https://github.com/noirb/sigverse-plugin).

For Linux, the emphasis is on setting everything up to build and run [SIGServer](https://github.com/noirb/sigverse-SIGServer) and the Linux side of various [Plugins](https://github.com/noirb/sigverse-plugin).

## Why should I use this?
SIGVerse is a small ecosystem of interdependent components, some of which have a long list of dependencies which can make getting everything up and running somewhat difficult.

This project contains a collection of scripts which will automate as much of the process of obtaining and configuring these dependencies as possible. The scripts will also set up a build and working environment for you which is common across all the sigverse components, so once you're set up everything should be just fine.

## How do I use this?
See the README files in the directory matching your platform for detailed instructions.

As a general note, you should be starting with a sane build environment for C++ development. The scripts will not set up basic tools like Git or CMake, and you should ensure you have these installed before you start (an exact list for each platform is provided in their respective READMEs, though).
