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
    @Published var progress: Double = 0

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
                DispatchQueue.main.async { self?.progress = webView.estimatedProgress }
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

// MARK: - WebViewRepresentable

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
    @FocusState private var addressFocused: Bool
    @State private var showSaveSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar + top bar
            VStack(spacing: 0) {
                DSProgressBar(progress: store.progress)
                topBar
            }
            .dsGlass()
            .overlay(alignment: .bottom) {
                Divider()
            }

            WebViewRepresentable(store: store)
                .ignoresSafeArea(edges: .bottom)

            bottomBar
                .dsGlass()
                .overlay(alignment: .top) {
                    Divider()
                }
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
            if !addressFocused {
                addressBarText = url
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: DSSpacing.sm) {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: store.isLoading ? "xmark" : "magnifyingglass")
                    .font(.footnote)
                    .foregroundStyle(DSColors.secondary)
                    .frame(width: 16)
                    .onTapGesture {
                        if store.isLoading { store.webView.stopLoading() }
                    }

                TextField("Search or enter URL", text: $addressBarText)
                    .font(DSFont.subheadline)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .focused($addressFocused)
                    .onSubmit {
                        addressFocused = false
                        store.load(addressBarText)
                    }

                if !addressBarText.isEmpty && addressFocused {
                    Button {
                        addressBarText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DSColors.secondary)
                    }
                }
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(DSColors.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .scaleEffect(addressFocused ? 1.01 : 1.0)
            .animation(DSAnimation.snappy, value: addressFocused)

            // Save / bookmark button
            Button {
                showSaveSheet = true
            } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(store.pageURL.isEmpty ? DSColors.secondary : DSColors.accent)
            }
            .disabled(store.pageURL.isEmpty)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            navButton(icon: "chevron.left", enabled: store.canGoBack) {
                store.webView.goBack()
            }
            Spacer()
            navButton(icon: "chevron.right", enabled: store.canGoForward) {
                store.webView.goForward()
            }
            Spacer()
            navButton(icon: store.isLoading ? "xmark" : "arrow.clockwise", enabled: true) {
                store.isLoading ? store.webView.stopLoading() : store.webView.reload()
            }
            Spacer()
            navButton(icon: "house", enabled: true) {
                store.load("https://www.google.com")
            }
        }
        .padding(.horizontal, DSSpacing.xxl)
        .padding(.vertical, DSSpacing.md)
    }

    private func navButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(enabled ? DSColors.primary : DSColors.tertiary)
        }
        .disabled(!enabled)
    }
}
