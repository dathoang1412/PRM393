# Journexa

> Auto-generated documentation from codebase analysis.
> Last generated: 2026-06-16 | Commit: `8e59fe6`

## Overview

**Journexa** is a Flutter application for exploring academic publication trends powered by the [OpenAlex](https://openalex.org) open scholarly data API. Users search any research topic (e.g. "Machine Learning", "Quantum Computing") and instantly see a curated set of up to 50 highly-cited papers, along with automatically computed trend charts, journal/author rankings, and key KPI metrics.

The app targets both **mobile** (bottom navigation, single-column layout) and **desktop** (sidebar navigation, multi-column layout) through Flutter's cross-platform renderer. It is structured as a clean, layered Flutter project: a Provider-based state layer sits between the network service and the UI, with pure Dart utility classes handling all analytics computation.

The project is small (24 source files, ~1,700 lines of Dart) and intentionally free of generated boilerplate — every file earns its place.

## Tech Stack

| Category | Technologies |
|----------|-------------|
| Language | Dart 3 |
| Framework | Flutter 3.8+ (Material 3) |
| State management | Provider 6.1.0 (ChangeNotifier) |
| HTTP | `http` 1.2.0 |
| Charts | `fl_chart` 0.68.0 |
| Fonts | `google_fonts` 6.2.1 (Fira Sans + Fira Code) |
| Env config | `flutter_dotenv` 5.2.1 |
| Data source | OpenAlex REST API (open, free) |
| Total source files | 24 |

## Architecture

Organized into **6 layers**:

| Layer | Description | Files |
|-------|-------------|-------|
| Config | App bootstrap, theming, env loading | 2 |
| State | Provider-based state + business logic | 1 |
| Data | API service, repository, domain models | 7 |
| Utils | Pure computation helpers | 2 |
| UI / Screens | Full-page screen widgets | 5 |
| UI / Widgets | Reusable presentational components | 7 |

→ See [Architecture](architecture.md) for full details.

## Features

| Feature | Where |
|---------|-------|
| Keyword search + 8 quick-topic chips | Search screen |
| Publication list (up to 50, sorted by citations) | Search screen |
| KPI metrics: total, avg citations, active year, top venue/author/paper | Dashboard |
| Yearly publication trend line chart | Dashboard |
| Top journals ranked leaderboard | Analytics → Journals tab |
| Top authors ranked leaderboard | Analytics → Authors tab |
| Most influential papers list | Analytics → Papers tab |
| Full publication detail (title, authors, DOI, abstract) | Detail screen |

## Quick Links

- [Architecture Overview](architecture.md)
- [Onboarding Guide](onboarding.md)
- [Agent Reference](AGENTS.md)
- Modules:
  - [Config](modules/config.md)
  - [State](modules/state.md)
  - [Data](modules/data.md)
  - [Utils](modules/utils.md)
  - [UI — Screens](modules/ui-screens.md)
  - [UI — Widgets](modules/ui-widgets.md)
