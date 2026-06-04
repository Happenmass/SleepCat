#!/bin/bash
# 重新打包 SleepCat.app 并封装成可拖拽安装的 DMG。
# 挂载后窗口里是 SleepCat.app 与「Applications」快捷方式，拖过去即安装。
set -e
cd "$(dirname "$0")"

# 1) 先产出最新的 .app
./package.sh

APP="SleepCat.app"
VOL="SleepCat"
DMG="SleepCat.dmg"

# 2) 准备挂载后看到的内容：App + 指向 /Applications 的软链
STAGE="$(mktemp -d)/SleepCat"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# 3) 先生成可读写 DMG，挂载后用 Finder 摆好图标位置（拖拽引导）
rm -f "$DMG" rw.dmg
hdiutil create -volname "$VOL" -srcfolder "$STAGE" -fs HFS+ \
  -format UDRW -ov rw.dmg >/dev/null

MOUNT_DIR="/Volumes/$VOL"
hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
DEV=$(hdiutil attach -readwrite -noverify -noautoopen rw.dmg | grep -E "/Volumes/$VOL" | awk '{print $1}')

# 用 AppleScript 摆位：左边 App、右边 Applications，居中提示拖拽（best-effort）
osascript <<OSA 2>/dev/null || echo "⚠️  图标摆位跳过（不影响安装功能）"
tell application "Finder"
  tell disk "$VOL"
    open
    set theWindow to container window
    set current view of theWindow to icon view
    set toolbar visible of theWindow to false
    set statusbar visible of theWindow to false
    set the bounds of theWindow to {200, 120, 720, 480}
    set viewOptions to the icon view options of theWindow
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 112
    set position of item "$APP" of theWindow to {130, 170}
    set position of item "Applications" of theWindow to {390, 170}
    update without registering applications
    delay 1
    close
  end tell
end tell
OSA

sync
hdiutil detach "$DEV" >/dev/null 2>&1 || hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true

# 4) 转成压缩只读 DMG 分发
hdiutil convert rw.dmg -format UDZO -imagekey zlib-level=9 -ov -o "$DMG" >/dev/null
rm -f rw.dmg
rm -rf "$(dirname "$STAGE")"

echo "✅ 已生成 $DMG"
hdiutil imageinfo "$DMG" 2>/dev/null | awk '/Format:/{print "   格式:",$2} /Total Bytes/{print "   大小:",$3,"bytes"}'
