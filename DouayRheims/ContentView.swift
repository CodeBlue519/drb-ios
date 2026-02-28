import SwiftUI

// MARK: - Loading View (Fix 1)
// Simple 1998-style loading screen shown while TSV data is parsed off the main thread.

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Loading...")
                .font(.system(.body, design: .serif))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Root View

struct ContentView: View {
    @EnvironmentObject var bibleData: BibleDataManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if !bibleData.isLoaded {
            // Fix 1: Show loading screen while async parse runs off main thread
            LoadingView()
        } else if horizontalSizeClass == .regular {
            iPadContentView()
        } else {
            iPhoneContentView()
        }
    }
}

// MARK: - iPhone Layout (existing TabView)

struct iPhoneContentView: View {
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
                ReadingPlanView()
            }
            .tabItem {
                Label("Plan", systemImage: "calendar")
            }

            NavigationStack {
                BookmarksView()
            }
            .tabItem {
                Label("Bookmarks", systemImage: "bookmark")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "textformat.size")
            }
        }
        .tint(Theme.accent(colorScheme))
    }
}

// MARK: - iPad Layout (NavigationSplitView)

struct iPadContentView: View {
    @EnvironmentObject var bibleData: BibleDataManager
    @Environment(\.colorScheme) var colorScheme

    enum SidebarItem: Hashable {
        case book(Book)
        case search
        case readingPlan
        case bookmarks
        case settings
    }

    @State private var selectedSidebar: SidebarItem?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selectedSidebar) {
                Section {
                    Label("Search", systemImage: "magnifyingglass")
                        .tag(SidebarItem.search)
                    Label("Reading Plan", systemImage: "calendar")
                        .tag(SidebarItem.readingPlan)
                    Label("Bookmarks", systemImage: "bookmark")
                        .tag(SidebarItem.bookmarks)
                    Label("Settings", systemImage: "textformat.size")
                        .tag(SidebarItem.settings)
                }

                ForEach(Testament.allCases, id: \.self) { testament in
                    Section {
                        ForEach(bibleData.books.filter { $0.testament == testament }) { book in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.name)
                                        .font(Theme.serifBody(16))
                                        .foregroundColor(Theme.textPrimary(colorScheme))
                                    if Theme.deuterocanonical.contains(book.name) {
                                        Text("Deuterocanonical")
                                            .font(.caption2.weight(.medium))
                                            .foregroundColor(Theme.goldAccent(colorScheme))
                                    }
                                }
                                Spacer()
                                Text("\(book.chapters.count)")
                                    .font(Theme.serifItalic(13))
                                    .foregroundColor(.secondary)
                            }
                            .tag(SidebarItem.book(book))
                        }
                    } header: {
                        Text(testament.rawValue)
                            .font(Theme.serifBold(12))
                            .foregroundColor(Theme.accent(colorScheme))
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background(colorScheme))
            .navigationTitle("Douay-Rheims")
        } detail: {
            NavigationStack {
                Group {
                    switch selectedSidebar {
                    case .book(let book):
                        ChapterListView(book: book)
                    case .search:
                        SearchView()
                    case .readingPlan:
                        ReadingPlanView()
                    case .bookmarks:
                        BookmarksView()
                    case .settings:
                        SettingsView()
                    case nil:
                        VStack(spacing: 16) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 56))
                                .foregroundColor(Theme.accent(colorScheme).opacity(0.4))
                                .accessibilityHidden(true)
                            Text("Select a book to begin reading")
                                .font(Theme.serifItalic(18))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.background(colorScheme))
                    }
                }
            }
        }
        .tint(Theme.accent(colorScheme))
        .navigationSplitViewStyle(.balanced)
    }
}
