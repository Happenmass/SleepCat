import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// .accessory：只在菜单栏出现，不占 Dock、不抢焦点 —— 一只安静的猫。
app.setActivationPolicy(.accessory)
app.run()
