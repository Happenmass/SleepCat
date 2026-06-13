import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let guard_ = SleepGuard()
    private var statusItem: NSStatusItem!

    /// 限时守护的截止时间；nil 表示「一直清醒」或未开启。
    private var deadline: Date?
    /// 每秒刷新一次菜单栏文案（倒计时）。
    private var ticker: Timer?

    // 限时档位（标题 → 表情 → 秒数）。一只猫的小憩哲学。
    private let durations: [(title: String, emoji: String, seconds: TimeInterval)] = [
        ("打个盹 · 15 分钟", "☕️", 15 * 60),
        ("晒会儿太阳 · 30 分钟", "🌞", 30 * 60),
        ("守一集剧 · 1 小时", "📺", 60 * 60),
        ("陪你加班 · 2 小时", "💻", 2 * 60 * 60),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        rebuildMenu()
        refreshTitle()
    }

    // MARK: - 守护开关

    private func startGuarding(deadline: Date?) {
        self.deadline = deadline
        guard_.start()
        startTickerIfNeeded()
        rebuildMenu()
        refreshTitle()
    }

    private func stopGuarding() {
        deadline = nil
        guard_.stop()
        ticker?.invalidate()
        ticker = nil
        rebuildMenu()
        refreshTitle()
    }

    @objc private func toggleForever() {
        if guard_.isActive {
            stopGuarding()
        } else {
            startGuarding(deadline: nil)
        }
    }

    @objc private func startTimed(_ sender: NSMenuItem) {
        let seconds = durations[sender.tag].seconds
        startGuarding(deadline: Date().addingTimeInterval(seconds))
    }

    @objc private func toggleDisplaySleep(_ sender: NSMenuItem) {
        guard_.preventDisplaySleep.toggle()
        if guard_.isActive { guard_.start() } // 即时生效
        rebuildMenu()
    }

    @objc private func quit() {
        guard_.stop()
        NSApp.terminate(nil)
    }

    // MARK: - 倒计时

    private func startTickerIfNeeded() {
        ticker?.invalidate()
        guard deadline != nil else { return }
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let deadline else { return }
        if Date() >= deadline {
            stopGuarding() // 时间到，猫咪安心睡去
        } else {
            refreshTitle()
        }
    }

    // MARK: - 菜单栏外观

    private func refreshTitle() {
        guard let button = statusItem.button else { return }
        button.image = CatIcon.image(awake: guard_.isActive)
        if !guard_.isActive {
            button.title = "" // 打盹中：允许正常睡眠
            button.toolTip = "猫咪打盹中 · 点击让它打起精神"
        } else if let deadline {
            button.title = " " + Self.format(remaining: deadline.timeIntervalSinceNow)
            button.toolTip = "限时守护中"
        } else {
            button.title = "" // 一直清醒
            button.toolTip = "一直清醒中 · 点击放它去睡"
        }
    }

    private static func format(remaining: TimeInterval) -> String {
        let s = max(0, Int(remaining.rounded()))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec)
                     : String(format: "%d:%02d", m, sec)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // 状态标题（不可点）
        let header = NSMenuItem(
            title: guard_.isActive ? "猫咪精神饱满" : "猫咪正在打盹",
            action: nil, keyEquivalent: ""
        )
        header.image = Self.emojiIcon(guard_.isActive ? "🐱" : "😴")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        // 一直清醒 / 放它去睡
        let toggle = NSMenuItem(
            title: guard_.isActive ? "放它去睡" : "一直陪我清醒",
            action: #selector(toggleForever), keyEquivalent: ""
        )
        toggle.target = self
        toggle.image = Self.emojiIcon(guard_.isActive ? "💤" : "☕️")
        if guard_.isActive && deadline == nil { toggle.state = .on }
        menu.addItem(toggle)

        // 限时守护子菜单
        let timed = NSMenuItem(title: "限时守护", action: nil, keyEquivalent: "")
        timed.image = Self.emojiIcon("⏰")
        let sub = NSMenu()
        for (i, d) in durations.enumerated() {
            let item = NSMenuItem(title: d.title, action: #selector(startTimed(_:)), keyEquivalent: "")
            item.target = self
            item.tag = i
            item.image = Self.emojiIcon(d.emoji)
            sub.addItem(item)
        }
        timed.submenu = sub
        menu.addItem(timed)

        menu.addItem(.separator())

        // 防熄屏开关
        let display = NSMenuItem(
            title: "同时不让屏幕熄灭", action: #selector(toggleDisplaySleep(_:)), keyEquivalent: ""
        )
        display.target = self
        display.image = Self.emojiIcon("🖥️")
        display.state = guard_.preventDisplaySleep ? .on : .off
        menu.addItem(display)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出 SleepCat", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /// 把一个 emoji 渲染成菜单项左侧的小图标（彩色，非 template，
    /// 这样系统不会把它按前景色重新着色，可爱表情得以保留原色）。
    /// 统一画进正方形画布并居中，各项图标基线对齐、不会高低参差。
    private static func emojiIcon(_ emoji: String, side: CGFloat = 16) -> NSImage {
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: side * 0.85)]
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            let str = emoji as NSString
            let textSize = str.size(withAttributes: attrs)
            str.draw(at: NSPoint(x: rect.midX - textSize.width / 2,
                                 y: rect.midY - textSize.height / 2),
                     withAttributes: attrs)
            return true
        }
        image.isTemplate = false
        return image
    }
}
