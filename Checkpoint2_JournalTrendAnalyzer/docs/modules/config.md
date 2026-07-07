# Config Layer

> Application bootstrap, theming, and environment configuration.

## Files

### `lib/main.dart`

**Summary:** Entry point. Loads `.env`, manually wires the DI chain, mounts `JournexaApp` inside a `ChangeNotifierProvider`.
**Complexity:** low | **Tags:** entry-point, di, bootstrap

**Key functions:** `main()`

**Dependencies:**
- Imports: `flutter_dotenv`, `provider`, `app.dart`, `research_provider.dart`, `publication_repository.dart`, `openalex_service.dart`
- Used by: Flutter runtime

---

### `lib/app.dart`

**Summary:** Defines the root `MaterialApp` with a complete Material 3 design system: color scheme, Fira Sans body font, Fira Code data font, and custom themes for Card, Chip, TabBar, InputDecoration, and ElevatedButton.
**Complexity:** medium | **Tags:** ui, theme, config

**Key class:** `JournexaApp`

**Design tokens:**
| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#1E40AF` | Buttons, active nav, links |
| Secondary | `#3B82F6` | Accents, chips |
| Accent | `#F59E0B` | CTAs, highlights |
| Background | `#F8FAFC` | Scaffold |
| Text | `#0F172A` | Body copy |

**Dependencies:**
- Imports: `google_fonts`, `home_shell.dart`
- Used by: `main.dart` (mounts it)

## Layer Relationships

Config is the root of the dependency graph. `main.dart` constructs all other layers
and passes them to `JournexaApp`. No other layer imports from Config.
