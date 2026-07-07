# Architecture

## System Overview

Journexa follows a **layered architecture** with unidirectional data flow:

```
OpenAlex API
     ↓ HTTP (100 works, cited_by_count:desc)
 OpenAlexService
     ↓ delegates
 PublicationRepository
     ↓ calls
 ResearchProvider  ←→  AnalyticsCalculator
   (year filter)
     ↓ context.watch
  UI Screens / Widgets
```

The pattern is: **Service → Repository → Provider → UI**, with pure utility classes
(`AnalyticsCalculator`, `AbstractParser`) doing stateless computation outside the
Provider to keep business logic testable in isolation.

---

## Layers

### Config

**Purpose:** Application bootstrap, theming, and environment configuration.

| File | Purpose | Complexity |
|------|---------|------------|
| `lib/main.dart` | Entry point — loads `.env`, wires DI chain, mounts app | low |
| `lib/app.dart` | Root `MaterialApp` with Material 3 theme, Plus Jakarta Sans + Space Grotesk fonts | medium |

**Key relationships:**
- `main.dart` constructs the entire dependency graph manually (no service locator): `OpenAlexService → PublicationRepository → ResearchProvider`.
- `app.dart` defines the global `ThemeData` (colors, fonts, card shapes) consumed by every widget in the tree.

---

### State

**Purpose:** Provider-based state management and business logic orchestration.

| File | Purpose | Complexity |
|------|---------|------------|
| `lib/providers/research_provider.dart` | Single ChangeNotifier; owns search state, year filter, and 10+ derived analytics getters | medium |

**Key relationships:**
- Depends on `PublicationRepository` (data fetch) and `AnalyticsCalculator` (analytics derivation).
- All 4 screens (`SearchScreen`, `DashboardScreen`, `TrendsScreen`, `AnalyticsScreen`) read from this provider via `context.watch<ResearchProvider>()`.
- All computed getters derive from `filteredPublications` — year-range filter applied transparently to every chart and ranking.
- `search()` resets the year filter automatically.

---

### Data

**Purpose:** External API integration, repository abstraction, and domain models.

| File | Purpose | Complexity |
|------|---------|------------|
| `lib/services/openalex_service.dart` | HTTP client — OpenAlex `/works` endpoint, 100 results, retry logic | high |
| `lib/repositories/publication_repository.dart` | Thin adapter decoupling Provider from HTTP | low |
| `lib/models/publication.dart` | Core domain model — parses OpenAlex JSON, strips HTML, extracts concepts/institutions/countries | medium |
| `lib/models/dashboard_summary.dart` | Aggregate KPI model | low |
| `lib/models/trend_point.dart` | `{year, count}` for line charts | low |
| `lib/models/year_count.dart` | `{year, count}` alias for citation trend grouping | low |
| `lib/models/journal_stat.dart` | `{name, publicationCount}` for journal rankings | low |
| `lib/models/author_stat.dart` | `{name, publicationCount}` for author rankings | low |
| `lib/models/author_impact.dart` | `{name, publicationCount, totalCitations}` for scatter-plot | low |
| `lib/models/keyword_stat.dart` | `{name, count}` for keyword/concept rankings | low |
| `lib/models/country_stat.dart` | `{name, count}` for country rankings | low |
| `lib/models/institution_stat.dart` | `{name, count}` for institution rankings | low |

**Key relationships:**
- `OpenAlexService` is the **only** network boundary. It requests 100 works sorted by `cited_by_count:desc`, handles retries (3 attempts, exponential backoff, 30 s timeout), and maps HTTP errors to typed `OpenAlexException` messages.
- `Publication.fromJson()` strips HTML tags from `display_name`, reconstructs abstracts from OpenAlex's inverted-index format, and extracts concept/institution/country arrays for analytics.

---

### Utils

**Purpose:** Pure computation helpers with no Flutter or network dependencies.

| File | Purpose | Complexity |
|------|---------|------------|
| `lib/utils/analytics_calculator.dart` | Aggregation: trends, citation trends, journal/author/keyword/country/institution rankings, author impact, work-type distribution, CSV export | high |
| `lib/utils/abstract_parser.dart` | Converts OpenAlex inverted-index → plain text | low |

**Key relationships:**
- `AnalyticsCalculator` is called exclusively by `ResearchProvider`. All methods are static and take `List<Publication>`, returning typed result models.
- `parseAbstractInvertedIndex()` is called inside `Publication.fromJson()`.
- `AnalyticsCalculator.exportCsv()` generates a CSV string consumed by `AnalyticsScreen` via `Clipboard.setData()`.

---

### UI / Screens

**Purpose:** Full-page widgets composing the app's 4-tab navigation tree.

| File | Purpose | Complexity |
|------|---------|------------|
| `lib/screens/home_shell.dart` | Root shell — `NavigationRail` (desktop ≥ 800 px) or `NavigationBar` (mobile) | low |
| `lib/screens/search_screen.dart` | Search field, 8 quick-chips, publication list | medium |
| `lib/screens/dashboard_screen.dart` | KPI grid, year filter, 4 chart cards (trend, donut, citation, keywords) | high |
| `lib/screens/trends_screen.dart` | KPI tiles, insight note, 4 chart cards (pub activity, citation, keywords, countries) | high |
| `lib/screens/analytics_screen.dart` | 5-tab ranking view: Journals, Authors, Keywords, Institutions, Top Papers; CSV export | high |
| `lib/screens/publication_detail_screen.dart` | Single publication detail + selectable text | low |

