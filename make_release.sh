#!/bin/bash
if [ -d .release ]; then rm -r .release; fi
mkdir -p .release/ErrorFilter
cp -r Libs Locales ErrorFilter.* .release/ErrorFilter
version=$(awk 'match($0, /## Version: (v[0-9.]+)/, a) {print a[1]}' ErrorFilter.toc)
cd .release
7z a "ErrorFilter-$version.zip" ErrorFilter
rm -r ErrorFilter