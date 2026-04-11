import SwiftUI
import UIKit

// MARK: - DevotionShareCardRenderer
// 1080 × 1920 공유카드 PNG 이미지 생성

struct DevotionShareCardRenderer {

    static func render(verse: Verse?, prayer: String, backgroundImage: UIImage? = nil) -> UIImage {
        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let context = ctx.cgContext

            // 1. 배경: 전달받은 이미지 또는 dvBgDeep 그라데이션 폴백
            if let bgImage = backgroundImage {
                let scale = max(size.width / bgImage.size.width, size.height / bgImage.size.height)
                let w = bgImage.size.width * scale
                let h = bgImage.size.height * scale
                bgImage.draw(in: CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h))
            } else {
                // 폴백 그라데이션
                let fallbackColors = [
                    UIColor(red: 0.035, green: 0.051, blue: 0.094, alpha: 1).cgColor,
                    UIColor(red: 0.071, green: 0.063, blue: 0.176, alpha: 1).cgColor
                ]
                let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: fallbackColors as CFArray, locations: [0, 1])!
                context.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }

            // 2. 다크 오버레이 (SavedDetailView와 동일: 0.25 → 0.55)
            let overlayColors = [
                UIColor.black.withAlphaComponent(0.25).cgColor,
                UIColor.black.withAlphaComponent(0.55).cgColor
            ]
            let overlay = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: overlayColors as CFArray, locations: [0, 1])!
            context.drawLinearGradient(overlay, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

            // 3. 말씀 텍스트 (좌측 정렬, 40% 위치 — SavedDetailView 동일)
            let hPad: CGFloat = max(size.width * 0.13, 140.0)
            let verseY = size.height * 0.40

            let versePara = NSMutableParagraphStyle()
            versePara.alignment = .left
            versePara.lineSpacing = 20

            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.85)
            shadow.shadowBlurRadius = 16
            shadow.shadowOffset = CGSize(width: 0, height: 4)

            let verseFont = UIFont.systemFont(ofSize: 56, weight: .semibold)
            let verseText = verse?.verseFullKo ?? ""
            let verseAttrs: [NSAttributedString.Key: Any] = [
                .font: verseFont,
                .foregroundColor: UIColor.white,
                .paragraphStyle: versePara,
                .shadow: shadow
            ]

            let verseNS = NSAttributedString(string: verseText, attributes: verseAttrs)
            let verseRect = CGRect(x: hPad, y: verseY, width: size.width - hPad * 2, height: 700)
            verseText.draw(in: verseRect, withAttributes: verseAttrs)

            // 말씀 실제 높이 계산
            let verseHeight = verseNS.boundingRect(
                with: CGSize(width: size.width - hPad * 2, height: 700),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).height

            // 4. reference (말씀 아래 54pt 간격)
            let refY = verseY + verseHeight + 54
            let refText = verse?.reference ?? ""
            let refFont = UIFont.systemFont(ofSize: 38, weight: .medium)
            let refAttrs: [NSAttributedString.Key: Any] = [.font: refFont, .foregroundColor: UIColor.white.withAlphaComponent(0.8)]
            refText.draw(in: CGRect(x: hPad, y: refY, width: size.width - hPad * 2, height: 60), withAttributes: refAttrs)

            // 5. 기도 (있을 때만, 하단 영역)
            let trimmed = prayer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let prayerY = size.height * 0.74
                let prayerPara = NSMutableParagraphStyle()
                prayerPara.alignment = .center
                prayerPara.lineSpacing = 10

                let prayerFont = UIFont(name: "Georgia-Italic", size: 38) ?? UIFont.italicSystemFont(ofSize: 38)
                let gold = UIColor(red: 0.784, green: 0.592, blue: 0.333, alpha: 1)
                let prayerAttrs: [NSAttributedString.Key: Any] = [.font: prayerFont, .foregroundColor: gold, .paragraphStyle: prayerPara]
                trimmed.draw(in: CGRect(x: 120, y: prayerY, width: size.width - 240, height: 160), withAttributes: prayerAttrs)
            }

            // 6. DailyVerse 워터마크 (하단)
            let wmPara = NSMutableParagraphStyle(); wmPara.alignment = .center
            let wmAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.40),
                .paragraphStyle: wmPara
            ]
            "DailyVerse".draw(in: CGRect(x: 0, y: size.height - 110, width: size.width, height: 50), withAttributes: wmAttrs)
        }
    }

}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
