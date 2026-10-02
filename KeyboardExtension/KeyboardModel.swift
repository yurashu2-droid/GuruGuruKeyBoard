import SwiftUI
import Combine

@MainActor
final class KeyboardModel: ObservableObject {
    enum InputMode { case kana, latin }

    @Published var composition = ""
    @Published var candidates: [String] = []
    @Published var inputMode: InputMode = .kana

    var characterColumns: [[FlowKey]] {
        inputMode == .kana ? Self.kanaCharacterColumns : Self.latinCharacterColumns
    }

    var utilityColumn: [FlowKey] {
        inputMode == .kana ? Self.kanaUtilityColumn : Self.latinUtilityColumn
    }

    private static let kanaCharacterColumns: [[FlowKey]] = [
        ["わ","も","こ","お","め","け","え","む","く","う","み","き","い","ま","か","あ"].map(FlowKey.text),
        ["を","","と","そ","","て","せ","ゆ","つ","す","","ち","し","や","た","さ"].map(FlowKey.text),
        ["ん","ろ","ほ","の","れ","へ","ね","る","ふ","ぬ","り","ひ","に","ら","は","な"].map(FlowKey.text)
    ]

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
