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
    private var versesByBook: [String: [Verse]] = [:]

    private init() {
        loadData()
    }

    private func loadData() {
        guard let url = Bundle.main.url(forResource: "drb", withExtension: "tsv"),
              let data = try? String(contentsOf: url, encoding: .utf8) else {
            return
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
                text: text
            )
            verses.append(verse)

            if var info = bookChapters[bookName] {
                info.chapters.insert(chapter)
                bookChapters[bookName] = info
            } else {
                bookChapters[bookName] = (abbrev, bookOrder, [chapter])
            }
        }

        allVerses = verses
        for verse in verses {
            versesByBook[verse.bookName, default: []].append(verse)
        }

        // New Testament starts at Matthew (book 47)
        books = bookChapters.map { name, info in
            Book(
                id: name,
                name: name,
                abbreviation: info.abbrev,
                order: info.order,
                chapters: info.chapters.sorted(),
                testament: info.order >= 47 ? .newTestament : .oldTestament
            )
        }.sorted { $0.order < $1.order }

        isLoaded = true
    }

    func verses(for book: String, chapter: Int) -> [Verse] {
        (versesByBook[book] ?? [])
            .filter { $0.chapter == chapter }
            .sorted { $0.verse < $1.verse }
    }

    func search(_ query: String, limit: Int = 100) -> [Verse] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()
        var results: [Verse] = []
        for verse in allVerses {
            if verse.text.lowercased().contains(lowered) ||
               verse.bookName.lowercased().contains(lowered) {
                results.append(verse)
                if results.count >= limit { break }
            }
        }
        return results
    }

    func verse(for id: String) -> Verse? {
        allVerses.first { $0.id == id }
    }
}
