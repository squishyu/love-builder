# Love Builder
### Love2D packaging script

This script generates zip files containing your packaged game for Windows and Linux.
Currently the script comes included with Love2D 0.10.2, however you can supply your own Love versions.

For Windows, you can get the binaries from the Love2D website (Link at the bottom).
For Linux, check out the [wiki](https://love2d.org/wiki/Game_Distribution)

## Usage

#### Make sure to make script executable

```
chmod +x build.sh
```

#### Run the script

```
./build.sh <path_to_love_file>
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

## TODO

- ~~Add Linux support~~ (Maybe even MacOS)
- Allow for different versions of Love2D

## Links

Love2D: [https://love2d.org](https://love2d.org)

AppImageKit: [https://github.com/AppImage/AppImageKit](https://github.com/AppImage/AppImageKit)
