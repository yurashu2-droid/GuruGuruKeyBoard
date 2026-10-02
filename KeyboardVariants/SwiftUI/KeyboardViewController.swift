import UIKit
import SwiftUI

@MainActor
final class KeyboardViewController: UIInputViewController {
    private let model = VerticalKeyboardModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let keyboard = VerticalKeyboardView(
            model: model,
            onKey: { [weak self] key in self?.handle(key) },
            onNextKeyboard: { [weak self] in self?.advanceToNextInputMode() }
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

        let height = view.heightAnchor.constraint(equalToConstant: 302)
        height.priority = .defaultHigh
        height.isActive = true
    }

    private func handle(_ key: FlowKey) {
        switch key {
        case .text(let text):
            textDocumentProxy.insertText(text)
        case .backspace:
            textDocumentProxy.deleteBackward()
        case .space:
            textDocumentProxy.insertText(" ")
        case .returnKey:
            textDocumentProxy.insertText("\n")
        case .modeToggle:
            model.inputMode = model.inputMode == .kana ? .latin : .kana
        case .microphone:
            // Third-party keyboard extensions cannot start system dictation.
            // Move to the next keyboard so the user can use Apple's dictation.
            advanceToNextInputMode()
        case .dakuten:
            textDocumentProxy.insertText("゛")
        case .handakuten:
            textDocumentProxy.insertText("゜")
        case .smallKana:
            break
        case .convert:
            break
        case .punctuation(let text):
            textDocumentProxy.insertText(text)
        }
    }
}

@MainActor
private final class VerticalKeyboardModel: ObservableObject {
    enum InputMode { case kana, latin }
    @Published var inputMode: InputMode = .kana

    var columns: [[FlowKey]] {
        Self.distribute(inputMode == .kana ? Self.kanaKeys : Self.latinKeys)
    }

    private static let kanaKeys: [FlowKey] = [
        "あ","い","う","え","お","か","き","く","け","こ",
        "さ","し","す","せ","そ","た","ち","つ","て","と",
        "な","に","ぬ","ね","の","は","ひ","ふ","へ","ほ",
        "ま","み","む","め","も","や","ゆ","よ",
        "ら","り","る","れ","ろ","わ","を","ん"
    ].map(FlowKey.text) + [
        .punctuation("ー"), .punctuation("、"), .punctuation("。"),
        .dakuten, .handakuten, .smallKana, .convert,
        .space, .returnKey, .backspace, .modeToggle, .microphone
    ]

    private static let latinKeys: [FlowKey] = Array("abcdefghijklmnopqrstuvwxyz").map {
        .text(String($0))
    } + [
        .text(","), .text("."), .text("-"),
        .space, .returnKey, .backspace, .modeToggle, .microphone
    ]

    private static func distribute(_ keys: [FlowKey]) -> [[FlowKey]] {
        var columns = Array(repeating: [FlowKey](), count: 4)
        for (index, key) in keys.enumerated() {
            columns[index % 4].append(key)
        }
        return columns
    }
}

private enum FlowKey: Hashable {
    case text(String)
    case backspace
    case space
    case returnKey
    case modeToggle
    case microphone
    case dakuten
    case handakuten
    case smallKana
    case convert
    case punctuation(String)

    var label: String {
        switch self {
        case .text(let text): return text
        case .backspace: return "⌫"
        case .space: return "空白"
        case .returnKey: return "↵"
        case .modeToggle: return "切替"
        case .microphone: return "🎤"
        case .dakuten: return "゛"
        case .handakuten: return "゜"
        case .smallKana: return "小"
        case .convert: return "変換"
        case .punctuation(let text): return text
        }
    }
}

private struct VerticalKeyboardView: View {
    @ObservedObject var model: VerticalKeyboardModel
    let onKey: (FlowKey) -> Void
    let onNextKeyboard: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.025, green: 0.03, blue: 0.04),
                    Color(red: 0.075, green: 0.08, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            HStack(spacing: 7) {
                ForEach(0..<4, id: \.self) { index in
                    VerticalConveyorColumn(
                        keys: model.columns[index],
                        phase: CGFloat(index) * 137,
                        speed: 47,
                        mode: model.inputMode,
                        onTap: onKey
                    )
                }
            }
            .padding(6)

            Button(action: onNextKeyboard) {
                Image(systemName: "globe")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.black.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.28), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(9)
        }
    }
}

private struct VerticalConveyorColumn: View {
    let keys: [FlowKey]
    let phase: CGFloat
    let speed: CGFloat
    let mode: VerticalKeyboardModel.InputMode
    let onTap: (FlowKey) -> Void

    private let keyHeight: CGFloat = 44
    private let spacing: CGFloat = 7

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { context in
                let cycleHeight = max(CGFloat(keys.count) * (keyHeight + spacing), 1)
                let travel = (
                    CGFloat(context.date.timeIntervalSinceReferenceDate) * speed + phase
                ).truncatingRemainder(dividingBy: cycleHeight)
                let y = -cycleHeight + travel

                VStack(spacing: spacing) {
                    ForEach(0..<(keys.count * 3), id: \.self) { index in
                        let key = keys[index % keys.count]
                        Button {
                            onTap(resolved(key))
                        } label: {
                            Text(displayLabel(for: key))
                                .font(.system(
                                    size: key.label.count > 1 ? 13 : 19,
                                    weight: .bold,
                                    design: .rounded
                                ))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: keyHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 13)
                                        .fill(background(for: key))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13)
                                        .stroke(.white.opacity(0.15), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .offset(y: y)
                .frame(width: geometry.size.width)
            }
        }
        .clipped()
    }

    private func displayLabel(for key: FlowKey) -> String {
        if key == .modeToggle {
            return mode == .kana ? "ABC" : "かな"
        }
        return key.label
    }

    private func resolved(_ key: FlowKey) -> FlowKey {
        key
    }

    private func background(for key: FlowKey) -> Color {
        switch key {
        case .space, .returnKey, .backspace, .modeToggle, .microphone, .convert:
            return .white.opacity(0.16)
        default:
            return .white.opacity(0.095)
        }
    }
}
