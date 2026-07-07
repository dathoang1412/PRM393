# Agent Reference — Journexa

> Machine-readable project reference for AI agents. Use this file to quickly
> understand the project structure without reading every source file.

## Quick Facts

- **Name:** Journexa
- **Languages:** Dart 3
- **Frameworks:** Flutter, Provider, fl_chart, google_fonts, flutter_dotenv
- **Files:** 24 source files
- **Layers:** 6
- **Analyzed:** 2026-06-16
- **Commit:** `8e59fe6`

## Layer Map

- **Config**: App bootstrap, theming, env loading (2 files)
- **State**: Provider-based state + business logic (1 file)
- **Data**: API service, repository, domain models (7 files)
- **Utils**: Pure computation helpers, no Flutter deps (2 files)
- **UI / Screens**: Full-page screen widgets (5 files)
- **UI / Widgets**: Reusable presentational components (7 files)

## Entry Points

- `lib/main.dart` — Bootstrap: loads `.env`, wires DI, mounts `JournexaApp`
- `lib/screens/home_shell.dart` — Root navigation shell (renders Search/Dashboard/Analytics)

## Key Files (by connectivity)

| File | Layer | Connections | Summary |
|------|-------|-------------|---------|
| `lib/providers/research_provider.dart` | State | 10 | Single ChangeNotifier; search state, error, publications, derived analytics |
| `lib/models/publication.dart` | Data | 9 | Core domain model; parses OpenAlex JSON, strips HTML, reconstructs abstracts |
| `lib/utils/analytics_calculator.dart` | Utils | 7 | Static aggregation: trends, journal/author rankings, dashboard summary |
| `lib/services/openalex_service.dart` | Data | 6 | HTTP client; retry logic; OpenAlex `/works` endpoint |
| `lib/screens/search_screen.dart` | UI/Screens | 6 | Search UI; quick chips; state-machine results area |
| `lib/screens/dashboard_screen.dart` | UI/Screens | 5 | KPI grid; trend chart; responsive LayoutBuilder breakpoint |
| `lib/screens/analytics_screen.dart` | UI/Screens | 5 | Three-tab rankings (journals, authors, papers) |
| `lib/app.dart` | Config | 4 | Material 3 theme; Fira Sans + Fira Code; design tokens |
| `lib/widgets/trend_chart.dart` | UI/Widgets | 3 | fl_chart line chart; smart x-axis labeling; gradient fill |
| `lib/widgets/publication_card.dart` | UI/Widgets | 3 | Tappable card; citation magnitude color chips |

## Relationship Summary

| Relationship | Count | Example |
|-------------|-------|---------|
| `imports` | 22 | `research_provider.dart` → `publication.dart` |
| `renders` | 14 | `home_shell.dart` → `search_screen.dart` |
| `depends_on` | 6 | `research_provider.dart` → `publication_repository.dart` |
| `calls` | 4 | `research_provider.dart` → `analytics_calculator.dart` |
| `routes_to` | 2 | `search_screen.dart` → `publication_detail_screen.dart` |

## Critical Implementation Notes

- **No `IndexedStack`** in HomeShell — causes GlobalKey conflicts. Uses `switch` to mount one screen at a time.
- **HTML stripping** in `Publication._stringValue()` — OpenAlex titles contain `<i>` tags.
- **Abstract parsing** — OpenAlex uses inverted-index format; `abstract_parser.dart` reconstructs plain text.
- **X-axis labels** in TrendChart use `interval: 1` + pre-computed `Set<int>` of label years — fl_chart places labels at multiples of `interval` from 0, not `minX`.
- **API key** — `OPENALEX_API_KEY` in `.env` (gitignored); passed as `?api_key=…` query param.
- **TextEditingController** in SearchScreen — initialized from `provider.keyword` in `initState()` to survive tab switches.

## State Machine

`ResearchStatus` enum drives all UI states:

```
idle ──search()──► loading ──success──► success
                       │
                       ├──empty──► empty
                       └──error──► error ──retry──► loading
```

## File Index

- `lib/app.dart` — Root MaterialApp; Material 3 theme with Fira Sans + Fira Code
- `lib/main.dart` — Entry point; DI wiring; `.env` loading
- `lib/models/author_stat.dart` — Value object: author name + publication count
- `lib/models/dashboard_summary.dart` — Aggregate model for dashboard KPIs
- `lib/models/journal_stat.dart` — Value object: journal name + publication count
- `lib/models/publication.dart` — Core domain model; OpenAlex JSON parser
- `lib/models/trend_point.dart` — Value object: year + publication count for charting
- `lib/providers/research_provider.dart` — Single ChangeNotifier; app state hub
- `lib/repositories/publication_repository.dart` — Thin adapter over OpenAlexService
- `lib/screens/analytics_screen.dart` — Three-tab rankings screen
- `lib/screens/dashboard_screen.dart` — KPI grid + trend chart screen
- `lib/screens/home_shell.dart` — Root navigation shell with bottom NavigationBar
- `lib/screens/publication_detail_screen.dart` — Full publication detail with selectable text
- `lib/screens/search_screen.dart` — Search field + quick chips + publication list
- `lib/services/openalex_service.dart` — HTTP client; retry; OpenAlex exception mapping
- `lib/utils/abstract_parser.dart` — Inverted-index → plain text converter
- `lib/utils/analytics_calculator.dart` — Static aggregation utilities
- `lib/widgets/empty_view.dart` — Centered placeholder for empty states
- `lib/widgets/error_view.dart` — Error state with Retry button
- `lib/widgets/loading_view.dart` — Centered spinner with message
- `lib/widgets/metric_tile.dart` — KPI card: icon badge + Fira Code value
- `lib/widgets/publication_card.dart` — Tappable card with color-coded semantic chips
- `lib/widgets/ranked_stat_list.dart` — Medal-badge leaderboard with progress bars
- `lib/widgets/trend_chart.dart` — fl_chart line chart with smart labeling
