import AppKit

/// 用矢量路径现画一只猫脸做菜单栏图标。
/// 设为 template image：系统自动按菜单栏前景色着色，深色/浅色模式与 Retina 都清晰。
enum CatIcon {

    /// - Parameter awake: true = 精神饱满（圆眼睛，18pt 宽）；
    ///   false = 打盹（闭眼弧线 + 右上 zzz，24pt 宽以容纳 zzz）。
    static func image(awake: Bool) -> NSImage {
        let width: CGFloat = awake ? 18 : 24
        let image = NSImage(size: NSSize(width: width, height: 18), flipped: false) { _ in

            // 1) 实心猫头（头 + 两只耳朵），nonZero 取并集。
            let body = NSBezierPath()
            body.appendOval(in: NSRect(x: 3.2, y: 1.4, width: 11.6, height: 11.6))
            body.move(to: NSPoint(x: 4.6, y: 10.8)); body.line(to: NSPoint(x: 2.6, y: 16.4)); body.line(to: NSPoint(x: 8.4, y: 12.4)); body.close()
            body.move(to: NSPoint(x: 13.4, y: 10.8)); body.line(to: NSPoint(x: 15.4, y: 16.4)); body.line(to: NSPoint(x: 9.6, y: 12.4)); body.close()
            NSColor.black.setFill()
            body.fill()

            // 2) 五官挖空（destinationOut：擦像素 → 透出菜单栏底色）。
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            NSColor.black.setFill()
            NSColor.black.setStroke()
            if awake {
                let eyes = NSBezierPath()
                eyes.appendOval(in: NSRect(x: 6.0, y: 6.6, width: 2.0, height: 2.0))   // 圆眼
                eyes.appendOval(in: NSRect(x: 10.0, y: 6.6, width: 2.0, height: 2.0))
                eyes.fill()
            } else {
                // 闭眼：两条向下的弧线（睡着的「‿ ‿」），加粗更清晰。
                let lids = NSBezierPath()
                lids.lineWidth = 1.1
                lids.lineCapStyle = .round
                lids.appendArc(withCenter: NSPoint(x: 6.9, y: 8.5), radius: 1.4, startAngle: 200, endAngle: 340)
                lids.appendArc(withCenter: NSPoint(x: 11.1, y: 8.5), radius: 1.4, startAngle: 200, endAngle: 340)
                lids.stroke()
            }
            // 鼻子（小三角，两种状态都有）
            let nose = NSBezierPath()
            nose.move(to: NSPoint(x: 8.3, y: 5.7)); nose.line(to: NSPoint(x: 9.7, y: 5.7)); nose.line(to: NSPoint(x: 9.0, y: 4.8)); nose.close()
            nose.fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver

            // 3) 胡须
            let whiskers = NSBezierPath()
            whiskers.lineWidth = 0.7
            whiskers.lineCapStyle = .round
            whiskers.move(to: NSPoint(x: 4.8, y: 6.1)); whiskers.line(to: NSPoint(x: 0.9, y: 6.8))
            whiskers.move(to: NSPoint(x: 4.8, y: 5.1)); whiskers.line(to: NSPoint(x: 0.9, y: 4.6))
            whiskers.move(to: NSPoint(x: 13.2, y: 6.1)); whiskers.line(to: NSPoint(x: 17.1, y: 6.8))
            whiskers.move(to: NSPoint(x: 13.2, y: 5.1)); whiskers.line(to: NSPoint(x: 17.1, y: 4.6))
            NSColor.black.setStroke()
            whiskers.stroke()

            // 4) 睡觉时右上角的 zzz —— 渐大、向上飘。
            if !awake {
                let z = NSBezierPath()
                z.lineWidth = 0.9
                z.lineJoinStyle = .round
                z.lineCapStyle = .round
                func addZ(_ ox: CGFloat, _ oy: CGFloat, _ s: CGFloat) {
                    z.move(to: NSPoint(x: ox, y: oy + s))        // 顶横
                    z.line(to: NSPoint(x: ox + s, y: oy + s))
                    z.line(to: NSPoint(x: ox, y: oy))            // 斜线
                    z.line(to: NSPoint(x: ox + s, y: oy))        // 底横
                }
                addZ(15.3, 8.2, 1.7)
                addZ(17.5, 10.9, 2.2)
                addZ(20.0, 13.9, 2.7)
                NSColor.black.setStroke()
                z.stroke()
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}
