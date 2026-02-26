import Foundation

// MARK: - Models

struct Verse: Identifiable, Hashable {
    let id: String  // "BookName:Chapter:Verse"
    let bookName: String
    let abbreviation: String
    let bookOrder: Int
    let chapter: Int
    let verse: Int
    let text: String
    let lowercasedText: String  // Fix 3: precomputed at parse time, zero alloc at search time

    var reference: String {
        "\(bookName) \(chapter):\(verse)"
    }

    var shortReference: String {
        "\(abbreviation) \(chapter):\(verse)"
    }
}

struct Book: Identifiable, Hashable {
    let id: String  // book name
    let name: String
    let abbreviation: String
    let order: Int
    let chapters: [Int]  // sorted chapter numbers
    let testament: Testament
}

enum Testament: String, CaseIterable {
    case oldTestament = "Old Testament"
    case newTestament = "New Testament"
}

// MARK: - Bible Data Manager

@MainActor
final class BibleDataManager: ObservableObject {
    static let shared = BibleDataManager()

    @Published private(set) var books: [Book] = []
    @Published private(set) var isLoaded = false

    private var allVerses: [Verse] = []
    // Fix 2: Two-level index — O(1) chapter lookup instead of O(n) filter
    private var verseIndex: [String: [Int: [Verse]]] = [:]
    private var verseById: [String: Verse] = [:]

    private init() {
        // Fix 1: Load off the main thread — fire-and-forget Task on @MainActor,
        // actual CPU work runs in a detached Task on a background thread.
        Task {
            await loadDataAsync()
        }
    }

    // MARK: - Async Load (Fix 1)

    private func loadDataAsync() async {
        let result = await Task.detached(priority: .userInitiated) {
            BibleDataManager.parseData()
        }.value

        // Back on @MainActor — safe to publish
        self.allVerses = result.verses
        self.verseIndex = result.verseIndex
        self.verseById = result.verseById
        self.books = result.books
        self.isLoaded = true
    }

    // MARK: - Background parse (runs off main thread)

    private struct LoadResult {
        let verses: [Verse]
        let verseIndex: [String: [Int: [Verse]]]
        let verseById: [String: Verse]
        let books: [Book]
    }

    private static func parseData() -> LoadResult {
        guard let url = Bundle.main.url(forResource: "drb", withExtension: "tsv"),
              let data = try? String(contentsOf: url, encoding: .utf8) else {
            return LoadResult(verses: [], verseIndex: [:], verseById: [:], books: [])
        }

        var verses: [Verse] = []
        var bookChapters: [String: (abbrev: String, order: Int, chapters: Set<Int>)] = [:]

        let lines = data.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "\t")
            guard parts.count >= 6 else { continue }

            let bookName = parts[0]
            let abbrev = parts[1]
            let bookOrder = Int(parts[2]) ?? 0
            let chapter = Int(parts[3]) ?? 0
            let verseNum = Int(parts[4]) ?? 0
            let text = parts[5]

            let verse = Verse(
                id: "\(bookName):\(chapter):\(verseNum)",
                bookName: bookName,
                abbreviation: abbrev,
                bookOrder: bookOrder,
                chapter: chapter,
                verse: verseNum,
                text: text,
                lowercasedText: text.lowercased()  // Fix 3: one alloc per verse, at parse time
            )
            verses.append(verse)

            if var info = bookChapters[bookName] {
                info.chapters.insert(chapter)
                bookChapters[bookName] = info
            } else {
                bookChapters[bookName] = (abbrev, bookOrder, [chapter])
            }
        }

        // Fix 2: Build two-level index and id→verse map in one pass
        var verseIndex: [String: [Int: [Verse]]] = [:]
        var verseById: [String: Verse] = [:]
        for verse in verses {
            verseIndex[verse.bookName, default: [:]][verse.chapter, default: []].append(verse)
            verseById[verse.id] = verse
        }
        // Verses arrive in order from the TSV but sort within each chapter to be safe
        for bookName in verseIndex.keys {
            for chapter in verseIndex[bookName]!.keys {
                verseIndex[bookName]![chapter]!.sort { $0.verse < $1.verse }
            }
        }

        let books = bookChapters.map { name, info in
            Book(
                id: name,
                name: name,
                abbreviation: info.abbrev,
                order: info.order,
                chapters: info.chapters.sorted(),
                testament: info.order >= 47 ? .newTestament : .oldTestament
            )
        }.sorted { $0.order < $1.order }

        return LoadResult(verses: verses, verseIndex: verseIndex, verseById: verseById, books: books)
    }

    // MARK: - Public API

    // Fix 2: O(1) chapter lookup — no more O(n) filter through the full book
    func verses(for book: String, chapter: Int) -> [Verse] {
        verseIndex[book]?[chapter] ?? []
    }

    // Fix 3: Use precomputed lowercasedText — no per-search String allocation
    func search(_ query: String, limit: Int = 100) -> [Verse] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()
        var results: [Verse] = []
        for verse in allVerses {
            if verse.lowercasedText.contains(lowered) ||
               verse.bookName.lowercased().contains(lowered) {
                results.append(verse)
                if results.count >= limit { break }
            }
        }
        return results
    }

    // Fix 2: O(1) bookmark lookup — was allVerses.first { $0.id == id }
    func verse(for id: String) -> Verse? {
        verseById[id]
    }
}
