import UIKit
import SwiftUI

@MainActor
final class KeyboardViewController: UIInputViewController {
    private let model = KeyboardModel()
    private let engine = KanaKanjiEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let keyboard = KurukuruKeyboardView(
            model: model,
            onCharacter: { [weak self] in self?.handleCharacter($0) },
            onBackspace: { [weak self] in self?.handleBackspace() },
            onSpace: { [weak self] in self?.handleSpace() },
            onReturn: { [weak self] in self?.handleReturn() },
            onCandidate: { [weak self] in self?.commitCandidate($0) },
            onNextKeyboard: { [weak self] in
                guard let self else { return }
                if !self.model.composition.isEmpty { self.commitCandidate(self.model.composition) }
                self.advanceToNextInputMode()
            },
            onDakuten: { [weak self] in self?.transformLast(using: Self.dakutenMap) },
            onHandakuten: { [weak self] in self?.transformLast(using: Self.handakutenMap) },
            onSmallKana: { [weak self] in self?.transformLast(using: Self.smallKanaMap) },
            onPunctuation: { [weak self] in self?.commitBestThenInsert($0) },
            onModeChange: { [weak self] in
                guard let self else { return }
                if !self.model.composition.isEmpty { self.commitCandidate(self.model.composition) }
                self.model.inputMode = self.model.inputMode == .kana ? .latin : .kana
            }
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
        let height = view.heightAnchor.constraint(equalToConstant: 302)
        height.priority = .defaultHigh
        height.isActive = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clearComposition()
    }
    override func textWillChange(_ textInput: (any UITextInput)?) {
        // Do not carry pending text across changes initiated by a host app.
        clearComposition()
    }
    private func clearComposition() {
        model.composition = ""
        model.candidates = []
        engine.endComposition()
    }
    private func handleCharacter(_ text: String) {
        if model.inputMode == .latin {
            flushCompositionIfNeeded()
            textDocumentProxy.insertText(text)
            return
        }
        // Pending kana lives in the extension. Never backspace a host document
        // using an assumed reading length: its caret or field may have changed.
        if model.composition.count >= 64 { commitCandidate(model.composition) }
        model.composition.append(text)
        refreshCandidates()
    }
    private func handleBackspace() {
        guard !model.composition.isEmpty else {
            textDocumentProxy.deleteBackward()
            return
        }
        model.composition.removeLast()
        if model.composition.isEmpty { clearComposition() }
        else { refreshCandidates() }
    }
    private func handleSpace() {
        if let best = model.candidates.first, !model.composition.isEmpty { commitCandidate(best) }
        else { textDocumentProxy.insertText(" ") }
    }
    private func handleReturn() {
        if let best = model.candidates.first, !model.composition.isEmpty { commitCandidate(best) }
        else { textDocumentProxy.insertText("\n") }
    }
    private func refreshCandidates() { model.candidates = engine.candidates(for: model.composition) }
    private func commitCandidate(_ candidate: String) {
        // Clear state before insertion, because a host may synchronously call back.
        clearComposition()
        textDocumentProxy.insertText(candidate)
    }
    private func flushCompositionIfNeeded() {
        guard !model.composition.isEmpty else { return }
        commitCandidate(model.candidates.first ?? model.composition)
    }
    private func commitBestThenInsert(_ text: String) {
        flushCompositionIfNeeded()
        textDocumentProxy.insertText(text)
    }
    private func transformLast(using map: [Character: Character]) {
        guard let old = model.composition.last, let replacement = map[old] else { return }
        model.composition.removeLast()
        model.composition.append(replacement)
        refreshCandidates()
    }
    private static let dakutenMap: [Character: Character] = [
        "か":"が","き":"ぎ","く":"ぐ","け":"げ","こ":"ご",
        "さ":"ざ","し":"じ","す":"ず","せ":"ぜ","そ":"ぞ",
        "た":"だ","ち":"ぢ","つ":"づ","て":"で","と":"ど",
        "は":"ば","ひ":"び","ふ":"ぶ","へ":"べ","ほ":"ぼ","う":"ゔ"
    ]
    private static let handakutenMap: [Character: Character] = [
        "は":"ぱ","ひ":"ぴ","ふ":"ぷ","へ":"ぺ","ほ":"ぽ",
        "ば":"ぱ","び":"ぴ","ぶ":"ぷ","べ":"ぺ","ぼ":"ぽ"
    ]
    private static let smallKanaMap: [Character: Character] = [
        "あ":"ぁ","い":"ぃ","う":"ぅ","え":"ぇ","お":"ぉ",
        "つ":"っ","や":"ゃ","ゆ":"ゅ","よ":"ょ","わ":"ゎ"
    ]
}
