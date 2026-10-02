import UIKit
import SwiftUI

@MainActor
final class KeyboardViewController: UIInputViewController {
    private let model = DiagonalKeyboardModel()
    private var keyboardHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        inputView?.allowsSelfSizing = true

        let keyboard = DiagonalKeyboardView(
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
private final class DiagonalKeyboardModel: ObservableObject {
    enum InputMode { case kana, latin }

    @Published var inputMode: InputMode = .kana

    var characterColumns: [[FlowKey]] {
        inputMode == .kana ? Self.kanaCharacterColumns : Self.latinCharacterColumns
    }

    var utilityColumn: [FlowKey] {
        inputMode == .kana ? Self.kanaUtilityColumn : Self.latinUtilityColumn
    }

    // Read from top to bottom. The final rows are what appear nearest the
    // bottom at launch, so kana starts with:
    //   ま や ら
    //    か た は
    //     あ さ な
    //
    // The three character lanes are vertically staggered in the view.
    private static let kanaCharacterColumns: [[FlowKey]] = [
        ["わ","も","こ","お","め","け","え","む","く","う","み","き","い","ま","か","あ"].map(FlowKey.text),
        ["を","","と","そ","","て","せ","ゆ","つ","す","","ち","し","や","た","さ"].map(FlowKey.text),
        ["ん","ろ","ほ","の","れ","へ","ね","る","ふ","ぬ","り","ひ","に","ら","は","な"].map(FlowKey.text)
    ]

    // QWERTY rotated 90 degrees. At launch the bottom-most visible group is
    // qaz, with q lower-left, a in the middle, and z upper-right.
    // Above it come wsx, then edc, then rfv...
    private static let latinCharacterColumns: [[FlowKey]] = [
        ["p","o","i","u","y","t","r","e","w","q"].map(FlowKey.text),
        ["","l","k","j","h","g","f","d","s","a"].map(FlowKey.text),
        ["","","","m","n","b","v","c","x","z"].map(FlowKey.text)
    ]

    private static let kanaUtilityColumn: [FlowKey] = [
        .punctuation("！"),
        .punctuation("？"),
        .punctuation("。"),
        .punctuation("、"),
        .punctuation("ー"),
        .dakuten,
        .handakuten,
        .smallKana,
        .convert,
        .space,
        .backspace,
        .returnKey,
        .modeToggle
    ]

    private static let latinUtilityColumn: [FlowKey] = [
        .text("/"),
        .text("@"),
        .text("_"),
        .text("-"),
        .text("!"),
        .text("?"),
        .text("."),
        .text(","),
        .space,
        .backspace,
        .returnKey,
        .modeToggle
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

private struct DiagonalKeyboardView: View {
    @ObservedObject var model: DiagonalKeyboardModel
    let showGlobe: Bool
    let onKey: (FlowKey) -> Void
    let onNextKeyboard: () -> Void

    @State private var startTime = Date()

    private let speed: CGFloat = 132
    private let diagonalOffsets: [CGFloat] = [0, -51, -102]

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
                ForEach(0..<3, id: \.self) { index in
                    DiagonalConveyorColumn(
                        keys: model.characterColumns[index],
                        speed: speed,
                        laneYOffset: diagonalOffsets[index],
                        startTime: startTime,
                        mode: model.inputMode,
                        onTap: onKey
                    )
                }

                DiagonalConveyorColumn(
                    keys: model.utilityColumn,
                    speed: speed,
                    laneYOffset: 0,
                    startTime: startTime,
                    mode: model.inputMode,
                    onTap: onKey
                )
            }
            .padding(6)

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
        .onChange(of: model.inputMode) { _ in
            startTime = Date()
        }
    }
}

private struct DiagonalConveyorColumn: View {
    let keys: [FlowKey]
    let speed: CGFloat
    let laneYOffset: CGFloat
    let startTime: Date
    let mode: DiagonalKeyboardModel.InputMode
    let onTap: (FlowKey) -> Void

    private let keyHeight: CGFloat = 44
    private let spacing: CGFloat = 7

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { context in
                let stride = keyHeight + spacing
                let cycleHeight = max(CGFloat(keys.count) * stride, 1)
                let elapsed = max(context.date.timeIntervalSince(startTime), 0)
                let travel = (CGFloat(elapsed) * speed)
                    .truncatingRemainder(dividingBy: cycleHeight)

                // Put the final item of the middle copy near the bottom at t=0.
                let finalIndexInMiddleCopy = CGFloat(keys.count * 2 - 1)
                let targetFinalTop = geometry.size.height - keyHeight - 10 + laneYOffset
                let baseY = targetFinalTop - finalIndexInMiddleCopy * stride

                VStack(spacing: spacing) {
                    ForEach(0..<(keys.count * 3), id: \.self) { index in
                        let key = keys[index % keys.count]

                        if key.label.isEmpty {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: keyHeight)
                        } else {
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
                }
                .offset(y: baseY + travel)
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
            return .white.opacity(0.17)
        default:
            return .white.opacity(0.095)
        }
    }
}
