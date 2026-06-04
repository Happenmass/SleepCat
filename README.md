# SleepCat 🐱

一只住在 Mac 菜单栏里的猫。它醒着的时候，你的 Mac 就不会睡 —— 不进系统睡眠、可选不熄屏。

底层用 **IOKit 电源断言**（`IOPMAssertionCreateWithName`），和 `caffeinate` 同一套系统 API，
但**不 fork 子进程**：断言随 App 进程存活，App 一退出断言自动释放，绝不会留下「Mac 永不睡眠」的孤儿进程。

## 已知限制：合盖会睡（网络中断）

电源断言只拦截**空闲（idle）睡眠**：
- **锁屏** —— 只是锁屏、不触发睡眠路径，空闲计时器被断言压住 → 不睡、网络在线。✅
- **合盖（clamshell）** —— 由**硬件**直接触发的强制睡眠，走另一条路，电源断言对它**无效** → 系统照睡、网络中断。这是 `caffeinate` / Amphetamine 等所有同类工具的共同限制，非本应用 bug。

想让**合盖也不睡**，用苹果官方支持的 **Clamshell 模式**：插上电源 + 接一台外接显示器（部分机型还需外接键鼠），合盖后即闭盖运行、不睡、网络在线，零风险。

> 纯软件方式（`sudo pmset disablesleep 1`）虽能合盖不睡，但需管理员权限、且合盖放包里有过热风险，本应用刻意不内置。

## 跑起来

```bash
swift run        # 直接运行，菜单栏右上角出现 😴
```

- 😴 猫咪打盹中 —— Mac 正常睡眠
- 🐱 猫咪精神饱满 —— 守护中（限时档会显示倒计时 `🐱 14:59`）

菜单：
- **一直陪我清醒 / 放它去睡** —— 主开关
- **限时守护** —— 打盹 15 分钟 / 晒太阳 30 分钟 / 守一集剧 1 小时 / 陪你加班 2 小时
- **同时不让屏幕熄灭** —— 开 = 防熄屏（caffeinate `-d`），关 = 仅防系统睡眠（`-i`）

## 验证它真的生效

守护开启后，另开终端：

```bash
pmset -g assertions | grep PreventUserIdleDisplaySleep
# 守护中会看到 SleepCat 的具名断言，聚合值为 1
```

## 打包成可双击的 .app（可选）

`swift run` 适合开发。要做成能放进「应用程序」的 App（`LSUIElement=true`，只在菜单栏、不进 Dock），
一条命令即可，会自动接入图标：

```bash
./package.sh          # 生成 SleepCat.app（含 Resources/AppIcon.icns）
open SleepCat.app
```

App 图标源文件在 `Resources/`：`AppIcon-1024.png`（透明源图）与 `AppIcon.icns`（打包用）。
换图标时替换 `AppIcon-1024.png`，用 `iconutil` 重新生成 `.icns` 即可。

## 封装成可拖拽安装的 DMG（分发用）

```bash
./make_dmg.sh         # 内部会先跑 package.sh，再产出 SleepCat.dmg
open SleepCat.dmg
```

挂载后窗口里是 **SleepCat.app** 和一个 **Applications** 快捷方式，把猫拖到 Applications 即完成安装。
App 已做 ad-hoc 签名（Apple Silicon 必需）；未经苹果公证，首次打开需在「系统设置 → 隐私与安全性」放行。

## 结构

| 文件 | 作用 |
| --- | --- |
| `Sources/SleepCat/SleepGuard.swift` | IOKit 电源断言封装，控制睡眠/熄屏 |
| `Sources/SleepCat/AppDelegate.swift` | 菜单栏 UI、限时倒计时、猫咪文案 |
| `Sources/SleepCat/CatIcon.swift` | 矢量现画的菜单栏猫脸图标（template，随状态变眼睛） |
| `Sources/SleepCat/main.swift` | 入口，`.accessory` 模式（仅菜单栏） |
| `Resources/AppIcon.icns` · `AppIcon-1024.png` | App 打包图标（捧拿铁的猫） |
| `package.sh` | 一键打包成 `SleepCat.app`（含 ad-hoc 签名） |
| `make_dmg.sh` | 打包并封装成可拖拽安装的 `SleepCat.dmg` |
