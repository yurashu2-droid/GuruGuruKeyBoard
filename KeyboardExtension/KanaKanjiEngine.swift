import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary

/// Adapter for the pinned azooKey 0.11.2 API. No network or user learning.
@MainActor
final class KanaKanjiEngine {
    private let converter = KanaKanjiConverter.withDefaultDictionary()
    private let options: ConvertRequestOptions
    init() {
        let directory = FileManager.default.temporaryDirectory
        options = ConvertRequestOptions(
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
            metadata: .init(versionString: "GuruGuruKeyBoard 0.1.1")
        )
    }
    func candidates(for reading: String) -> [String] {
        guard !reading.isEmpty else { return [] }
        var composing = ComposingText()
        composing.insertAtCursorPosition(reading, inputStyle: .direct)
        let result = converter.requestCandidates(composing, options: options)
        var seen = Set<String>()
        // The MVP commits a whole reading, not a first-clause prefix.
        var values = result.mainResults
            .filter { $0.correspondingCount == composing.input.count }
            .map(\.text)
            .filter { !$0.isEmpty && $0 != reading && seen.insert($0).inserted }
            .prefix(11)
            .map { $0 }
        values.append(reading)
        return values
    }
    func endComposition() { converter.stopComposition() }
}
