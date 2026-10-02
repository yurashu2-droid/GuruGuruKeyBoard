import SwiftUI
import Combine

struct KurukuruKeyboardView: View {
    @ObservedObject var model: KeyboardModel
    let onCharacter: (String) -> Void
    let onBackspace: () -> Void
    let onSpace: () -> Void
    let onReturn: () -> Void
    let onCandidate: (String) -> Void
    let onNextKeyboard: () -> Void
    let onDakuten: () -> Void
    let onHandakuten: () -> Void
    let onSmallKana: () -> Void
    let onPunctuation: (String) -> Void
    let onModeChange: () -> Void
    @State private var distance: CGFloat = 0
    @State private var lastTick: Date?
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 6) {
            Text(model.composition.isEmpty ? "文字が流れてきます" : model.composition)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            topStrip
            ForEach(model.rows.indices, id: \.self) { index in
                ConveyorRow(keys: model.rows[index], distance: distance * (index == 1 ? 0.88 : 1), direction: index == 1 ? -1 : 1, phase: CGFloat(index) * 86, onTap: onCharacter)
            }
            HStack(spacing: 6) {
                MiniKey(title: "゛", action: onDakuten)
                MiniKey(title: "゜", action: onHandakuten)
                MiniKey(title: "小", action: onSmallKana)
                MiniKey(title: "ー") { onCharacter("ー") }
                MiniKey(title: "、") { onPunctuation("、") }
                MiniKey(title: "。") { onPunctuation("。") }
            }.frame(height: 31)
            controlStrip
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(LinearGradient(colors: [Color(red: 0.035, green: 0.04, blue: 0.05), Color(red: 0.075, green: 0.08, blue: 0.10)], startPoint: .top, endPoint: .bottom))
        .onReceive(timer) { now in
            let delta = min(max(now.timeIntervalSince(lastTick ?? now), 0), 0.1)
            lastTick = now
            if !model.isPaused { distance += CGFloat(delta) * model.speed }
        }
        .onDisappear { lastTick = nil }
    }
    private var topStrip: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if model.candidates.isEmpty {
                        Text("かな → 候補をタップして確定")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                    }
                    ForEach(model.candidates, id: \.self) { candidate in
                        Button(candidate) { onCandidate(candidate) }
                            .buttonStyle(CandidateButtonStyle())
                    }
                }
            }.frame(height: 34)
            Button { model.isPaused.toggle() } label: {
                Image(systemName: model.isPaused ? "play.fill" : "pause.fill").frame(width: 34, height: 34)
            }.buttonStyle(ToolButtonStyle())
            Button { model.cycleSpeed() } label: {
                Text(model.speedLabel).font(.system(size: 11, weight: .bold)).frame(width: 40, height: 34)
            }.buttonStyle(ToolButtonStyle())
        }
    }
    private var controlStrip: some View {
        HStack(spacing: 6) {
            Button(action: onNextKeyboard) {
                Image(systemName: "globe").frame(width: 36, height: 42)
            }.buttonStyle(ControlButtonStyle())
            Button(action: onModeChange) {
                Text(model.inputMode == .kana ? "ABC" : "かな").font(.system(size: 12, weight: .bold)).frame(width: 44, height: 42)
            }.buttonStyle(ControlButtonStyle())
            Button(action: onSpace) {
                Text(model.composition.isEmpty ? "空白" : "変換 / 確定")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 42)
            }.buttonStyle(ControlButtonStyle())
            Button(action: onBackspace) {
                Image(systemName: "delete.left").frame(width: 44, height: 42)
            }.buttonStyle(ControlButtonStyle())
            Button(action: onReturn) {
                Image(systemName: "return").frame(width: 42, height: 42)
            }.buttonStyle(ControlButtonStyle())
        }
    }
}

private struct ConveyorRow: View {
    let keys: [String]
    let distance: CGFloat
    let direction: CGFloat
    let phase: CGFloat
    let onTap: (String) -> Void
    private let keyWidth: CGFloat = 44
    private let spacing: CGFloat = 8
    var body: some View {
        GeometryReader { _ in
            let rowWidth = CGFloat(keys.count) * (keyWidth + spacing)
            let travel = (distance + phase).truncatingRemainder(dividingBy: rowWidth)
            let x = direction > 0 ? -rowWidth + travel : -travel
            HStack(spacing: spacing) {
                ForEach(0..<(keys.count * 3), id: \.self) { index in
                    let key = keys[index % keys.count]
                    Button { onTap(key) } label: {
                        Text(key)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: keyWidth, height: 43)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.105)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.16), lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }.offset(x: x)
        }
        .frame(height: 43)
        .clipped()
    }
}
private struct MiniKey: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 13, weight: .bold)).frame(maxWidth: .infinity).frame(height: 31)
        }.buttonStyle(ToolButtonStyle())
    }
}
private struct CandidateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
            .padding(.horizontal, 13).frame(height: 34)
            .background(RoundedRectangle(cornerRadius: 11).fill(.white.opacity(configuration.isPressed ? 0.22 : 0.10)))
    }
}
private struct ToolButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(.white.opacity(0.92))
            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(configuration.isPressed ? 0.18 : 0.08)))
    }
}
private struct ControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 11).fill(.white.opacity(configuration.isPressed ? 0.22 : 0.12)))
    }
}
