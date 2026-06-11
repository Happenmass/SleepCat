#!/bin/bash
# 把 SleepCat 打包成可双击的 .app（含图标），accessory 模式只在菜单栏出现。
set -e
cd "$(dirname "$0")"

swift build -c release

APP="SleepCat.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/SleepCat "$APP/Contents/MacOS/SleepCat"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
# SwiftPM 资源包（菜单栏猫猫 PNG），Bundle.module 在 Contents/Resources 下查找
cp -R .build/release/SleepCat_SleepCat.bundle "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>SleepCat</string>
  <key>CFBundleIdentifier</key><string>com.sleepcat.app</string>
  <key>CFBundleName</key><string>SleepCat</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
</dict></plist>
PLIST

# ad-hoc 签名：Apple Silicon 上未签名的 .app 可能被系统直接拒绝运行。
codesign --force --deep --sign - "$APP" 2>/dev/null || echo "⚠️  ad-hoc 签名跳过（不影响本机运行）"

echo "✅ 已生成 $APP —— 双击运行，或 open $APP"
