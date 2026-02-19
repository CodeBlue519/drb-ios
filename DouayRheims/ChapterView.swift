import SwiftUI

struct ChapterView: View {
    let book: Book
    let chapter: Int

    @EnvironmentObject var bibleData: BibleDataManager
    @EnvironmentObject var bookmarks: BookmarkManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let verses = bibleData.verses(for: book.name, chapter: chapter)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Chapter header
                Text("\(book.name)")
                    .font(Theme.serifBold(24))
                    .foregroundColor(Theme.accent(colorScheme))
                    .padding(.bottom, 2)
                Text("Chapter \(chapter)")
                    .font(Theme.serifItalic(18))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)

                // Verses as flowing text
                ForEach(verses) { verse in
                    VerseRow(verse: verse)
                        .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("\(book.abbreviation) \(chapter)")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.background(colorScheme))
    }
}

struct VerseRow: View {
    let verse: Verse
    @EnvironmentObject var bookmarks: BookmarkManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(verse.verse) ")
                .font(Theme.serifBold(12))
                .foregroundColor(Theme.accent(colorScheme))
                .baselineOffset(4)

            Text(verse.text)
                .font(Theme.serifBody(18))
                .foregroundColor(Theme.textPrimary(colorScheme))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                bookmarks.toggle(verse.id)
            } label: {
                Label(
                    bookmarks.isBookmarked(verse.id) ? "Remove Bookmark" : "Bookmark",
                    systemImage: bookmarks.isBookmarked(verse.id) ? "bookmark.slash" : "bookmark"
                )
            }

            Button {
                UIPasteboard.general.string = "\(verse.reference)\n\(verse.text)"
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            ShareLink(item: "\(verse.reference)\n\(verse.text)") {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .overlay(alignment: .trailing) {
            if bookmarks.isBookmarked(verse.id) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.accent(colorScheme))
                    .offset(x: 4)
            }
        }
    }
}
