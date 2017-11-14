#!/bin/bash

FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$5-$6.zip
DATE=$(date +"%Y/%m/%d %H:%M:%S")

echo "Download sourcemod..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Set compiler env..."
chmod +x addons/sourcemod/scripting/spcomp

echo "Set version info..."
for file in core.sp
do
    sed -i "s%<commit_num>%$COUNT%g" $file > output.txt
    sed -i "s%<commit_date>%$DATE%g" $file > output.txt
    rm output.txt
done

echo "Prepare files..."
mkdir addons/sourcemod/scripting/core
cp -r core/* addons/sourcemod/scripting
cp include/* addons/sourcemod/scripting/include
cp core.sp addons/sourcemod/scripting

echo "Compiling..."
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/core.sp

if [ ! -f "core.smx" ]; then
    echo "Compile core failed!"
    exit 1;
fi

echo "Compress files..."
zip -9rq $FILE core.smx core.sp core include LICENSE

echo "Upload files..."
lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O Core/$1/ $FILE"

if [ "$1" = "1.8" ]; then
    echo "Upload RAW..."
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O Core/Raw/ core.smx"
fi
