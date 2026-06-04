import Foundation
import IOKit.pwr_mgt

/// 用 IOKit 电源断言（power assertion）控制 Mac 睡眠 —— 和 `caffeinate` 底层是同一套 API，
/// 但不 fork 子进程：断言随本进程存活，App 一退出断言自动释放，绝不会留下「永不睡眠」的孤儿。
final class SleepGuard {

    /// 当前是否正在守护（让猫咪保持清醒）。
    private(set) var isActive = false

    /// 是否连屏幕也一起守护（防熄屏）。对应 caffeinate 的 `-d`；关闭时仅防系统睡眠，等价 `-i`。
    /// 默认关闭：只防系统睡眠，屏幕仍可正常熄灭。
    var preventDisplaySleep = false

    private var assertionID: IOPMAssertionID = 0

    /// 开始守护。会先释放旧断言，再按当前 `preventDisplaySleep` 设置重新申请。
    func start() {
        release()

        let type = preventDisplaySleep
            ? kIOPMAssertionTypePreventUserIdleDisplaySleep   // 屏幕 + 系统都不睡
            : kIOPMAssertionTypePreventUserIdleSystemSleep    // 仅系统不睡，屏幕可熄

        let reason = "SleepCat 正在守护，让猫咪保持清醒 🐱" as CFString
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        isActive = (result == kIOReturnSuccess)
    }

    /// 停止守护，让 Mac 恢复正常的睡眠行为。
    func stop() {
        release()
        isActive = false
    }

    private func release() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }

    deinit {
        release()
    }
}
