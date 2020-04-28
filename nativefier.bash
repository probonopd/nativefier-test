#!/bin/bash -ex

###################################################
IMPORTANT: DO NOT RUN THIS ON SYSTEMS NEWER THAN
THE OLDEST STILL-SUPPORTED LTS RELEASE OF UBUNTU
OR ELSE THE RESULTING APPIMAGE WILL NOT BE ABLE TO
RUN ON ALL STILL-SUPPORTED VERSIONS OF UBUNTU
###################################################

rm -rf appdir/ || true # Clean up from previous runs

wget -c "https://nodejs.org/dist/v12.16.3/node-v12.16.3-linux-x64.tar.xz"
tar xf node-*-linux-x64.tar.xz
./node-*-linux-x64/bin/node ./node-*-linux-x64/bin/npm install nativefier -g
./node-*-linux-x64/bin/node ./node-*-linux-x64/bin/nativefier "https://medium.com"

OUTDIR=$(dirname $(dirname $(dirname $(readlink -f $(find . -type f -name 'icon.png'))))| head -n 1)
BINNAME=$(basename $(echo $OUTDIR) | cut -d "-" -f 1)

mkdir -p appdir/usr/bin
mv "$OUTDIR"/* appdir/usr/bin/
mkdir -p appdir/usr/share/icons/hicolor/256x256/apps/
cp appdir/usr/bin/resources/app/icon.png appdir/usr/share/icons/hicolor/256x256/apps/
cp appdir/usr/share/icons/hicolor/256x256/apps/icon.png appdir/

mkdir -p appdir/usr/share/applications/
cat > appdir/usr/share/applications/nativefied.desktop <<EOF
[Desktop Entry]
Type=Application
Name=$BINNAME
Comment=$BINNAME produced by Nativefier
Icon=icon
Exec=nativefied
Categories=Network;
EOF

cp appdir/usr/share/applications/nativefied.desktop appdir/

mv appdir/usr/bin/$BINNAME appdir/usr/bin/nativefied

cat > appdir/AppRun <<\EOF
#!/bin/bash

HERE="$(dirname "$(readlink -f "${0}")")"

# https://github.com/AppImage/AppImageKit/issues/1039
if [ $(sysctl kernel.unprivileged_userns_clone | cut -d " " -f 3) != "1" ] ; then
  echo "Working around systems without unprivileged_userns_clone using --no-sandbox"
  exec "${HERE}/usr/bin/nativefied" "$@" --no-sandbox
else
  exec "${HERE}/usr/bin/nativefied" "$@"
fi

EOF
chmod +x appdir/AppRun

wget -c https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases -O - | grep "appimagetool-.*-x86_64.AppImage" | head -n 1 | cut -d '"' -f 2)
chmod +x appimagetool-*.AppImage
./appimagetool-*.AppImage deploy ./appdir/usr/share/applications/*.desktop # Bundle everything expect what comes with the base system

find appdir/ -type f -name '*libnss*' -delete

VERSION=$(date +"%Y%m%d") ./appimagetool-*.AppImage ./appdir # turn AppDir into AppImage