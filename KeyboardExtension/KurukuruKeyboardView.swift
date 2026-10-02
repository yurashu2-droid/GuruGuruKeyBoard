import SwiftUI

enum FlowKey: Hashable {
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

struct KurukuruKeyboardView: View {
    @ObservedObject var model: KeyboardModel
    let showGlobe: Bool
    let onKey: (FlowKey) -> Void
    let onNextKeyboard: () -> Void

    @State private var startTime = Date()

    private let speed: CGFloat = 132
    private let diagonalOffsets: [CGFloat] = [20, 0, -20]

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
    let mode: KeyboardModel.InputMode
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
