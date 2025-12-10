#!/usr/bin/env bash
#
# Aseprite RPM Build Script (with submodules in the tarball)
#
# This script builds Aseprite from the official GitHub repo and creates an RPM.
# It installs all required packages, clones the repo, initializes submodules,
# adjusts the .spec file, builds, and asks at the end if cleanup should be performed.

set -e

# 1. Install required packages
REQUIRED_PKGS=(git cmake ninja-build gcc-c++ libX11-devel libXcursor-devel libXrandr-devel libXi-devel libXext-devel libXinerama-devel libXfixes-devel libpng-devel libjpeg-turbo-devel zlib-devel freetype-devel fontconfig-devel mesa-libGL-devel curl curl-devel rpm-build harfbuzz-devel pixman-devel lua-devel libwebp-devel tinyxml2-devel desktop-file-utils pkgconfig)
MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! rpm -q $pkg &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done
if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo "Installing missing packages: ${MISSING_PKGS[*]}"
    sudo dnf install -y "${MISSING_PKGS[@]}"
fi

# 2. Clone aseprite (if not present)
if [ ! -d aseprite ]; then
    git clone --recursive https://github.com/aseprite/aseprite.git
fi
cd aseprite
git submodule update --init --recursive
cd ..

# 2a. Download Skia (as in the official build.sh)
skia_tag=$(cat aseprite/laf/misc/skia-tag.txt)
skia_dir="$(pwd)/skia-$(echo $skia_tag | cut -d '-' -f 1)"
skia_build=Release
skia_library_dir="$skia_dir/out/Release-x64"

if [ ! -d "$skia_library_dir" ]; then
    echo "Downloading Skia..."
    mkdir -p "$skia_dir"
    skia_url=$(bash aseprite/laf/misc/skia-url.sh $skia_build)
    skia_file=$(basename $skia_url)
    if [ ! -f "$skia_dir/$skia_file" ]; then
        curl --ssl-revoke-best-effort -L -o "$skia_dir/$skia_file" "$skia_url"
    fi
    unzip -n -d "$skia_dir" "$skia_dir/$skia_file"
fi

# 3. Read version number
cd aseprite
VERSION=$(git describe --tags --abbrev=0 | sed 's/^v//')
cd ..

# 4. Adjust .spec file
SPEC_FILE="aseprite.spec"
if [ ! -f "$SPEC_FILE" ]; then
    echo "Error: $SPEC_FILE not found!"
    exit 1
fi
cp "$SPEC_FILE" "$SPEC_FILE.bak"
sed -i "s/^Version:.*/Version:        $VERSION/" "$SPEC_FILE"

# 5. Prepare sources (pack complete directory including submodules)
mkdir -p SOURCES
TARNAME="aseprite-$VERSION.tar.gz"
rm -f "SOURCES/$TARNAME"
tar czf "SOURCES/$TARNAME" --transform "s,^aseprite,aseprite-$VERSION," aseprite skia-*

# 6. Build RPM
rpmbuild --define "_topdir $(pwd)" -ba "$SPEC_FILE"

# 7. Find RPM
RPM_FILE=$(find RPMS/ -name "aseprite-*.rpm" ! -name "*debuginfo*" ! -name "*debugsource*" | head -n1)
if [ -z "$RPM_FILE" ]; then
    echo "Error: RPM was not created."
    exit 1
fi

ABS_RPM_FILE=$(readlink -f "$RPM_FILE")
echo "The RPM is located here: $ABS_RPM_FILE"


