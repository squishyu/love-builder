# Love Builder
### Love2D packaging script

This script generates zip files containing your packaged game for Windows, Linux and MacOS.
Currently the script comes included with Love2D 0.10.2, however you can supply your own Love versions.

#### Supplying your own Love version
For Windows, you can get the binaries [here](https://github.com/love2d/love/releases)

For Linux, check out the [wiki](https://love2d.org/wiki/Game_Distribution)

For MacOS get your preffered version [here](https://github.com/love2d/love/releases)

## Usage

#### Make sure to make script executable

```
chmod +x build.sh
```

#### Run the script

```
./build.sh <path_to_love_file>
```
or
```
./build.sh <path_to_love_file> [path_to_icon]
```

#### Enjoy

Archives get put into a build folder.

## Notes

You can supply your own **_appimagetool_** and **_AppRun_** file.

**_appimagetool_** needs be placed in a directory named `appimagetool` or
be installed and accessible from PATH.
The **_AppRun_** file needs to be placed at the root of the repository.

If any of these files are missing, they get downloaded from the _AppImageKit_
repository.

#### Icons

Sure was a pain. To change icons of a *.exe* a Windows program called *Resource Hacker* is needed, which requires *Wine* to run on Linux. Before the icon can be changed, *ImageMagick* needs to convert the *.png* you supplied to a *.ico* file.

My tool does all of that, just make sure you have **_Wine_** installed.

## TODO

- ~~Add Linux support (Maybe even MacOS)~~
- ~~Allow for different versions of Love2D~~

## Links

Love2D: [https://love2d.org](https://love2d.org)

AppImageKit: [https://github.com/AppImage/AppImageKit](https://github.com/AppImage/AppImageKit)

Resource Hacher: [http://www.angusj.com/resourcehacker](http://www.angusj.com/resourcehacker)

ImageMagick: [https://imagemagick.org/index.php](https://imagemagick.org/index.php)

Wine: [https://www.winehq.org](https://www.winehq.org/)
