import XCTest
@testable import KeyboardCore

final class KanaKanjiEngineTests: XCTestCase {
    @MainActor func testEmptyInput() async {
        XCTAssertEqual(KanaKanjiEngine().candidates(for: ""), [])
    }
    @MainActor func testJapaneseDictionaryIsLoaded() async {
        let engine = KanaKanjiEngine()
        XCTAssertTrue(engine.candidates(for: "にほん").contains("日本"))
    }
    @MainActor func testKanaFallbackIsAlwaysAvailable() async {
        let engine = KanaKanjiEngine()
        XCTAssertTrue(engine.candidates(for: "くるくる").contains("くるくる"))
    }
    @MainActor func testResetAndSecondConversion() async {
        let engine = KanaKanjiEngine()
        _ = engine.candidates(for: "にほん")
        engine.endComposition()
        XCTAssertTrue(engine.candidates(for: "とうきょう").contains("東京"))
    }
}