**Key relationships:**
- `HomeShell` uses a `switch` (not `IndexedStack`) to swap screens — `IndexedStack` causes `GlobalKey` conflicts between `AnalyticsScreen`'s `DefaultTabController` and `InkWell` cards in sibling screens.
- All content screens wrap their layout in `ConstrainedBox(maxWidth: 1400)` + `Center` for comfortable ultra-wide display.
- `SearchScreen` and `AnalyticsScreen` both push `PublicationDetailScreen` via `Navigator.push`.

---

### UI / Widgets

**Purpose:** Reusable, self-contained presentational components.

| File | Purpose | Complexity |
|------|---------|------------|
| `lib/widgets/trend_chart.dart` | fl_chart line chart with smart x-axis + peak-year vertical annotation | high |
| `lib/widgets/donut_chart.dart` | Interactive fl_chart donut with responsive legend (wide: row, narrow: column) | high |
| `lib/widgets/horizontal_bar_chart.dart` | Proportional horizontal bars for ranked categorical data | medium |
| `lib/widgets/scatter_plot_widget.dart` | fl_chart scatter plot for author output vs impact | medium |
| `lib/widgets/metric_tile.dart` | KPI card with left-accent bar (Stack/Positioned) + value in Space Grotesk | low |
| `lib/widgets/insight_note.dart` | Data callout box with left accent, icon, and optional bold label prefix | low |
| `lib/widgets/year_range_filter.dart` | Year chip filter — reads/writes ResearchProvider year range | low |
| `lib/widgets/publication_card.dart` | Tappable card with semantic citation-count color coding | medium |
| `lib/widgets/ranked_stat_list.dart` | Leaderboard with medal badges + progress bars | medium |
| `lib/widgets/empty_view.dart` | Centered placeholder for empty states | low |
| `lib/widgets/error_view.dart` | Error state with Retry button | low |
| `lib/widgets/loading_view.dart` | Centered spinner with message | low |

---

## Dependency Flow

```
Config ──────────────────────────────────────────┐
  main.dart (DI wiring)                           │
  app.dart (theme + fonts)                        │
                                                  ▼
Data ────────────────► State ──────────────► UI Screens
  OpenAlexService          ResearchProvider      HomeShell
  Repository               (ChangeNotifier)      SearchScreen
  Publication (model)      year filter           DashboardScreen
  DashboardSummary         filteredPubs          TrendsScreen
  TrendPoint / YearCount                         AnalyticsScreen
  JournalStat / AuthorStat    Utils              DetailScreen
  KeywordStat              AnalyticsCalculator        │
  CountryStat              AbstractParser             ▼
  InstitutionStat          exportCsv()         UI Widgets
  AuthorImpact                                  TrendChart
                                                DonutChart
                                                HorizontalBarChart
                                                ScatterPlotWidget
                                                MetricTile
                                                InsightNote
                                                YearRangeFilter
                                                PublicationCard
                                                RankedStatList
                                                EmptyView / ErrorView / LoadingView
```

No circular dependencies exist between layers. All data flows downward.

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Provider over Riverpod/Bloc | Simplest approach for a single-provider, single-search-flow app. No generated code needed. |
| Repository pattern | Decouples `ResearchProvider` from `http`; swap API or add caching without touching state logic. |
| Static utility classes | `AnalyticsCalculator` has no state and no Flutter deps — easy to unit test without `flutter_test`. |
| `switch` in HomeShell | Avoids `GlobalKey` duplicates caused by `IndexedStack` keeping all screens alive simultaneously. |
| `filteredPublications` gateway | All 10+ analytics getters delegate to `filteredPublications` so the year filter applies everywhere with no extra wiring. |
| `ConstrainedBox(maxWidth: 1400)` | Keeps content readable on ultra-wide monitors without centering logic in every screen. |
| `_kChartHeight = 252` constant | Uniform chart content height ensures all cards in the same row reach the same total height when using identical `_SectionCard` wrappers. |
| `DonutChart`: `Row + Expanded(legend)` inside `LayoutBuilder` | `LayoutBuilder` bounds the Row width; `Expanded(legend)` fills remaining space so `%` values align to the card's content-right edge — matching adjacent leaderboard cards. Using `Row(mainAxisSize.min)` or `SizedBox(legendW)` was rejected because it centered content and left a gap at the right edge. |
| `InsightNote`: `ClipRRect` + `Border.all` | Flutter requires uniform border colors when `borderRadius` is set on a `BoxDecoration`. `ClipRRect` handles rounding independently; `Border.all` (single color) satisfies the constraint. The left accent is a sibling `Container(width:3)`. |
| `interval: 1` in TrendChart | fl_chart places x-axis labels at multiples of `interval` from 0; using 1 with a pre-computed `Set<int>` of evenly-distributed label years avoids misaligned labels. |
| API key via `api_key` query param | OpenAlex requires a key via `?api_key=…`. `flutter_dotenv` keeps it out of source control. |
| CSV export via clipboard | Avoids file-system permission complexity on all platforms; `Clipboard.setData()` works uniformly on Android, iOS, Windows, macOS, web. |
