# Journexa — Giải thích App

> Tài liệu này giải thích app hiện tại đang hoạt động như thế nào: màn hình nào làm gì, dữ liệu lấy từ đâu, và các chart/tính năng được implement ra sao. Viết dựa trên code thực tế trong `lib/`, không phải bản thiết kế ban đầu.

## 1. App là gì

**Journexa** là app Flutter giúp người dùng nhập 1 từ khóa nghiên cứu (ví dụ "Machine Learning"), sau đó tự động:
- Lấy tối đa 100 bài báo khoa học liên quan từ [OpenAlex API](https://openalex.org) (sắp xếp theo số citation giảm dần).
- Phân tích và hiển thị: xu hướng công bố theo năm, top journal, top tác giả, top từ khóa, top institution, top quốc gia, bài báo ảnh hưởng nhất.
- Cho phép lọc theo khoảng năm và export dữ liệu ra CSV.

Không có backend riêng, không đăng nhập, không lưu database — toàn bộ state chỉ tồn tại trong session (gọi API lại mỗi khi search).

## 2. Kiến trúc tổng thể

```
lib/
  main.dart, app.dart         → khởi động app, load .env, setup theme + Provider
  services/openalex_service.dart   → gọi REST API OpenAlex
  repositories/publication_repository.dart → lớp trung gian giữa service và provider
  providers/research_provider.dart → state trung tâm (ChangeNotifier)
  utils/analytics_calculator.dart  → toàn bộ logic tính toán (thuần Dart, không UI)
  models/*.dart                → các class dữ liệu (Publication, JournalStat, ...)
  screens/*.dart                → 5 màn hình
  widgets/*.dart                → các component dùng lại (chart, card, KPI tile...)
```

Luồng dữ liệu: `SearchScreen` gọi `provider.search(keyword)` → `ResearchProvider` gọi `PublicationRepository.search()` → `OpenAlexService.searchWorks()` gọi API → parse JSON thành `List<Publication>` → lưu vào provider → mọi screen khác (`watch<ResearchProvider>()`) tự rebuild với data mới.

## 3. Điều hướng (`home_shell.dart`)

App có 4 tab chính, chuyển bằng `NavigationBar` (mobile) hoặc `NavigationRail` (desktop, khi width ≥ 800px):

| Index | Tên tab | Screen |
|---|---|---|
| 0 | Search | `SearchScreen` |
| 1 | Dashboard | `DashboardScreen` |
| 2 | Trends | `TrendsScreen` |
| 3 | Rankings | `AnalyticsScreen` |

Chỉ 1 screen được mount tại một thời điểm (dùng `switch`, không dùng `IndexedStack`, vì `AnalyticsScreen` có `DefaultTabController` gây trùng key nếu giữ nhiều screen sống cùng lúc).

## 4. Các màn hình

### 4.1 Search Screen
- Ô nhập từ khóa (mặc định "Artificial Intelligence") + 8 chip gợi ý nhanh (AI, Machine Learning, Data Science, Cybersecurity, Blockchain, IoT, Quantum Computing, Bioinformatics).
- Nhấn search → gọi `provider.search(keyword)`.
- Khu vực kết quả render theo `ResearchStatus`: `idle` → empty view, `loading` → spinner, `error` → nút "Try again", `empty` → "không có kết quả", `success` → danh sách `PublicationCard` (grid 2 cột trên desktop, 1 cột trên mobile).
- Tap vào 1 card → mở `PublicationDetailScreen`.

### 4.2 Dashboard Screen
Màn hình tổng quan, có **year-range filter** (All time / Last 5 năm / Last 10 năm / theo thập kỷ / trước 2000) áp dụng cho mọi số liệu bên dưới.

- 6 KPI tile: Publications, Avg citations, Most active year, Top venue, Top author, Top paper.
- Insight note: % tăng/giảm công bố 5 năm gần nhất so với 5 năm trước đó.
- Chart (xem mục 5):
  - Publication Activity (Line chart)
  - Donut chart phân bố loại công bố (article/preprint/...)
  - Citation Activity (Line chart, citation theo năm)
  - Top Research Keywords (Horizontal Bar)
  - Research by Country (Horizontal Bar)
- Nút export CSV (icon download trên AppBar) → copy CSV vào clipboard.

### 4.3 Trends Screen
Phiên bản "deep-dive" của phần trend, tách riêng khỏi Dashboard:
- 4 KPI: Publications (đã filter), Total citations, Peak year, 5-year growth rate (kèm icon tăng/giảm).
- Year-range filter riêng.
- Chart: Publication Activity (Line), Citation Activity (Line), Top Keywords (Bar, top 15), Research by Country (Bar, top 15).

### 4.4 Analytics Screen ("Rankings") — 5 tab
- **Journals**: KPI (số venue, top-5 share %, số venue có ≥2 bài) + Horizontal Bar (top 10) + danh sách rank đầy đủ (top 20, có progress bar).
- **Authors**: KPI (số tác giả, tác giả nhiều bài nhất, tác giả được cite nhiều nhất) + Horizontal Bar (top 15) + danh sách rank + **Scatter Plot** "Author Impact Matrix" (số bài vs tổng citation, chỉ hiện khi ≥3 tác giả).
- **Keywords**: KPI (số concept, % bài có keyword, top concept) + Donut chart (top 6) cạnh Horizontal Bar (top 20) — side-by-side trên màn rộng, xếp dọc trên màn hẹp.
- **Institutions**: KPI (số institution, top institution, top-3 share %) + Horizontal Bar (top 10) + danh sách rank.
- **Top Papers**: KPI (tổng citation, số bài "highly cited" ≥100 citation, median citation) + danh sách `PublicationCard` top 20 theo citation, tap để xem detail.
- Nút export CSV ở AppBar (giống Dashboard).
- Tất cả tab đều tôn trọng year-range filter.

### 4.5 Publication Detail Screen
Hiện khi tap vào 1 bài báo: title, tác giả, năm, journal, citation count, DOI (copy được), abstract (đã reconstruct từ `abstract_inverted_index` của OpenAlex), và nếu có dữ liệu: institutions, keywords, mini citation-trend chart.

## 5. Các loại chart đang dùng

| Loại chart | Widget | Dùng ở đâu |
|---|---|---|
| **Line Chart** (`fl_chart`) | `trend_chart.dart` | Publication Activity, Citation Activity (Dashboard, Trends, mini chart trong Detail) |
| **Horizontal Bar Chart** (tự code, không dùng `fl_chart` vì lib này không có bar ngang sẵn) | `horizontal_bar_chart.dart` | Journal/Author/Institution ranking, Top Keywords, Research by Country |
| **Donut/Pie Chart** (`fl_chart`) | `donut_chart.dart` | Publication type distribution (Dashboard), Top concepts (Analytics → Keywords) |
| **Scatter Plot** (`fl_chart`) | `scatter_plot_widget.dart` | Author Impact Matrix (Analytics → Authors): số bài (x) vs tổng citation (y) |

Ngoài ra `ranked_stat_list.dart` là danh sách rank dùng `LinearProgressIndicator` — không phải "chart" thật, chỉ là UI list kiểu cũ, hiện ít được dùng trực tiếp (đã bị thay phần lớn bởi `_RankRow` custom trong `analytics_screen.dart`).

## 6. State management — `ResearchProvider`

Là `ChangeNotifier` duy nhất của app, expose:
- **Trạng thái cơ bản**: `status` (idle/loading/success/empty/error), `keyword`, `errorMessage`, `publications`.
- **Filter**: `yearFrom`, `yearTo`, `hasYearFilter`, `filteredPublications` (publications sau khi áp filter năm), method `setYearRange(from, to)`.
- **Analytics getters** (tất cả tính trên `filteredPublications`, đều đi qua `AnalyticsCalculator`): `trends`, `citationTrends`, `journals`, `authors`, `authorImpacts`, `topKeywords`, `topInstitutions`, `topCountries`, `workTypes`, `influentialPapers`, `summary`.
- **Method chính**: `search(String keyword)` — gọi repository, set status, reset year filter.

## 7. Nguồn dữ liệu — OpenAlex API

`openalex_service.dart` gọi `GET https://api.openalex.org/works` với:
- `search`: từ khóa người dùng nhập.
- `per-page`: 100, `sort`: `cited_by_count:desc`.
- `select`: `id, doi, title, display_name, publication_year, cited_by_count, counts_by_year, authorships, primary_location, abstract_inverted_index, concepts, type`.
- `api_key` (optional, đọc từ `.env` nếu có).

Có retry tối đa 3 lần (backoff) cho lỗi 429/5xx, timeout 30s/lần. Lỗi được map thành message thân thiện (`OpenAlexException`) thay vì crash app.

`Publication.fromJson()` parse trực tiếp JSON này thành model, bao gồm cả reconstruct abstract từ `abstract_inverted_index`, parse `keywords` từ `concepts`, `institutions`/`countries` từ `authorships`, và `citationsByYear` từ `counts_by_year`.

## 8. Tính năng lọc & export

- **Year range filter** (`year_range_filter.dart`): chip ngang với các preset (All time, Last 5/10 năm, theo thập kỷ, trước 2000). Khi chọn, mọi getter analytics của provider tự tính lại trên `filteredPublications`.
- **CSV export**: nút download ở AppBar (Dashboard + Analytics) gọi `AnalyticsCalculator.exportCsv()` để build chuỗi CSV (có metadata header), copy vào clipboard qua `Clipboard.setData()`, hiện `SnackBar` xác nhận.
