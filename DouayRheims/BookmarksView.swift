import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var bibleData: BibleDataManager
    @EnvironmentObject var bookmarks: BookmarkManager
    @Environment(\.colorScheme) var colorScheme

    private var bookmarkedVerses: [Verse] {
        bookmarks.bookmarkedVerseIDs.compactMap { bibleData.verse(for: $0) }
            .sorted { ($0.bookOrder, $0.chapter, $0.verse) < ($1.bookOrder, $1.chapter, $1.verse) }
    }

    var body: some View {
        Group {
            if bookmarkedVerses.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.accent(colorScheme).opacity(0.4))
                    Text("No Bookmarks Yet")
                        .font(Theme.serifBold(20))
                        .foregroundColor(Theme.textPrimary(colorScheme))
                    Text("Long press any verse to bookmark it.")
                        .font(Theme.serifItalic(16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background(colorScheme))
            } else {
                List {
                    ForEach(bookmarkedVerses) { verse in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verse.reference)
                                .font(Theme.serifBold(14))
                                .foregroundColor(Theme.accent(colorScheme))

                            Text(verse.text)
                                .font(Theme.serifBody(16))
                                .foregroundColor(Theme.textPrimary(colorScheme))
                                .lineSpacing(3)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                bookmarks.toggle(verse.id)
                            } label: {
                                Label("Remove", systemImage: "bookmark.slash")
                            }
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = "\(verse.reference)\n\(verse.text)"
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            ShareLink(item: "\(verse.reference)\n\(verse.text)") {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            Button(role: .destructive) {
                                bookmarks.toggle(verse.id)
                            } label: {
                                Label("Remove Bookmark", systemImage: "bookmark.slash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Theme.background(colorScheme))
            }
        }
        .navigationTitle("Bookmarks")
    }
}
