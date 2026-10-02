import SwiftUI
import Combine

@MainActor
final class KeyboardModel: ObservableObject {
    enum InputMode { case kana, latin }
    @Published var composition = ""
    @Published var candidates: [String] = []
    @Published var inputMode: InputMode = .kana
    @Published var isPaused = false
    @Published var speed: CGFloat = 52
    let kanaRows = [
        ["あ","い","う","え","お","か","き","く","け","こ","さ","し","す","せ","そ"],
        ["た","ち","つ","て","と","な","に","ぬ","ね","の","は","ひ","ふ","へ","ほ"],
        ["ま","み","む","め","も","や","ゆ","よ","ら","り","る","れ","ろ","わ","を","ん"]
    ]
    let latinRows = [Array("qwertyuiop").map(String.init), Array("asdfghjkl").map(String.init), Array("zxcvbnm").map(String.init)]
    var rows: [[String]] { inputMode == .kana ? kanaRows : latinRows }
    func cycleSpeed() {
        switch speed {
        case ..<40: speed = 52
        case ..<70: speed = 82
        default: speed = 30
        }
    }
    var speedLabel: String {
        switch speed {
        case ..<40: return "0.6×"
        case ..<70: return "1×"
        default: return "1.6×"
        }
    }
}
