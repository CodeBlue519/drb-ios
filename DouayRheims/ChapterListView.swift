import SwiftUI

struct ChapterListView: View {
    let book: Book
    @Environment(\.colorScheme) var colorScheme

    private let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(book.chapters, id: \.self) { chapter in
                    NavigationLink(destination: ChapterView(book: book, chapter: chapter)) {
                        Text("\(chapter)")
                            .font(Theme.serifBody(18))
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Theme.accent(colorScheme).opacity(0.1))
                            )
                            .foregroundColor(Theme.textPrimary(colorScheme))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(book.name)
        .background(Theme.background(colorScheme))
    }
}
