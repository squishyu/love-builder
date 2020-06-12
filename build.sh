#!/bin/bash

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <path_to_love_file> [path_to_icon_file]"
	exit 0
fi

FILE_PATH="$1"
ICON_PATH="$2"

if ! test -f "$FILE_PATH"; then
	echo "[${FILE_PATH}] - File not found"
	exit 1
fi

if ! test -d "./love-win32"; then
	echo "Missing love folder at [./love-win32]"
	exit 1
fi

if ! test -d "./love-win64"; then
	echo "Missing love folder at [./love-win64]"
	exit 1
fi

if ! test -d "./AppDir"; then
	echo "Missing AppDir structure"
	exit 1
fi

# Icon file

ICON_FILE_NAME=$(basename "$ICON_PATH")
ICON_FILE_EXTENSION=${ICON_FILE_NAME##*.}
ICON_FILE_NO_EXTENSION=$(basename -s ".$ICON_FILE_EXTENSION" "$ICON_PATH")

if test -f "$ICON_PATH"; then
	if [[ "$ICON_FILE_EXTENSION" != "png" ]]; then
		echo "[${ICON_PATH}] - Please supply the icon as a .png"
		exit 1
	fi

	if [[ "$ICON_PATH" != /* ]]; then
		echo "Icon file path relative."

		ICON_PREFIX="../"
	fi

	ICON_FILE_SUPPLIED=1
elif ! [ -z $ICON_PATH ]; then
	echo "[${ICON_PATH}] - File not found"
fi

# Love file

LOVE_FILE_NAME=$(basename "$FILE_PATH")
LOVE_FILE_EXTENSION=${LOVE_FILE_NAME##*.}
GAME_NAME=$(basename -s ".$LOVE_FILE_EXTENSION" "$FILE_PATH")
LOWERCASE=$(echo "$GAME_NAME" | tr '[:upper:]' '[:lower:]')
PACKAGE_NAME=${LOWERCASE// /_}

if [ "$LOVE_FILE_EXTENSION" != "love" ]; then
	echo "[${FILE_PATH}] - Supplied file isn't a .love file."
	exit 1
fi

if [[ "$FILE_PATH" != /* ]]; then
	echo "Love file path relative."

	LOVE_PREFIX="../"
fi

# Colors

RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
ORANGE="\033[0;33m"
NC="\033[0m"

# Downloading

download_fail() {
	echo -e "${RED}Download failed. If this shouldn't happen please create an issue at ${BLUE}[https://github.com/squishyu/love-builder]${NC}"
}

download() {
	LINK="$1"
	OUTPUT="$2"
	FILE_NAME=$(basename "$LINK")

	echo "Attempting to download $FILE_NAME..."

	if command -v wget > /dev/null; then
		wget -q --spider http://google.com &> /dev/null
	else
		nc -zw1 google.com 443 &> /dev/null
	fi

	if ! [ $? -eq 0 ]; then
		echo -e "${RED}Internet connection not available.${NC}"
		download_fail
		SUCCESS=0
		return 0
	fi

	echo "Creating download folder..."
	mkdir -p "$OUTPUT"

	echo -e "Downloading from ${BLUE}[${LINK}]...${NC}"

	if command -v wget > /dev/null; then
		if ! wget -q -P "$OUTPUT" "$LINK"; then
			download_fail
			SUCCESS=0
			return 0
		fi
	elif command -v curl > /dev/null; then
		if ! curl -L -s -k "$LINK" --output "${OUTPUT}/$FILE_NAME"; then
			download_fail
			SUCCESS=0
			return 0
		fi
	else
		echo -e "${RED}Download failed. Please make sure you have curl or wget installed.${NC}"
		SUCCESS=0
		return 0
	fi

	echo -e "${GREEN}Download successful.${NC}"
	SUCCESS=1
	return 0
}

# Building

BUILDS=0
BUILDS_ALL=3

echo "Enabling extended globs..."
shopt -s extglob

wine_check() {
	echo -e "Checking for ${RED}Wine${NC}..."

	if command -v wine > /dev/null; then
		if [[ "$WINEARCH" != "win32" ]]; then
			echo -e "${ORANGE}If you receive errors while changing .exe icons, please remove ${NC}~/.wine ${ORANGE}folder and try again."
		fi

		WINE_COMMAND="wine"
		export WINEARCH=win32
	elif command -v wine32 > /dev/null; then
		WINE_COMMAND="wine32"
	fi

	if [ -z ${WINE_COMMAND} ]; then
		echo -e "${ORANGE}Please install ${RED}Wine ${ORANGE}if you want to add game icons to your Windows executables.${NC}"
	else
		echo -e "${GREEN}Wine installed.${NC}"
	fi
}

resource_hacker_check() {
	RH_ADDRESS="http://www.angusj.com/resourcehacker/resource_hacker.zip"
	RH_DOWNLOAD_PATH="resource_hacker"

	echo "Checking for Resource Hacker..."

	if [ -z ${WINE_COMMAND} ]; then
		echo "No Wine, skipping..."
	else
		if test -d resource_hacker; then
			if test -f resource_hacker/ResourceHacker.exe; then
				echo -e "${GREEN}Resource Hacker found.${NC}"
				RH_FOUND=1
			else
				echo -e "${ORANGE}Invalid resource_hacker folder, please remove it and re-run script to fix this.${NC}"
			fi
		else
			echo -e "${ORANGE}Resource Hacker missing.${NC}"
			download "$RH_ADDRESS" "$RH_DOWNLOAD_PATH"

			if [[ "$SUCCESS" == 1 ]]; then
				echo "Extracting Resource Hacker..."
				cd resource_hacker
				unzip -qq resource_hacker.zip
				rm -f resource_hacker.zip
				cd ..

				echo -e "${GREEN}Resource Hacker found.${NC}"
				RH_FOUND=1
			else
				echo -e "${ORANGE}Oh well... :c${NC}"
			fi
		fi
	fi
}

magick_check() {
	IM_ADDRESS="https://imagemagick.org/download/binaries/magick"
	IM_DOWNLOAD_PATH="magick"

	echo "Checking for ImageMagick..."

	if test -d magick; then
		if test -f magick/magick; then
			echo -e "${GREEN}ImageMagick found.${NC}"
			IM_FOUND=1
		else
			echo -e "${ORANGE}Invalid magick folder, please remove it and re-run the script to fix this.${NC}"
		fi
	else
		echo -e "${ORANGE}ImageMagick missing.${NC}"
		download "$IM_ADDRESS" "$IM_DOWNLOAD_PATH"

		if [[ "$SUCCESS" == 1 ]]; then
			chmod +x magick/magick

			echo -e "${GREEN}ImageMagick found.${NC}"
			IM_FOUND=1
		else
			echo -e "${ORANGE}ono${NC}"
		fi
	fi
}

change_icon() {
	if [[ "$ICON_FILE_SUPPLIED" == 1 ]] && [[ "$RH_FOUND" == 1 ]] && [[ "$IM_FOUND" == 1 ]]; then
		echo "Converting icon from .png to .ico..."
		cp "${ICON_PREFIX}${ICON_PATH}" .
		../magick/magick convert "${ICON_FILE_NAME}" -resize 256x256 -colors 256 -background transparent "${ICON_FILE_NO_EXTENSION}.ico"

		echo "Changing .exe icon..."

		"$WINE_COMMAND" ../resource_hacker/ResourceHacker.exe -open "${GAME_NAME}.exe" -save "${GAME_NAME}.exe" -action addskip -res "${ICON_FILE_NO_EXTENSION}.ico" -mask ICONGROUP, MAINICON, 0

		rm -f "${ICON_FILE_NAME}"
		rm -f "${ICON_FILE_NO_EXTENSION}.ico"
		echo -e "${GREEN}Changed executable icon.${NC}"
	fi
}

add_apprun() {
	echo "Adding AppRun..."
	cp ../AppRun .
	chmod +x AppRun
}

build_windows() {
	ARCH="$1"

	if [[ "$ARCH" == "x86" ]]; then
		ARCH_BITS=32
	else
		ARCH_BITS=64
	fi

	echo -e "${PURPLE}Building $GAME_NAME for win${ARCH_BITS}...${NC}"
	cd "love-win${ARCH_BITS}"

	echo "Creating executable..."	
	cat love.exe "${LOVE_PREFIX}$FILE_PATH" > "${GAME_NAME}.exe"

	change_icon

	echo "Compressing..."
	zip -q "build.zip" * -x "love.exe"
	echo -e "${GREEN}Moving package to build folder...${NC}"
	mv "build.zip" "../build/${PACKAGE_NAME}_win_${ARCH}.zip"
	echo "Cleaning..."
	rm "${GAME_NAME}.exe"
	cd ..
	((BUILDS++))
}

build_linux() {
	echo -e "${PURPLE}Building $GAME_NAME for Linux (AppImage)...${NC}"
	cd AppDir

	echo "Adding icon..."
	if [[ "$ICON_FILE_SUPPLIED" == 1 ]]; then
		cp "${ICON_PREFIX}${ICON_PATH}" .
		cp "${ICON_PREFIX}${ICON_PATH}" usr/share/icons/hicolor/256x256
		ICON_NAME="$ICON_FILE_NO_EXTENSION"
	else
		cp ../love.png .
		cp ../love.png usr/share/icons/hicolor/256x256
		ICON_NAME="love"
	fi

	echo "Creating .desktop file..."
	DESKTOP=$(cat <<-END
	[Desktop Entry]
	Exec=run_game "$LOVE_FILE_NAME"
	Icon=$ICON_NAME
	Name=$GAME_NAME
	Terminal=false
	Type=Application
	X-AppImage-Name=$GAME_NAME
	Categories=Game;
	END
	)
	echo "$DESKTOP" >> "${GAME_NAME}.desktop"

	echo "Adding .love file..."
	cp "${LOVE_PREFIX}$FILE_PATH" usr/bin

	echo "Checking for AppRun..."
	APPRUN_ADDRESS="https://github.com/AppImage/AppImageKit/releases/download/12/AppRun-x86_64"
	APPRUN_DOWNLOAD_PATH=".."

	if ! test -f ../AppRun; then
		download "$APPRUN_ADDRESS" "$APPRUN_DOWNLOAD_PATH"

		if [[ "$SUCCESS" == 1 ]]; then
			mv ../AppRun-x86_64 ../AppRun
			add_apprun
		else
			echo -e "${RED}Missing AppRun.${NC}"
		fi
	else
		add_apprun
	fi

	echo "Checking for appimagetool..."
	AIT_ADDRESS="https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage"
	AIT_DOWNLOAD_PATH="../appimagetool"

	if ! command -v appimagetool > /dev/null; then
		if ! test -d ../appimagetool; then		
		    download "$AIT_ADDRESS" "$AIT_DOWNLOAD_PATH"

		    if [[ "$SUCCESS" == 1 ]]; then
		    	echo "Making appimagetool executable..."
		    	chmod +x ../appimagetool/appimagetool-x86_64.AppImage

		    	echo "Creating AppImage package..."
		    	../appimagetool/appimagetool-x86_64.AppImage . &> /dev/null
		    else
		    	echo -e "${RED}Missing appimagetool.${NC}"
		    	echo -e "${RED}AppImage build failed.${NC}"
		    fi
		else
			if test -f ../appimagetool/*.AppImage; then
				echo "Creating AppImage package..."
				../appimagetool/*.AppImage . &> /dev/null
			else
				echo -e "${RED}Missing appimagetool. Removing empty folder...${NC}"
				rm -r ../appimagetool
				echo -e "${RED}Please try running the script again.${NC}"
			    echo -e "${RED}AppImage build failed.${NC}"
			fi
		fi
	else
		echo "Creating AppImage package..."
		appimagetool . &> /dev/null
	fi

	if test -f *.AppImage; then
		echo -e "${GREEN}Moving package to build folder...${NC}"
		
		for f in *.AppImage; do
			[ -f "$f" ] || break

			NO_EXTENSION=$(basename -s .AppImage "$f")
			LOWERCASE=$(echo "$NO_EXTENSION" | tr '[:upper:]' '[:lower:]')
			FILE_NAME="${LOWERCASE//-/_}.AppImage"

			mv "$f" "../build/${FILE_NAME}"
		done

		((BUILDS++))
	fi

	echo "Cleaning..."
	rm -f !("usr")
	rm -f ".DirIcon"
	rm -f usr/bin/*.love
	rm -f usr/share/icons/hicolor/256x256/*
	cd ..
}

echo "Love Builder needs ImageMagick, Wine and ResourceHacker to be able to change icons of .exe files."
echo "If you know of a better way to go about this, feel free to file an issue at"
echo -e "${BLUE}[https://github.com/squishyu/love-builder]${NC}"

wine_check
resource_hacker_check
magick_check

echo "Creating build folder..."
mkdir -p ./build

build_windows "x86"
build_windows "x64"

build_linux

if (( $BUILDS >= $BUILDS_ALL )); then
	echo -e "${GREEN}Builds completed. [${BUILDS}/${BUILDS_ALL}]${NC}"
	exit 0
elif (( $BUILDS > 0 )); then
	echo -e "${ORANGE}Builds partially completed. [${BUILDS}/${BUILDS_ALL}]${NC}"
	exit 0
else
	echo -e "${RED}All builds failed. [${BUILDS}/${BUILDS_ALL}]${NC}"
	exit 1
fi