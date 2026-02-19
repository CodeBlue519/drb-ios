import SwiftUI

struct BookListView: View {
    @EnvironmentObject var bibleData: BibleDataManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            ForEach(Testament.allCases, id: \.self) { testament in
                Section {
                    ForEach(bibleData.books.filter { $0.testament == testament }) { book in
                        NavigationLink(destination: ChapterListView(book: book)) {
                            HStack {
                                Text(book.name)
                                    .font(Theme.serifBody(17))
                                    .foregroundColor(Theme.textPrimary(colorScheme))
                                Spacer()
                                Text("\(book.chapters.count)")
                                    .font(Theme.serifItalic(14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(testament.rawValue)
                        .font(Theme.serifBold(13))
                        .foregroundColor(Theme.accent(colorScheme))
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Douay-Rheims Bible")
        .scrollContentBackground(.hidden)
        .background(Theme.background(colorScheme))
    }
}
