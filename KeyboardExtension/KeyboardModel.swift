import SwiftUI
import Combine

@MainActor
final class KeyboardModel: ObservableObject {
    enum InputMode { case kana, latin }

    @Published var composition = ""
    @Published var candidates: [String] = []
    @Published var inputMode: InputMode = .kana

    var columns: [[FlowKey]] {
        inputMode == .kana ? Self.kanaColumns : Self.latinColumns
    }

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
