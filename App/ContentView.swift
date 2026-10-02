import SwiftUI

struct ContentView: View {
    @State private var testText = ""
    private let rows = [Array("あいうえおかきくけこさしすせそ").map(String.init), Array("たちつてとなにぬねのはひふへほ").map(String.init), Array("まみむめもやゆよらりるれろわをん").map(String.init)]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("くるくるキーボード").font(.system(size: 32, weight: .black, design: .rounded))
                        Text("文字のほうが流れてくる、日本語キーボード。")
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 10) {
                        ForEach(rows.indices, id: \.self) { index in
                            PreviewConveyorRow(keys: rows[index], direction: index == 1 ? -1 : 1)
                        }
                    }
                    .padding(.vertical, 14).background(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    VStack(alignment: .leading, spacing: 12) {
                        Label("iPhoneに追加する", systemImage: "keyboard").font(.title3.bold())
                        Text("1. 設定 → 一般 → キーボード → キーボード")
                        Text("2. 新しいキーボードを追加 →「くるくる」")
                        Text("3. 入力欄で地球儀を長押しして「くるくる」を選択")
                        Text("フルアクセスは不要です。変換は端末内で行います。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding().background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ここで入力を試す").font(.headline)
                        TextEditor(text: $testText)
                            .frame(minHeight: 110).padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.35)))
                        Text("かなはキーボード上で編集中になります。候補をタップ、または変換キーで確定してください。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Text("停止・再開 / 3段階速度 / かな・ABC / 濁点・半濁点・小文字 / 日本語変換")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("試作版 0.1.1 · 非公式の独立したアプリです。")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(20)
            }.navigationBarTitleDisplayMode(.inline)
        }
    }
}
private struct PreviewConveyorRow: View {
    let keys: [String]
    let direction: CGFloat
    var body: some View {
        GeometryReader { _ in
            TimelineView(.animation) { context in
                let rowWidth = CGFloat(keys.count) * 50
                let travel = (CGFloat(context.date.timeIntervalSinceReferenceDate) * 42).truncatingRemainder(dividingBy: rowWidth)
                let x = direction > 0 ? -rowWidth + travel : -travel
                HStack(spacing: 8) {
                    ForEach(0..<(keys.count * 3), id: \.self) { i in
                        Text(keys[i % keys.count]).font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white).frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }.offset(x: x)
            }
        }.frame(height: 42).clipped()
    }
}
