#!/bin/bash
cd "$(dirname "$0")" || exit 1
echo "Building Splendor Java Project..."

mkdir -p classes

echo "Compiling Java sources..."
javac --release 17 -encoding UTF-8 -d classes -sourcepath src \
src/com/splendor/*.java \
src/com/splendor/config/*.java \
src/com/splendor/controller/*.java \
src/com/splendor/data/*.java \
src/com/splendor/exception/*.java \
src/com/splendor/model/*.java \
src/com/splendor/model/validator/*.java \
src/com/splendor/network/*.java \
src/com/splendor/util/*.java \
src/com/splendor/view/*.java

if [ $? -eq 0 ]; then
    echo "Build successful!"
else
    echo "Build failed!"
    exit 1
fi
