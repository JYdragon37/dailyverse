import SwiftUI
import UIKit

// MARK: - DevotionShareCardRenderer
// 1080 × 1920 공유카드 PNG 이미지 생성

struct DevotionShareCardRenderer {

    static func render(verse: Verse?, prayer: String) -> UIImage {
        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let context = ctx.cgContext

            // ── 배경 그라데이션 ──────────────────────────────────────────
            let bgColors = [
                UIColor(red: 0.063, green: 0.051, blue: 0.094, alpha: 1).cgColor, // #101018
                UIColor(red: 0.102, green: 0.102, blue: 0.173, alpha: 1).cgColor, // #1A1A2E
                UIColor(red: 0.176, green: 0.176, blue: 0.267, alpha: 1).cgColor  // #2D2D44
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: bgColors as CFArray,
                locations: [0, 0.5, 1]
            )!
            context.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )

            // ── 앱 워드마크 (상단 중앙) ────────────────────────────────────
            drawCenteredText(
                "DailyVerse",
                font: UIFont.systemFont(ofSize: 36, weight: .medium),
                color: UIColor.white.withAlphaComponent(0.55),
                in: CGRect(x: 0, y: 160, width: size.width, height: 50),
                context: context
            )

            // ── 말씀 텍스트 (중앙) ────────────────────────────────────────
            let verseText = verse?.verseShortKo ?? ""
            let versePara = NSMutableParagraphStyle()
            versePara.alignment = .center
            versePara.lineSpacing = 14

            let verseFont = UIFont(name: "Georgia-Italic", size: 52) ?? UIFont.italicSystemFont(ofSize: 52)
            let verseColor = UIColor(red: 0.961, green: 0.902, blue: 0.792, alpha: 1) // #F5E6CA

            let verseAttrs: [NSAttributedString.Key: Any] = [
                .font: verseFont,
                .foregroundColor: verseColor,
                .paragraphStyle: versePara
            ]

            let verseRect = CGRect(x: 80, y: size.height * 0.32, width: size.width - 160, height: 480)
            verseText.draw(in: verseRect, withAttributes: verseAttrs)

            // ── 말씀 출처 ─────────────────────────────────────────────────
            let refText = "— \(verse?.reference ?? "")"
            let refColor = UIColor(red: 0.784, green: 0.592, blue: 0.333, alpha: 1) // #D4A774

            drawCenteredText(
                refText,
                font: UIFont.systemFont(ofSize: 28, weight: .medium),
                color: refColor,
                in: CGRect(x: 0, y: size.height * 0.32 + 480 + 20, width: size.width, height: 50),
                context: context
            )

            // ── 구분선 ────────────────────────────────────────────────────
            let dividerY = size.height * 0.32 + 480 + 90
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            context.setLineWidth(1.5)
            let dividerX = (size.width - 200) / 2
            context.move(to: CGPoint(x: dividerX, y: dividerY))
            context.addLine(to: CGPoint(x: dividerX + 200, y: dividerY))
            context.strokePath()

            // ── 기도 텍스트 ────────────────────────────────────────────────
            if !prayer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let prayerPara = NSMutableParagraphStyle()
                prayerPara.alignment = .center
                prayerPara.lineSpacing = 8

                let prayerFont = UIFont(name: "Georgia-Italic", size: 32) ?? UIFont.italicSystemFont(ofSize: 32)
                let prayerAttrs: [NSAttributedString.Key: Any] = [
                    .font: prayerFont,
                    .foregroundColor: refColor,
                    .paragraphStyle: prayerPara
                ]

                let prayerRect = CGRect(x: 100, y: dividerY + 40, width: size.width - 200, height: 140)
                prayer.draw(in: prayerRect, withAttributes: prayerAttrs)
            }

            // ── 워터마크 (하단) ───────────────────────────────────────────
            drawCenteredText(
                "DailyVerse · 말씀으로 시작하는 하루",
                font: UIFont.systemFont(ofSize: 22),
                color: UIColor.white.withAlphaComponent(0.30),
                in: CGRect(x: 0, y: size.height - 100, width: size.width, height: 40),
                context: context
            )
        }
    }

    // MARK: - Helper

    private static func drawCenteredText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        in rect: CGRect,
        context: CGContext
    ) {
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: para
        ]
        text.draw(in: rect, withAttributes: attrs)
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
