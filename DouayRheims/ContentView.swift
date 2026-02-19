import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        TabView {
            NavigationStack {
                BookListView()
            }
            .tabItem {
                Label("Bible", systemImage: "book.closed")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationStack {
                BookmarksView()
            }
            .tabItem {
                Label("Bookmarks", systemImage: "bookmark")
            }
        }
        .tint(Theme.accent(colorScheme))
    }
}
