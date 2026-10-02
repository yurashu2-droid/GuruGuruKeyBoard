import UIKit
import SwiftUI

@MainActor
final class KeyboardViewController: UIInputViewController {
    private let model = VerticalKeyboardModel()
    private var keyboardHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        inputView?.allowsSelfSizing = true

        let keyboard = VerticalKeyboardView(
            model: model,
            showGlobe: needsInputModeSwitchKey,
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

        let height = view.heightAnchor.constraint(equalToConstant: 340)
        height.priority = .defaultHigh
        height.isActive = true
        keyboardHeightConstraint = height
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let target: CGFloat = traitCollection.verticalSizeClass == .compact ? 238 : 340
        if keyboardHeightConstraint?.constant != target {
            keyboardHeightConstraint?.constant = target
        }
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
        inputMode == .kana ? Self.kanaColumns : Self.latinColumns
    }

    // Predictable layout: each column owns a contiguous chunk of the alphabet.
    // All columns move at the same speed and phase, so rows stay visually aligned.
    private static let kanaColumns: [[FlowKey]] = [
        ["あ","い","う","え","お","か","き","く","け","こ","さ","し","す","せ","そ"].map(FlowKey.text),
        ["た","ち","つ","て","と","な","に","ぬ","ね","の","は","ひ","ふ","へ","ほ"].map(FlowKey.text),
        ["ま","み","む","め","も","や","ゆ","よ","ら","り","る","れ","ろ","わ","を"].map(FlowKey.text),
        [
            .text("ん"), .punctuation("ー"), .punctuation("、"), .punctuation("。"),
            .dakuten, .handakuten, .smallKana, .convert,
            .space, .backspace, .space, .returnKey, .modeToggle,
            .punctuation("？"), .punctuation("！")
        ]
    ]

    private static let latinColumns: [[FlowKey]] = [
        Array("abcdefg").map { .text(String($0)) },
        Array("hijklmn").map { .text(String($0)) },
        Array("opqrstu").map { .text(String($0)) },
        Array("vwxyz").map { .text(String($0)) } + [
            .text(","), .text("."), .text("-"),
            .space, .backspace, .space, .returnKey, .modeToggle
        ]
    ]
}

private enum FlowKey: Hashable {
    case text(String)
    case backspace
    case space
    case returnKey
    case modeToggle
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
    let showGlobe: Bool
    let onKey: (FlowKey) -> Void
    let onNextKeyboard: () -> Void

    private let speed: CGFloat = 122

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
                        speed: speed,
                        mode: model.inputMode,
                        onTap: onKey
                    )
                }
            }
            .padding(6)

            // Face ID iPhones normally provide the globe/mic system controls
            // below the extension. Only provide our own globe if iOS says it is needed.
            if showGlobe {
                Button(action: onNextKeyboard) {
                    Image(systemName: "globe")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(.black.opacity(0.84))
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
}

private struct VerticalConveyorColumn: View {
    let keys: [FlowKey]
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
                    CGFloat(context.date.timeIntervalSinceReferenceDate) * speed
                ).truncatingRemainder(dividingBy: cycleHeight)

                VStack(spacing: spacing) {
                    ForEach(0..<(keys.count * 3), id: \.self) { index in
                        let key = keys[index % keys.count]
                        Button {
                            onTap(key)
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
                .offset(y: -cycleHeight + travel)
                .frame(width: geometry.size.width)
            }
        }
        .clipped()
    }

    private func displayLabel(for key: FlowKey) -> String {
        key == .modeToggle ? (mode == .kana ? "ABC" : "かな") : key.label
    }

    private func background(for key: FlowKey) -> Color {
        switch key {
        case .space, .returnKey, .backspace, .modeToggle, .convert:
            return .white.opacity(0.16)
        default:
            return .white.opacity(0.095)
        }
    }
}
