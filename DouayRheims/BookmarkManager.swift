import Foundation
import SwiftUI

@MainActor
final class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    @Published private(set) var bookmarkedVerseIDs: Set<String> = []

    private let key = "bookmarked_verses"

    private init() {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            bookmarkedVerseIDs = Set(saved)
        }
    }

    func isBookmarked(_ verseID: String) -> Bool {
        bookmarkedVerseIDs.contains(verseID)
    }

    func toggle(_ verseID: String) {
        if bookmarkedVerseIDs.contains(verseID) {
            bookmarkedVerseIDs.remove(verseID)
        } else {
            bookmarkedVerseIDs.insert(verseID)
        }
        save()
    }

    private func save() {
        UserDefaults.standard.set(Array(bookmarkedVerseIDs), forKey: key)
    }
}
