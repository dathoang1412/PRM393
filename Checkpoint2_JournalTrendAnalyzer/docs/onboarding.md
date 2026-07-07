# Onboarding Guide

Welcome to **Journexa**. This guide walks you through every important
file in the codebase in dependency order — start at the entry point and follow the
chain outward.

## Before You Start

- **Language:** Dart 3
- **Framework:** Flutter 3.8+ with Material 3
- **State:** Provider 6.1.0 (one `ChangeNotifier`, no generated code)
- **Data source:** [OpenAlex API](https://openalex.org) — free, open scholarly data
- **Total files:** 24 source files
- **Estimated reading time:** ~30 minutes

---

## The Tour

### Step 1: Bootstrap — `lib/main.dart`

📍 **File:** `lib/main.dart`

Everything starts here. `main()` does three things in sequence:

1. Loads the `.env` file via `flutter_dotenv` — the `OPENALEX_API_KEY` lives there.
2. Manually constructs the dependency graph: `OpenAlexService → PublicationRepository → ResearchProvider`.
3. Wraps the root widget in a `ChangeNotifierProvider` so every screen in the tree can access `ResearchProvider`.

There is intentionally no service locator or code generation. The wiring is explicit and readable in 22 lines.

**Key imports:** `flutter_dotenv`, `provider`, `app.dart`, `research_provider.dart`, `publication_repository.dart`, `openalex_service.dart`

**Next:** The mounted widget is `JournexaApp` in `app.dart`…

---

### Step 2: Theme — `lib/app.dart`

📍 **File:** `lib/app.dart`

`JournexaApp` defines the entire Material 3 design system for the app.
Any color, font, or component style change should start here:

- **Primary:** `#1E40AF` (deep blue — scholarly authority)
- **Secondary:** `#3B82F6` (bright blue)
- **Accent:** `#F59E0B` (amber — highlights and CTAs)
- **Background:** `#F8FAFC` (near-white slate)
- **Body font:** Fira Sans (academic, readable)
- **Data/metrics font:** Fira Code (monospace, scannable numbers)

Custom themes are set for `CardTheme`, `ChipTheme`, `TabBarTheme`, `InputDecorationTheme`, and `ElevatedButtonTheme`. All downstream widgets inherit these — there are no hardcoded `Theme.of(context)` overrides except for intentional semantic deviations (e.g., citation chip colors that vary by magnitude).

**Next:** `app.dart` renders `HomeShell`…

---

### Step 3: State hub — `lib/providers/research_provider.dart`

📍 **File:** `lib/providers/research_provider.dart`

This is the **single source of truth**. Understand this file and you understand the app.

`ResearchProvider` holds:
- `_keyword` — the last searched topic
- `_status` — a `ResearchStatus` enum (`idle | loading | success | empty | error`)
- `_publications` — the `List<Publication>` returned by OpenAlex
- `_errorMessage` — a human-readable error string

When `search(keyword)` is called:
1. Sets status to `loading` and notifies listeners (triggers loading spinner).
2. Awaits `_repository.search(keyword)`.
3. Sets status to `success` or `empty`, stores publications, notifies listeners again.
4. On exception: sets status to `error`, stores error message.

The computed getters (`trends`, `journals`, `authors`, `influentialPapers`, `summary`)
derive analytics from `_publications` on every call via `AnalyticsCalculator`. No caching needed — a 50-item list computes in microseconds.

**Next:** The provider delegates data fetching to `PublicationRepository`…

---

### Step 4: Network — `lib/services/openalex_service.dart`

📍 **File:** `lib/services/openalex_service.dart`

The only place that touches the network. `searchWorks(keyword)` builds:

```
GET https://api.openalex.org/works
  ?search=<keyword>
  &per-page=50
  &sort=cited_by_count:desc
  &select=id,doi,title,display_name,publication_year,cited_by_count,authorships,primary_location,abstract_inverted_index
  &api_key=<OPENALEX_API_KEY from .env>
```

The `_getWithRetry()` method retries up to 3 times with exponential backoff (1s, 2s)
on `TimeoutException`, 429, and 5xx responses. All errors are mapped to typed
`OpenAlexException` with user-friendly messages.

**Next:** The raw JSON is parsed by `Publication.fromJson()`…

---

### Step 5: Domain model — `lib/models/publication.dart`

📍 **File:** `lib/models/publication.dart`

`Publication.fromJson()` handles several OpenAlex quirks:

- **HTML in titles:** OpenAlex embeds `<i>`, `<b>` tags in `display_name`. The `_stringValue()` helper strips them with `replaceAll(RegExp(r'<[^>]*>'), '')`.
- **Inverted-index abstracts:** OpenAlex doesn't return plain text. It returns `{"word": [position1, position2], ...}`. `parseAbstractInvertedIndex()` (in `abstract_parser.dart`) reconstructs the original word order.
- **Author deduplication:** The same author can appear multiple times in `authorships`. Authors are collected into a `Set` before `toList()`.
- **Venue extraction:** Journal name comes from `primary_location.source.display_name` (new schema) with fallback to `host_venue.display_name` (legacy schema).

**Next:** Once publications are loaded, analytics are computed…

---

### Step 6: Analytics — `lib/utils/analytics_calculator.dart`

📍 **File:** `lib/utils/analytics_calculator.dart`

Pure static utility — no Flutter, no state. Takes `List<Publication>`, returns typed models:

| Method | Output | How |
|--------|--------|-----|
| `publicationTrends()` | `List<TrendPoint>` | Groups by year, sorts chronologically |
| `topJournals()` | `List<JournalStat>` | Frequency count, sorted descending |
| `topAuthors()` | `List<AuthorStat>` | Frequency count, sorted descending |
| `influentialPapers()` | `List<Publication>` | Sorted by `citedByCount` descending |
| `summary()` | `DashboardSummary` | Calls all of the above, packages into aggregate |

To add a new metric: add a static method here, then expose it as a getter in `ResearchProvider`.

**Next:** The shell routes users to three screens…

---

### Step 7: Navigation — `lib/screens/home_shell.dart`

📍 **File:** `lib/screens/home_shell.dart`

`HomeShell` is a `StatefulWidget` that owns `_selectedIndex` (0, 1, or 2) and
renders one of three screens via a `switch`. It shows a `NavigationBar` (bottom on mobile,
adaptable to a `NavigationRail` on desktop).

**Why not `IndexedStack`?** Using `IndexedStack` keeps all three screens alive
simultaneously. `AnalyticsScreen` contains a `DefaultTabController`, and `SearchScreen`
contains `InkWell` cards — both try to register a `GlobalKey`. Flutter throws a
`_InkFeatures` duplicate key exception. The switch avoids this by mounting only
one screen at a time.

**Next:** The user lands on `SearchScreen`…

---

### Step 8: Search — `lib/screens/search_screen.dart`

📍 **File:** `lib/screens/search_screen.dart`

The first thing users see. Key behaviors:

- **TextField** restores its text from `provider.keyword` in `initState()` — so switching tabs and returning doesn't clear the search input.
- **Quick-topic chips** (8 preset topics in `_kQuickTopics`) call `_search(topic)`, which sets both the text field and triggers `provider.search()`. Active chip is highlighted with primary color.
- **State machine results:** The content area renders one of five states based on `provider.status`: `idle` (explore prompt), `loading` (spinner), `empty` (no results), `error` (retry button), `success` (SliverList of cards).
- **Navigation:** Tapping a `PublicationCard` pushes `PublicationDetailScreen`.

---

### Step 9: Dashboard — `lib/screens/dashboard_screen.dart`

📍 **File:** `lib/screens/dashboard_screen.dart`

Reads `provider.summary` to render:

1. A `LayoutBuilder`-responsive `GridView`: 2 columns on mobile (`maxWidth ≤ 600`), 3 columns on wider screens. Six `MetricTile` widgets with distinct `iconColor` values.
2. A `_TrendCard` containing the `TrendChart` at 260px height.

This is the screen that best demonstrates the responsive scaffold — the grid breakpoint at 600px applies to the *widget* width, not the screen width, so it works correctly on tablets and in split-screen mode.

---

### Step 10: TrendChart — `lib/widgets/trend_chart.dart`

📍 **File:** `lib/widgets/trend_chart.dart`

The most complex widget. Important implementation details:

- **X-axis label placement:** fl_chart places labels at multiples of `interval` from 0, not from `minX`. Using `interval: 1` with a pre-computed `Set<int>` of label years (5 evenly-distributed actual data years) avoids labels landing on years with no data points.
- **Y-axis interval:** `_yInterval()` scales dynamically — 1 for tiny counts, 10+ for large. Labels at 0 and `chartMaxY` are hidden to avoid clutter at extremes.
- **Single-point guard:** If there's only one year of data, `minX` and `maxX` are padded by ±1 so the chart doesn't render a dot spanning the full axis width.
- **Smooth curve:** `isCurved: sortedPoints.length > 2` — straight segments for 2 points, smooth for 3+.

---

## What's Next?

Now that you've walked the full codebase:

- Explore [modules/](modules/) for per-layer deep dives with complete file indexes.
- See [architecture.md](architecture.md) for the dependency flow diagram.
- See [AGENTS.md](AGENTS.md) for a compact machine-readable reference.

**To add a new feature:**
1. Add a new static method in `analytics_calculator.dart`
2. Expose it as a getter in `research_provider.dart`
3. Read it in the relevant screen with `context.watch<ResearchProvider>()`
