import SwiftUI
import WebKit
import Combine

// MARK: - WebViewStore

/// Observable object wrapping a WKWebView, publishing navigation state updates.
final class WebViewStore: ObservableObject {
    let webView: WKWebView

    @Published var pageTitle: String = ""
    @Published var pageURL: String = ""
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0

    private var observations: [NSKeyValueObservation] = []

    init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        setupObservations()
    }

    private func setupObservations() {
        observations = [
            webView.observe(\.title, options: .new) { [weak self] webView, _ in
                DispatchQueue.main.async { self?.pageTitle = webView.title ?? "" }
            },
            webView.observe(\.url, options: .new) { [weak self] webView, _ in
                DispatchQueue.main.async { self?.pageURL = webView.url?.absoluteString ?? "" }
            },
            webView.observe(\.canGoBack, options: .new) { [weak self] webView, _ in
                DispatchQueue.main.async { self?.canGoBack = webView.canGoBack }
            },
            webView.observe(\.canGoForward, options: .new) { [weak self] webView, _ in
                DispatchQueue.main.async { self?.canGoForward = webView.canGoForward }
            },
            webView.observe(\.isLoading, options: .new) { [weak self] webView, _ in
                DispatchQueue.main.async { self?.isLoading = webView.isLoading }
            },
            webView.observe(\.estimatedProgress, options: .new) { [weak self] webView, _ in
                DispatchQueue.main.async { self?.estimatedProgress = webView.estimatedProgress }
            },
        ]
    }

    deinit {
        observations.forEach { $0.invalidate() }
    }

    func load(_ urlString: String) {
        var resolved = urlString.trimmingCharacters(in: .whitespaces)

        if !resolved.hasPrefix("http://") && !resolved.hasPrefix("https://") {
            if resolved.contains(".") && !resolved.contains(" ") {
                resolved = "https://" + resolved
            } else {
                let encoded = resolved.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? resolved
                resolved = "https://www.google.com/search?q=\(encoded)"
            }
        }

        guard let url = URL(string: resolved) else { return }
        webView.load(URLRequest(url: url))
    }
}

// MARK: - WebView (UIViewRepresentable)

struct WebViewRepresentable: UIViewRepresentable {
    let store: WebViewStore

    func makeUIView(context: Context) -> WKWebView { store.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - BrowserView

struct BrowserView: View {
    var initialURL: String?
    /// When set, enables the "Update Progress" button so the user can track
    /// where they stopped in the docs without leaving the browser.
    var link: SavedLink? = nil

    @StateObject private var store = WebViewStore()
    @State private var addressBarText = ""
    @FocusState private var addressBarFocused: Bool
    @State private var showSaveSheet = false
    @State private var showProgressSheet = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            WebViewRepresentable(store: store)
                .ignoresSafeArea(edges: .bottom)
            bottomBar
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSaveSheet) {
            SaveToTagSheet(url: store.pageURL, title: store.pageTitle)
        }
        .sheet(isPresented: $showProgressSheet) {
            if let link {
                UpdateProgressSheet(link: link, currentBrowserURL: store.pageURL)
            }
        }
        .onAppear {
            let url = initialURL ?? "https://www.google.com"
            addressBarText = url
            store.load(url)
        }
        .onReceive(store.$pageURL) { url in
            if !addressBarFocused {
                addressBarText = url
            }
        }
        // Sync focus → editing state so the address bar display updates
        .onChange(of: addressBarFocused) { _, focused in
            if focused {
                // Switch to raw URL so the user can edit it
                addressBarText = store.pageURL
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                addressBar
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, store.isLoading ? 6 : 10)

            // Determinate progress bar — only visible while a page is loading
            if store.isLoading {
                ProgressView(value: store.estimatedProgress)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                    .frame(height: 2)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            } else {
                Divider()
            }
        }
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.2), value: store.isLoading)
    }

    // MARK: - Address Bar

    private var addressBar: some View {
        HStack(spacing: 8) {
            // Icon: lock for https, globe otherwise
            Image(systemName: store.pageURL.hasPrefix("https") ? "lock.fill" : "globe")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack(alignment: .leading) {
                // Idle state: show page title so the bar is readable
                if !addressBarFocused {
                    Button {
                        addressBarFocused = true
                    } label: {
                        Text(
                            store.pageTitle.isEmpty
                                ? (store.pageURL.isEmpty ? "Search or enter URL" : store.pageURL)
                                : store.pageTitle
                        )
                        .font(.subheadline)
                        .foregroundStyle(store.pageURL.isEmpty ? .tertiary : .primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }

                // Editing state: full URL text field
                TextField("Search or enter URL", text: $addressBarText)
                    .font(.subheadline)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .focused($addressBarFocused)
                    .opacity(addressBarFocused ? 1 : 0)
                    .onSubmit {
                        addressBarFocused = false
                        store.load(addressBarText)
                    }
            }

            // Clear button — only while editing
            if addressBarFocused && !addressBarText.isEmpty {
                Button {
                    addressBarText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut(duration: 0.15), value: addressBarFocused)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                toolbarButton(
                    icon: "chevron.left",
                    label: "Back",
                    enabled: store.canGoBack
                ) {
                    store.webView.goBack()
                }

                toolbarButton(
                    icon: "chevron.right",
                    label: "Forward",
                    enabled: store.canGoForward
                ) {
                    store.webView.goForward()
                }

                toolbarButton(
                    icon: store.isLoading ? "xmark" : "arrow.clockwise",
                    label: store.isLoading ? "Stop" : "Reload",
                    enabled: true
                ) {
                    if store.isLoading {
                        store.webView.stopLoading()
                    } else {
                        store.webView.reload()
                    }
                }

                toolbarButton(
                    icon: "bookmark",
                    label: "Save",
                    enabled: !store.pageURL.isEmpty,
                    tint: .accentColor
                ) {
                    showSaveSheet = true
                }

                if link != nil {
                    toolbarButton(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Progress",
                        enabled: true,
                        tint: .accentColor
                    ) {
                        showProgressSheet = true
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .background(Color(.systemBackground))
    }

    /// Reusable labeled toolbar button for the bottom bar.
    @ViewBuilder
    private func toolbarButton(
        icon: String,
        label: String,
        enabled: Bool,
        tint: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .regular))
                Text(label)
                    .font(.system(size: 10, weight: .regular))
            }
            .foregroundStyle(enabled ? tint : Color(.tertiaryLabel))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .disabled(!enabled)
    }
}
