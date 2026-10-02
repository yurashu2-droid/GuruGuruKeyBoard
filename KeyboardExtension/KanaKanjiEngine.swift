import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary

/// Adapter for the pinned azooKey 0.11.2 API. No network or user learning.
///
/// Important: a custom keyboard extension has a tight memory budget. Keep both
/// the converter and its dictionaries out of the extension launch path.
/// azooKey itself lazily creates its converter for the same reason.
@MainActor
final class KanaKanjiEngine {
    private var converterHasStarted = false

    private lazy var converter = KanaKanjiConverter.withDefaultDictionary()

    private lazy var options: ConvertRequestOptions = {
        let directory = FileManager.default.temporaryDirectory
        return ConvertRequestOptions(
            N_best: 10,
            requireJapanesePrediction: true,
            requireEnglishPrediction: false,
            keyboardLanguage: .ja_JP,
            englishCandidateInRoman2KanaInput: false,
            fullWidthRomanCandidate: false,
            halfWidthKanaCandidate: false,
            learningType: .nothing,
            maxMemoryCount: 0,
            memoryDirectoryURL: directory,
            sharedContainerURL: directory,
            textReplacer: .withDefaultEmojiDictionary(),
            specialCandidateProviders: nil,
            zenzaiMode: .off,
            metadata: .init(versionString: "GuruGuruKeyBoard 0.1.2")
        )
    }()

    func candidates(for reading: String) -> [String] {
        guard !reading.isEmpty else { return [] }

        // This is the first point at which loading the conversion dictionary is
        // allowed. Selecting the keyboard must be able to render before this.
        converterHasStarted = true

        var composing = ComposingText()
        composing.insertAtCursorPosition(reading, inputStyle: .direct)
        let result = converter.requestCandidates(composing, options: options)
        var seen = Set<String>()

        // The MVP commits a whole reading, not a first-clause prefix.
        // Ask ComposingText to consume the count: it can be an input count,
        // a displayed-surface count, or a composite of both.
        var values = result.mainResults
            .filter { candidate in
                guard candidate.inputable else { return false }
                var remaining = composing
                remaining.prefixComplete(composingCount: candidate.composingCount)
                return remaining.isEmpty
            }
            .map(\.text)
            .filter { !$0.isEmpty && $0 != reading && seen.insert($0).inserted }
            .prefix(11)
            .map { $0 }
        values.append(reading)
        return values
    }

    func endComposition() {
        // UIKit can call textWillChange while the keyboard is being activated.
        // Do not accidentally initialize the converter from that lifecycle path.
        guard converterHasStarted else { return }
        converter.stopComposition()
    }
}
