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

FILE_NAME=$(basename "$FILE_PATH")
GAME_NAME=$(basename -s .love "$FILE_PATH")
LOWERCASE=$(echo "$GAME_NAME" | tr '[:upper:]' '[:lower:]')
PACKAGE_NAME=${LOWERCASE// /_}

echo "Enabling extended globs..."
shopt -s extglob

echo "Creating build folder..."
mkdir -p ./build

echo "Building $GAME_NAME for win32..."
cd love-0.10.2-win32
cat love.exe "$FILE_PATH" > "${GAME_NAME}.exe"
zip -q "build.zip" * -x "love.exe"
mv "build.zip" "../build/${PACKAGE_NAME}_love_x86.zip"
rm "${GAME_NAME}.exe"
cd ..

echo "Building $GAME_NAME for win64..."
cd love-0.10.2-win64
cat love.exe "$FILE_PATH" > "${GAME_NAME}.exe"
zip -q "build.zip" * -x "love.exe"
mv "build.zip" "../build/${PACKAGE_NAME}_love_x64.zip"
rm "${GAME_NAME}.exe"
cd ..

echo "Build completed."
exit 0

#echo "file path: $FILE_PATH"
#echo "file name: $FILE_NAME"
#echo "game name: $GAME_NAME"
#echo "package name: $PACKAGE_NAME"