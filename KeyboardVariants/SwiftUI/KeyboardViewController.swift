import UIKit
import SwiftUI

@MainActor
final class KeyboardViewController: UIInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let keyboard = MovingKeyboardView(
            insert: { [weak self] text in self?.textDocumentProxy.insertText(text) },
            delete: { [weak self] in self?.textDocumentProxy.deleteBackward() },
            next: { [weak self] in self?.advanceToNextInputMode() }
        )
        let host = UIHostingController(rootView: keyboard)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)

        let height = view.heightAnchor.constraint(equalToConstant: 235)
        height.priority = .defaultHigh
        height.isActive = true
    }
}

private struct MovingKeyboardView: View {
    let insert: (String) -> Void
    let delete: () -> Void
    let next: () -> Void

    private let rows = [
        ["あ","い","う","え","お","か","き","く","け","こ","さ","し","す","せ","そ"],
        ["た","ち","つ","て","と","な","に","ぬ","ね","の","は","ひ","ふ","へ","ほ"],
        ["ま","み","む","め","も","や","ゆ","よ","ら","り","る","れ","ろ","わ","を","ん"]
    ]

    var body: some View {
        VStack(spacing: 7) {
            Text("くるくる SwiftUI")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(rows.indices, id: \.self) { index in
                MovingRow(
                    keys: rows[index],
                    direction: index == 1 ? -1 : 1,
                    speed: index == 1 ? 46 : 54,
                    insert: insert
                )
            }

            HStack(spacing: 6) {
                key("🌐", action: next)
                key("空白") { insert(" ") }
                    .frame(maxWidth: .infinity)
                key("⌫", action: delete)
                key("改行") { insert("\n") }
            }
            .frame(height: 42)
        }
        .padding(6)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.04, blue: 0.05),
                    Color(red: 0.075, green: 0.08, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func key(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
    }
}

private struct MovingRow: View {
    let keys: [String]
    let direction: CGFloat
    let speed: CGFloat
    let insert: (String) -> Void

    var body: some View {
        GeometryReader { _ in
            TimelineView(.animation) { context in
                let stride: CGFloat = 52
                let rowWidth = CGFloat(keys.count) * stride
                let travel = (CGFloat(context.date.timeIntervalSinceReferenceDate) * speed)
                    .truncatingRemainder(dividingBy: rowWidth)
                let x = direction > 0 ? -rowWidth + travel : -travel

                HStack(spacing: 8) {
                    ForEach(0..<(keys.count * 3), id: \.self) { index in
                        let key = keys[index % keys.count]
                        Button { insert(key) } label: {
                            Text(key)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 42)
                                .background(.white.opacity(0.105))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .offset(x: x)
            }
        }
        .frame(height: 46)
        .clipped()
    }
}
