import SwiftUI
import Combine

@MainActor
final class KeyboardModel: ObservableObject {
    enum InputMode { case kana, latin }

    @Published var composition = ""
    @Published var candidates: [String] = []
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
