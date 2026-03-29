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

    @StateObject private var store = WebViewStore()
    @State private var addressBarText = ""
    @State private var isEditingAddress = false
    @State private var showSaveSheet = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            WebViewRepresentable(store: store)
                .ignoresSafeArea(edges: .bottom)
            Divider()
            bottomBar
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSaveSheet) {
            SaveToTagSheet(url: store.pageURL, title: store.pageTitle)
        }
        .onAppear {
            let url = initialURL ?? "https://www.google.com"
            addressBarText = url
            store.load(url)
        }
        .onReceive(store.$pageURL) { url in
            if !isEditingAddress {
                addressBarText = url
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 8) {
            // Address bar
            HStack(spacing: 6) {
                Image(systemName: store.isLoading ? "xmark" : "magnifyingglass")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                    .onTapGesture {
                        if store.isLoading { store.webView.stopLoading() }
                    }

                TextField("Search or enter URL", text: $addressBarText, onEditingChanged: { editing in
                    isEditingAddress = editing
                })
                .font(.subheadline)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .onSubmit {
                    isEditingAddress = false
                    store.load(addressBarText)
                }

                if !addressBarText.isEmpty && isEditingAddress {
                    Button {
                        addressBarText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Save button
            Button {
                showSaveSheet = true
            } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(store.pageURL.isEmpty ? .secondary : .accentColor)
            }
            .disabled(store.pageURL.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button {
                store.webView.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
            }
            .disabled(!store.canGoBack)

            Spacer()

            Button {
                store.webView.goForward()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
            }
            .disabled(!store.canGoForward)

            Spacer()

            Button {
                if store.isLoading {
                    store.webView.stopLoading()
                } else {
                    store.webView.reload()
                }
            } label: {
                Image(systemName: store.isLoading ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 18, weight: .medium))
            }

            Spacer()

            Button {
                store.load("https://www.google.com")
            } label: {
                Image(systemName: "house")
                    .font(.system(size: 18, weight: .medium))
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}
