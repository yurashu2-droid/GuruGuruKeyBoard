import UIKit
import SwiftUI

@MainActor
final class KeyboardViewController: UIInputViewController {
    private let model = KeyboardModel()
    private let engine = KanaKanjiEngine()
    private var keyboardHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        inputView?.allowsSelfSizing = true

        let keyboard = KurukuruKeyboardView(
            model: model,
            showGlobe: needsInputModeSwitchKey,
            onKey: { [weak self] key in self?.handle(key) },
            onNextKeyboard: { [weak self] in
                guard let self else { return }
                self.commitRawCompositionIfNeeded()
                self.advanceToNextInputMode()
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clearComposition()
    }

    override func textWillChange(_ textInput: (any UITextInput)?) {
        clearComposition()
    }

    private func handle(_ key: FlowKey) {
        switch key {
        case .text(let text):
            handleCharacter(text)
        case .backspace:
            handleBackspace()
        case .space:
            flushCompositionIfNeeded()
            textDocumentProxy.insertText(" ")
        case .returnKey:
            flushCompositionIfNeeded()
            textDocumentProxy.insertText("\n")
        case .modeToggle:
            commitRawCompositionIfNeeded()
            model.inputMode = model.inputMode == .kana ? .latin : .kana
        case .dakuten:
            transformLast(using: Self.dakutenMap)
        case .handakuten:
            transformLast(using: Self.handakutenMap)
        case .smallKana:
            transformLast(using: Self.smallKanaMap)
        case .convert:
            handleConvert()
        case .punctuation(let text):
            commitBestThenInsert(text)
        }
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

        if model.composition.count >= 64 {
            commitCandidate(model.composition)
        }
        model.composition.append(text)
        refreshCandidates()
    }

    private func handleBackspace() {
        guard !model.composition.isEmpty else {
            textDocumentProxy.deleteBackward()
            return
        }

        model.composition.removeLast()
        if model.composition.isEmpty {
            clearComposition()
        } else {
            refreshCandidates()
        }
    }

    private func handleConvert() {
        guard !model.composition.isEmpty else { return }
        commitCandidate(model.candidates.first ?? model.composition)
    }

    private func refreshCandidates() {
        model.candidates = engine.candidates(for: model.composition)
    }

    private func commitCandidate(_ candidate: String) {
        clearComposition()
        textDocumentProxy.insertText(candidate)
    }

    private func commitRawCompositionIfNeeded() {
        guard !model.composition.isEmpty else { return }
        commitCandidate(model.composition)
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
