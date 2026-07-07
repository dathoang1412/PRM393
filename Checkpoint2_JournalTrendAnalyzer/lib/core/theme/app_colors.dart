import 'package:flutter/material.dart';

/// Single source of truth for the app's scholarly "ink & paper" palette.
///
/// The categorical chart palette was validated for colorblind safety
/// (adjacent-pair CVD ΔE ≥ 15, contrast ≥ 3:1 on white) — keep the slot
/// order fixed and never cycle it; fold extra series into "other".
class AppColors {
  const AppColors._();

  // ── Brand: "pine & gilt" — deep viridian green with old-gold accents,
  // the look of a university-press book spine.
  static const primary = Color(0xFF0F5D4E); // deep pine green
  static const primaryDark = Color(0xFF0A4237);
  static const primaryLight = Color(0xFF15806B); // gradient companion
  static const accent = Color(0xFFB7791F); // old gold — highlights only

  // ── Ink (text) ─────────────────────────────────────────────────────────
  static const ink = Color(0xFF222D3A);
  static const inkSecondary = Color(0xFF5D6672);
  static const inkMuted = Color(0xFF8F8D84);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const paper = Color(0xFFF6F4EF); // scaffold background
  static const surface = Colors.white;
  static const border = Color(0xFFE6E2D8);
  static const wash = Color(0xFFF3F1EA); // neutral chip / grid fill
  static const primaryWash = Color(0xFFE7F1EC); // soft primary chip bg
  static const primaryBorder = Color(0xFFC0D8CD);

  // ── Status (reserved — never used as series colors) ────────────────────
  static const success = Color(0xFF067647);
  static const warning = Color(0xFFB54708);
  static const danger = Color(0xFFB42318);

  // ── Categorical chart palette (validated, fixed order) ─────────────────
  static const series1Blue = Color(0xFF2E67B2);
  static const series2Bronze = Color(0xFFB45309);
  static const series3Green = Color(0xFF12896B);
  static const series4Violet = Color(0xFF6D4FA3);
  static const series5Brick = Color(0xFFC0504E);
  static const series6Teal = Color(0xFF1791B8);
  static const series7Mauve = Color(0xFFA5588A);

  static const chartPalette = [
    series1Blue,
    series2Bronze,
    series3Green,
    series4Violet,
    series5Brick,
    series6Teal,
    series7Mauve,
  ];

  // Semantic aliases so every screen colors the same entity the same way.
  static const seriesPublications = series1Blue;
  static const seriesCitations = series2Bronze;
  static const seriesCountries = series3Green;
  static const seriesKeywords = series4Violet;
  static const seriesPapers = series5Brick;
  static const seriesAuthors = series6Teal;
  static const seriesVenues = series7Mauve;
}
