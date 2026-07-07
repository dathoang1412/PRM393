# Journexa

## Overview

Journexa is a Flutter mobile application for exploring academic publication trends using live OpenAlex data.

## Features

- Search publications by research topic
- View publication details, authors, DOI, venue, citations, and abstract
- Analyze publication trends by year
- View top journals and venues
- View top contributing authors
- View top influential papers by citation count
- Research trend dashboard with compact metrics and chart

## Tech Stack

- Flutter
- Dart
- OpenAlex API
- REST API with `http`
- State management with `provider`
- Chart visualization with `fl_chart`

## API

Data is retrieved from OpenAlex:

```text
https://api.openalex.org/works?search={keyword}&per-page=50&sort=cited_by_count:desc
```

OpenAlex API keys are passed as an `api_key` query parameter. Do not hard-code the key in Dart source code. Put it in `.env`:

```env
OPENALEX_API_KEY=your_openalex_key
```

For quick local testing without a key, the service still sends unauthenticated requests. For assignment demos or repeated testing, create a free key from OpenAlex and update `.env`.

The app reconstructs abstracts from `abstract_inverted_index` when OpenAlex returns abstract data.

## Project Structure

```text
lib/
  main.dart
  app.dart
  models/
  services/
  repositories/
  providers/
  screens/
  widgets/
  utils/
```

## How To Run

1. Install Flutter.
2. Run `flutter pub get`.
3. Start an Android emulator or connect an Android device.
4. Copy `.env.example` to `.env` if needed, then set `OPENALEX_API_KEY`.
5. Run `flutter run`.

## Screenshots

Add screenshots of:

- Search screen
- Publication detail screen
- Dashboard screen
- Analytics screen

## AI-Assisted Code Review

Document at least three findings from an AI-assisted or automated code review tool.

Suggested findings to verify and document during review:

- Network calls should handle timeout and malformed JSON.
- Missing OpenAlex fields should not crash UI rendering.
- Search input should reject empty keywords.

## Author

Student name and student ID.
