Name:           aseprite
Version:        1.3.17.2
Release:        1%{?dist}
Summary:        Animated sprite editor & pixel art tool

License:        https://github.com/aseprite/aseprite/blob/main/EULA.txt
URL:            https://www.aseprite.org/
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  ninja-build
BuildRequires:  libX11-devel
BuildRequires:  libXcursor-devel
BuildRequires:  libXrandr-devel
BuildRequires:  libXi-devel
BuildRequires:  libpng-devel
BuildRequires:  libjpeg-turbo-devel
BuildRequires:  zlib-devel
BuildRequires:  freetype-devel
BuildRequires:  fontconfig-devel
BuildRequires:  curl-devel
BuildRequires:  harfbuzz-devel
BuildRequires:  pixman-devel
BuildRequires:  lua-devel
BuildRequires:  libwebp-devel
BuildRequires:  tinyxml2-devel
BuildRequires:  desktop-file-utils
BuildRequires:  pkgconfig
BuildRequires:  git

Requires:       hicolor-icon-theme

%description
Aseprite is a program to create animated sprites and pixel art.

%prep
%autosetup -n %{name}-%{version}

%build
SKIA_DIR="$PWD/../skia-$(cat laf/misc/skia-tag.txt | cut -d '-' -f 1)"
SKIA_LIBRARY_DIR="$SKIA_DIR/out/Release-x64"
cmake -B build -S . -G Ninja -DLAF_BACKEND=skia -DSKIA_DIR="$SKIA_DIR" -DSKIA_LIBRARY_DIR="$SKIA_LIBRARY_DIR"
cmake --build build --target aseprite

%install
mkdir -p %{buildroot}/usr/bin
install -m 755 build/bin/aseprite %{buildroot}/usr/bin/aseprite

# Install data files
mkdir -p %{buildroot}/usr/share/aseprite/data
cp -a data/* %{buildroot}/usr/share/aseprite/data/

# Desktop file
mkdir -p %{buildroot}/usr/share/applications
cat > %{buildroot}/usr/share/applications/aseprite.desktop << EOF
[Desktop Entry]
Name=Aseprite
Comment=Animated sprite editor & pixel art tool
Exec=aseprite
Icon=aseprite
Terminal=false
Type=Application
Categories=Graphics;2DGraphics;RasterGraphics;GTK;
EOF

# Icons
for size in 16 20 24 28 32 48 64 128 256; do
    mkdir -p %{buildroot}/usr/share/icons/hicolor/${size}x${size}/apps
    install -m 644 data/icons/ase${size}.png %{buildroot}/usr/share/icons/hicolor/${size}x${size}/apps/aseprite.png
done

%files
/usr/bin/aseprite
/usr/share/applications/aseprite.desktop
/usr/share/icons/hicolor/*/apps/aseprite.png
/usr/share/aseprite/data

%changelog
* Sat Jun 28 2025 Packager <you@example.com> - 1.3.14-1
- Initial RPM release for Aseprite 1.3.14
