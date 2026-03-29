# MarkIT

A lightweight iOS study companion that turns web browsing into organized learning — one tagged link at a time.

## Overview

MarkIT lets you browse the web in a built-in browser, save pages to colour-coded emoji tags, and build a personal study library. Tags support two levels (parent → child), so you can organize broadly ("Tech Study") and drill down ("Swift", "Android").

## Features

- **Hierarchical tags** — parent tags with up to one level of subtags
- **Custom tag appearance** — pick any emoji and colour for each tag
- **Built-in browser** — WKWebView with address bar, back/forward/reload, and a persistent Save button
- **Two-step save flow** — pick a parent tag, then optionally drill into a subtag before saving
- **Link management** — swipe to delete, search within any tag, favicon + domain display
- **Smart delete** — when removing a parent tag, choose to delete all children or promote them to top-level

## Requirements

- iOS 17.0+
- Xcode 15+
- Swift 5.9+

## Project Setup

1. Open Xcode and create a new **iOS App** project
   - Interface: SwiftUI
   - Storage: SwiftData
2. Copy all files from the `MarkIT/` folder into your project target
3. Build and run

No third-party dependencies are required.

## Project Structure

```
MarkIT/
├── MarkITApp.swift              # App entry point + TabView shell
├── Models/
│   ├── Tag.swift                # SwiftData model — parent/child hierarchy
│   └── SavedLink.swift          # SwiftData model — saved web page
├── Utilities/
│   ├── Color+Hex.swift          # Color initializer from hex string
│   └── Constants.swift          # Preset tag colours and emoji palette
└── Views/
    ├── HomeView.swift            # Parent tag grid (Library tab)
    ├── ParentTagDetailView.swift # Child sub-grid + direct links
    ├── ChildTagDetailView.swift  # Links saved to a child tag
    ├── BrowserView.swift         # WKWebView browser (Browser tab)
    ├── Components/
    │   ├── TagCard.swift         # Reusable colour card component
    │   └── LinkRow.swift         # Link list row with favicon
    └── Sheets/
        ├── AddTagSheet.swift     # Create / edit a tag
        └── SaveToTagSheet.swift  # Two-step save flow
```

## Data Model

```swift
Tag
├── name: String
├── emoji: String
├── colorHex: String
├── parent: Tag?          // nil = top-level tag
├── children: [Tag]       // empty for child tags
└── links: [SavedLink]    // links saved directly to this tag

SavedLink
├── url: String
├── title: String
├── faviconURL: String?
├── savedAt: Date
└── tag: Tag
```

Depth is capped at 2 levels (parent → child) and enforced at creation time. Deleting a parent cascades to its children and their links unless children are promoted first.

## Roadmap

| Version | Features |
|---------|----------|
| MVP 1 (current) | Hierarchical tags, built-in browser, local SwiftData persistence |
| MVP 2 | iCloud sync via CloudKit, Share Extension (save from Safari) |
| MVP 3 | Reminders, export, duplicate link detection |
