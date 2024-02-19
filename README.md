# SRB2-FLBot
An interpretation of Bot Code for SRB2.

## How to build
- [Install MSYS2](https://www.msys2.org/)
- Install the zip package in MSYS2 using `pacman -S zip`
- You can build the pk3 by running build.sh in the msys2 shell
- Optional: Create a batch file that runs build.sh. (Make sure the directory to msys2 is correct on your machine)
`C:\msys64\msys2_shell.cmd -mingw32 -here build.sh`
- Optional: Create a batch file that can be used to easily test in-game (Make sure the directory to msys2 is correct on your machine)
`cd "[PATH TO SRB2]"`
`Start "" srb2win.exe -file "[PATH TO THIS REPO]\Z_[NAME]_[VERSIONNUMBER].pk3" -warp 1`

After that, simply run the two batch files in order to quickly run and test the mod. The build script will automatically ignore any zone builder temporary files such as `.dbs`, and it will automatically declare version number variables based on the values in `defaults.sh`!

## About defaults.sh (how to create a release)
In order to make a public release, edit defaults.sh:
- PK3_FLAGS_DEF 		Sets the filename prefix
- PK3_VERSION_DEF		major version number
- PK3_SUBVERSION_DEF	minor version number
- FOLDER_NAME_DEF		Defines the root folder for building
