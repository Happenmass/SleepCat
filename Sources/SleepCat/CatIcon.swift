import AppKit

/// 菜单栏小猫图标:直接使用 Resources 里手绘的两张 PNG(睁眼.png / 睡觉.png)。
///
/// 原图是「黑色线稿 + 棋盘格假透明背景」的 RGB 图,不能直接当菜单栏图标用,
/// 加载时做一次转换:亮色像素(背景/棋盘格)→ 透明,深色线条 → 纯黑,
/// 再裁掉四周空白缩放进固定画布。成品设为 template image,
/// 系统自动按菜单栏前景色着色,深色/浅色模式与 Retina 都清晰。
enum CatIcon {

    /// 两种状态同尺寸画布,切换时菜单栏图标不会跳动。
    static func image(awake: Bool) -> NSImage {
        awake ? awakeImage : asleepImage
    }

    private static let awakeImage  = load("睁眼")
    private static let asleepImage = load("睡觉")

    private static func load(_ name: String) -> NSImage {
        guard let url = resourceURL(name),
              let glyph = makeTemplate(from: url) else {
            assertionFailure("找不到或无法转换图标资源 \(name).png")
            let empty = NSImage(size: NSSize(width: 18, height: 18))
            empty.isTemplate = true
            return empty
        }
        return compose(glyph)
    }

    private static func resourceURL(_ name: String) -> URL? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: "png") {
            return url
        }
        #endif
        // 兜底:从仓库根目录直接跑(开发期)时按源码路径找。
        let candidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/SleepCat/Resources/\(name).png")
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }

    /// 把「黑线稿 + 浅色背景」的位图转成黑色 + 透明的 template 字形:
    /// 缩到工作分辨率 → 亮度转 alpha → 线稿加粗(膨胀)→ 裁掉四周空白。
    /// 原图线条相对画幅很细,直接缩到 18pt 会虚成灰色,必须加粗才经得起缩小。
    static func makeTemplate(from url: URL) -> NSImage? {
        guard let src = NSImage(contentsOf: url),
              let cg = src.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        // 1) 等比缩到 ≤512 的工作分辨率,后续逐像素处理在这层做,又快又够清晰。
        let scale = min(1, 512.0 / CGFloat(max(cg.width, cg.height)))
        let w = max(1, Int(CGFloat(cg.width) * scale))
        let h = max(1, Int(CGFloat(cg.height) * scale))
        guard let ctx = CGContext(data: nil, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return nil }
        let px = data.assumingMemoryBound(to: UInt8.self)

        // 2) 亮度 → 不透明度:≤0.45 全黑不透明,≥0.72 全透明,中间线性过渡。
        //    棋盘格假透明(白 / 亮灰)整体落在透明区,线条的抗锯齿边缘得到平滑 alpha。
        var alpha = [UInt8](repeating: 0, count: w * h)
        for i in 0..<(w * h) {
            let lum = (0.299 * CGFloat(px[i * 4]) + 0.587 * CGFloat(px[i * 4 + 1])
                       + 0.114 * CGFloat(px[i * 4 + 2])) / 255
            alpha[i] = UInt8(min(max((0.72 - lum) / (0.72 - 0.45), 0), 1) * 255)
        }

        // 3) 线稿加粗:横向 + 纵向各做一次滑动取最大(盒式膨胀)。
        let r = max(1, w * 10 / 1000)
        for pass in 0..<2 {
            var out = alpha
            for y in 0..<h {
                for x in 0..<w {
                    var m: UInt8 = 0
                    for d in -r...r {
                        let xx = pass == 0 ? x + d : x
                        let yy = pass == 0 ? y : y + d
                        if xx >= 0, xx < w, yy >= 0, yy < h {
                            m = max(m, alpha[yy * w + xx])
                        }
                    }
                    out[y * w + x] = m
                }
            }
            alpha = out
        }

        // 4) 写回(预乘黑:RGB 置 0 即可)并统计内容包围盒。
        var minX = w, minY = h, maxX = -1, maxY = -1
        for y in 0..<h {
            for x in 0..<w {
                let i = y * w + x
                px[i * 4] = 0; px[i * 4 + 1] = 0; px[i * 4 + 2] = 0
                px[i * 4 + 3] = alpha[i]
                if alpha[i] > 20 {
                    if x < minX { minX = x }; if x > maxX { maxX = x }
                    if y < minY { minY = y }; if y > maxY { maxY = y }
                }
            }
        }
        guard maxX >= minX, maxY >= minY, let whole = ctx.makeImage() else { return nil }

        let pad = max(w, h) / 100                              // 1% 呼吸边
        let x0 = max(0, minX - pad), y0 = max(0, minY - pad)
        let crop = CGRect(x: x0, y: y0,
                          width: min(w, maxX + pad + 1) - x0,
                          height: min(h, maxY + pad + 1) - y0)
        guard let cropped = whole.cropping(to: crop) else { return nil }
        return NSImage(cgImage: cropped, size: .zero)
    }

    /// 把字形按比例缩放、居中放进固定大小的菜单栏画布。
    static func compose(_ glyph: NSImage, canvas: NSSize = NSSize(width: 21, height: 18)) -> NSImage {
        let image = NSImage(size: canvas, flipped: false) { rect in
            let gs = glyph.size
            guard gs.width > 0, gs.height > 0 else { return true }
            let scale = min(rect.width / gs.width, rect.height / gs.height)
            let size = NSSize(width: gs.width * scale, height: gs.height * scale)
            NSGraphicsContext.current?.imageInterpolation = .high
            glyph.draw(in: NSRect(x: rect.midX - size.width / 2,
                                  y: rect.midY - size.height / 2,
                                  width: size.width, height: size.height))
            return true
        }
        image.isTemplate = true
        return image
    }
}
