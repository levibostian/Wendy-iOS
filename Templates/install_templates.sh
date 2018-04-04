#!/bin/sh
PATH=/bin:/usr/bin:/usr/libexec

FILE_TEMPLATES_DIR="$HOME/Library/Developer/Xcode/Templates/File Templates/Wendy"
mkdir -p "$FILE_TEMPLATES_DIR"

echo "\033[0;33mInstalling Wendy XCode file templates..."
echo "path: $FILE_TEMPLATES_DIR"

for dir in "file_templates/*/"
do
  cp -R ${dir%*/} "$FILE_TEMPLATES_DIR"
done

echo "..."
echo "\033[0;32mDone."
echo "\033[0;37mYou may now go to File > New > File from XCode, find the 'Wendy' section to create files quick and easy for working with Wendy."
