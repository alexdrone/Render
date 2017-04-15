#!/bin/bash

cd bin
rm -rf *.framework
rm -rf *.dSYM
cd ..
rm -rf .build_temp
mkdir .build_temp
cd .build_temp
echo "github \"alexdrone/Render\" \"master\"" >> Cartfile
carthage update
mv Carthage/Build/iOS/*.framework ../bin/
mv Carthage/Build/iOS/*.dSYM ../bin/
cd ..
rm -rf .build_temp
cd bin
