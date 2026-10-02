import SwiftUI

struct ContentView: View {
    @State private var testText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("くるくるキーボード")
                        .font(.system(size: 32, weight: .black, design: .rounded))

                    Text("0.1.4は4種類を同梱した診断版です。設定から全部追加して、地球儀長押しで切り替えられます。")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        VariantRow(name: "くるくる Safe", detail: "固定UIKit。起動できる基準")
                        VariantRow(name: "くるくる Move", detail: "UIKit + CADisplayLink。文字が流れる本命")
                        VariantRow(name: "くるくる SwiftUI", detail: "SwiftUIで文字が流れる。変換なし")
                        VariantRow(name: "くるくる IME", detail: "SwiftUI + azooKeyかな漢字変換")
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 10) {
                        Label("追加方法", systemImage: "keyboard")
                            .font(.headline)
                        Text("設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加")
                        Text("4種類を全部追加して、入力欄で🌐を長押しして切り替えます。")
                        Text("フルアクセスは不要です。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    TextEditor(text: $testText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.35)))

                    Text("試作版 0.1.4 · 診断用マルチキーボード")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
        }
    }
}

private struct VariantRow: View {
    let name: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
