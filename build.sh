#!/bin/bash

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <path_to_love_file>"
	exit 0
fi

FILE_PATH="$1"

if ! test -f "$FILE_PATH"; then
	echo "[$FILE_PATH] - File not found"
	exit 1
fi

if ! test -d "./love-0.10.2-win32"; then
	echo "Missing love folder at [./love-0.10.2-win32]"
	exit 1
fi

if ! test -d "./love-0.10.2-win64"; then
	echo "Missing love folder at [./love-0.10.2-win64]"
	exit 1
fi

# File

FILE_NAME=$(basename "$FILE_PATH")
FILE_EXTENSION=${FILE_NAME##*.}
GAME_NAME=$(basename -s .love "$FILE_PATH")
LOWERCASE=$(echo "$GAME_NAME" | tr '[:upper:]' '[:lower:]')
PACKAGE_NAME=${LOWERCASE// /_}

if [ "$FILE_EXTENSION" != "love" ]; then
	echo "[$FILE_PATH] - Supplied file isn't a .love file."
	exit 1
fi

if [[ "$FILE_PATH" != /* ]]; then
	echo "File path relative."

	PREFIX="../"
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

add_apprun() {
	echo "Adding AppRun..."
	cp ../AppRun AppDir
	chmod +x AppDir/AppRun
}

build_windows() {
	ARCH="$1"

	if [[ "$ARCH" == "x86" ]]; then
		ARCH_BITS=32
	else
		ARCH_BITS=64
	fi

	echo -e "${PURPLE}Building $GAME_NAME for win${ARCH_BITS}...${NC}"
	cd "love-0.10.2-win${ARCH_BITS}"

	echo "Creating executable..."	
	cat love.exe "${PREFIX}$FILE_PATH" > "${GAME_NAME}.exe"
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
	cd love-0.10.2-appimage

	echo "Creating .desktop file..."
	DESKTOP=$(cat <<-END
	[Desktop Entry]
	Exec=run_game "$FILE_NAME"
	Icon=love
	Name=$GAME_NAME
	Terminal=false
	Type=Application
	X-AppImage-Name=$GAME_NAME
	Categories=Game;
	END
	)
	echo "$DESKTOP" >> "AppDir/${GAME_NAME}.desktop"

	echo "Adding icon..."
	cp ../love.png AppDir

	echo "Adding .love file..."
	cp "${PREFIX}$FILE_PATH" AppDir/usr/bin

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

	if ! command -v appimagefool > /dev/null; then
		if ! test -d ../appimagetool; then		
		    download "$AIT_ADDRESS" "$AIT_DOWNLOAD_PATH"

		    if [[ "$SUCCESS" == 1 ]]; then
		    	echo "Making appimagetool executable..."
		    	chmod +x ../appimagetool/appimagetool-x86_64.AppImage

		    	echo "Creating AppImage package..."
		    	../appimagetool/appimagetool-x86_64.AppImage AppDir &> /dev/null
		    else
		    	echo -e "${RED}Missing appimagetool.${NC}"
		    	echo -e "${RED}AppImage build failed.${NC}"
		    fi
		else
			if test -f ../appimagetool/*.AppImage; then
				echo "Creating AppImage package..."
				../appimagetool/*.AppImage AppDir &> /dev/null
			else
				echo -e "${RED}Missing appimagetool. Removing empty folder...${NC}"
				rm -r ../appimagetool
				echo -e "${RED}Please try running the script again.${NC}"
			    echo -e "${RED}AppImage build failed.${NC}"
			fi
		fi
	else
		echo "Creating AppImage package..."
		appimagetool AppDir &> /dev/null
	fi

	if test -f *.AppImage; then
		echo -e "${GREEN}Moving package to build folder...${NC}"
		
		for f in *.AppImage; do
			[ -f "$f" ] || break

			NO_EXTENSION=$(basename "$f")
			LOWERCASE=$(echo "$NO_EXTENSION" | tr '[:upper:]' '[:lower:]')
			FILE_NAME="${LOWERCASE//-/_}.AppImage"

			mv "$f" "../build/${FILE_NAME}"
		done

		((BUILDS++))
	fi

	echo "Cleaning..."
	cd AppDir
	rm -f !("usr")
	rm -f ".DirIcon"
	rm -f usr/bin/*.love
	cd ../..
}

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

#echo "file path: $FILE_PATH"
#echo "file name: $FILE_NAME"
#echo "game name: $GAME_NAME"
#echo "package name: $PACKAGE_NAME"