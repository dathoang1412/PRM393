# Đánh giá kiến trúc mã nguồn — Journexa

> Phạm vi: toàn bộ thư mục `lib/` (~6.300 dòng, 30 file): models → repository → service → provider → screens/widgets.
> Nhận xét chung: kiến trúc theo mô hình `Provider` + repository/service khá gọn gàng, không bị "vẽ rắn thêm chân". Các vấn đề dưới đây chủ yếu nằm ở việc **lặp code trong lớp UI** và **thiếu kiểm thử (test)**, không phải lỗi cấu trúc nghiêm trọng.

## 1. Code Smells & Anti-patterns (Mùi code & phản mẫu hình)

- **Widget "card" bị lặp 3 lần.** [analytics_screen.dart:827-912](lib/screens/analytics_screen.dart#L827-L912) (`_ChartSection`), [dashboard_screen.dart:412-499](lib/screens/dashboard_screen.dart#L412-L499) (`_SectionCard`), và [trends_screen.dart:336-421](lib/screens/trends_screen.dart#L336-L421) (`_Section`) là 3 widget gần như giống y nhau (icon + tiêu đề/phụ đề + thanh nhấn màu), copy-paste ~90 dòng mỗi nơi thay vì tách ra dùng chung.
- **Header bộ lọc năm bị lặp 3 lần.** [analytics_screen.dart:1032-1071](lib/screens/analytics_screen.dart#L1032-L1071), [dashboard_screen.dart:370-408](lib/screens/dashboard_screen.dart#L370-L408), [trends_screen.dart:294-332](lib/screens/trends_screen.dart#L294-L332) — cùng một badge "YEAR FILTER", lặp lại nguyên văn ở 3 nơi.
- **Công thức tính tỉ lệ khung KPI-grid bị lặp 4 lần.** Cùng một mẫu `LayoutBuilder` → tính `aspect = (w - (n-1)*gap)/n/targetH` → `GridView.count`, xuất hiện ở 4 nơi: [dashboard_screen.dart:182-197](lib/screens/dashboard_screen.dart#L182-L197), [trends_screen.dart:80-94](lib/screens/trends_screen.dart#L80-L94), [analytics_screen.dart:594-632](lib/screens/analytics_screen.dart#L594-L632), [analytics_screen.dart:710-726](lib/screens/analytics_screen.dart#L710-L726).
- **Hàm `build` quá dài, gánh nhiều việc.** `DashboardScreen.build` và `TrendsScreen.build` trộn lẫn: tính dữ liệu, format hiển thị, và rẽ nhánh layout trong một hàm ~300 dòng có closure `LayoutBuilder` lồng nhau — khó đọc, khó test từng phần riêng.
- **Constructor factory quá dài.** `Publication.fromJson` ([publication.dart:37-134](lib/models/publication.dart#L37-L134)) nhúng 4 chuỗi `.whereType().map().where()` lồng nhau (cho authors/institutions/countries/keywords) trong một khối ~100 dòng. Hàm `_extractJournalName` đã làm đúng cách (tách ra hàm static riêng) — nên áp dụng tương tự cho các phần còn lại.
- **Switch chuyển label loại bài viết bị định nghĩa 2 lần.** `_labelWorkType` xuất hiện độc lập ở [analytics_calculator.dart:261-272](lib/utils/analytics_calculator.dart#L261-L272) và [publication_detail_screen.dart:255-264](lib/screens/publication_detail_screen.dart#L255-L264), với **fallback khác nhau** (`'Other'` vs trả về nguyên giá trị gốc) — dễ gây lệch dữ liệu nếu chỉ sửa một nơi.

## 2. Khả năng bảo trì & Đọc hiểu (Maintainability & Readability)

- **Không có hằng số design-system chung trong code.** Có thư mục `design-system/` ở gốc repo nhưng chỉ chứa tài liệu, `lib/` không tái sử dụng — mỗi screen tự định nghĩa hằng số khoảng cách/chiều rộng riêng với tên khác nhau cho cùng một khái niệm (`_kMaxContentWidth`/`_kChartHeight` ở dashboard vs `_kMaxW`/`_kChartH` ở trends), và hardcode màu hex riêng thay vì dùng `ColorScheme` đã định nghĩa trong [app.dart](lib/app.dart).
- **Mất kiểu dữ liệu không cần thiết.** `SearchScreen._pushDetail(BuildContext context, dynamic publication)` ([search_screen.dart:435](lib/screens/search_screen.dart#L435)) nhận `dynamic` trong khi mọi nơi gọi đều truyền `Publication`. Nên khai báo đúng kiểu.
- **Lộ thông báo lỗi gốc ra UI.** `ResearchProvider.search` dùng `catch (error) { ...; _errorMessage = error.toString(); }` ([research_provider.dart:101-104](lib/providers/research_provider.dart#L101-L104)). Hiện tại "trông an toàn" chỉ vì `OpenAlexException.toString()` tình cờ trả về message sạch — nếu sau này có exception loại khác (ví dụ `FormatException`/`TypeError`) thì văn bản lỗi thô của Dart sẽ hiển thị thẳng cho người dùng.
- **`NumberFormat` được tạo lại nhiều lần.** `NumberFormat.compact()`/`decimalPattern()` được khởi tạo mới ngay trong gần như mọi `build()` (analytics, dashboard, trends, search, detail) thay vì dùng chung một formatter — lặp lại cùng một mẫu ở 8+ nơi.

## 3. Ảnh hưởng hiệu năng (Performance Implications)

- **`ResearchProvider` không có memoization (bộ nhớ đệm kết quả tính toán).** Mọi getter (`trends`, `journals`, `authors`, `summary`, `citationTrends`, `topKeywords`, `topInstitutions`, `topCountries`, `authorImpacts`, `workTypes`) tính lại từ đầu mỗi lần được gọi — và `filteredPublications` cũng lọc lại toàn bộ danh sách mỗi lần truy cập ([research_provider.dart:38-47](lib/providers/research_provider.dart#L38-L47)). Riêng `summary()` đã gọi lại `publicationTrends`, `topJournals`, `topAuthors`, `influentialPapers` ([analytics_calculator.dart:59-80](lib/utils/analytics_calculator.dart#L59-L80)), mỗi hàm tự sort O(n log n). Một lần rebuild của `DashboardScreen` có thể duyệt danh sách publication hàng chục lần. Hiện tại giới hạn 100 item nên chưa thấy rõ, nhưng không có lớp cache nào nếu giới hạn này tăng lên.
- **Cây widget trang trí (decorated container) bị dựng lại lặp nhiều lần.** 3 widget card bị lặp (mục 1) đều dựng lại cùng một cấu trúc `Container > BoxDecoration > Row > Container` mỗi lần parent rebuild — gộp lại thành 1 widget chung sẽ giảm cả code lẫn chi phí layout.
- **Không dùng `TextTheme` đã cache sẵn.** [app.dart](lib/app.dart) đã build `GoogleFonts.plusJakartaSansTextTheme()` một lần, nhưng một số screen (`publication_detail_screen.dart`, `search_screen.dart`) lại gọi trực tiếp `GoogleFonts.plusJakartaSans(...)`/`GoogleFonts.spaceGrotesk(...)` thay vì dùng `Theme.of(context).textTheme`, khiến cơ chế cache của google_fonts bị bỏ qua.

## 4. Khả năng kiểm thử (Testability)

- **Gần như không có test.** [test/widget_test.dart](test/widget_test.dart) chỉ là placeholder (`expect(true, isTrue)`). Trong khi `AnalyticsCalculator` là class static thuần (pure), rất dễ viết unit test; `Publication.fromJson`/`parseAbstractInvertedIndex` chỉ là parse JSON thuần — cả hai đều là mục tiêu test "ít công, nhiều lợi" nhưng hiện chưa có test nào.
- **Repository chưa có abstraction (interface).** `PublicationRepository` là class cụ thể gắn cứng với `OpenAlexService` ([publication_repository.dart](lib/repositories/publication_repository.dart)), không có interface trừu tượng. `OpenAlexService` có nhận `http.Client` injectable nên có thể fake tầng HTTP, nhưng để test `ResearchProvider` vẫn phải dựng `OpenAlexService` thật + mock `http.Client`, thay vì thay thế bằng một repository giả đơn giản.
- **Phụ thuộc cấu hình toàn cục (global state).** `OpenAlexService.searchWorks` đọc trực tiếp `dotenv.env['OPENALEX_API_KEY']` ([openalex_service.dart:39](lib/services/openalex_service.dart#L39)) — trạng thái toàn cục có thể thay đổi (mutable) khiến việc test song song với nhiều cấu hình API key khác nhau trở nên khó khăn nếu không reset `dotenv` giữa các lần test.
- **Một số logic tính toán nằm trong widget thay vì trong calculator.** Phần lớn logic phân tích đã được đặt trong `AnalyticsCalculator` (tốt, dễ test), nhưng một số chỗ — ví dụ `top5Pct`/`multiVenue` trong `_JournalsTab.build` ([analytics_screen.dart:100-105](lib/screens/analytics_screen.dart#L100-L105)) — lại được tính trực tiếp trong `build()`, nên chỉ có thể kiểm tra qua widget test đầy đủ thay vì unit test thuần.

## Kết luận

Tầng dữ liệu (`AnalyticsCalculator`, `Publication.fromJson`, `OpenAlexService`) có cấu trúc tốt và dễ test về mặt nguyên tắc; nợ kỹ thuật chính nằm ở tầng screens — 3 widget card/header bị lặp, công thức layout bị lặp, và hoàn toàn chưa có test. Ưu tiên xử lý:

1. Gộp 3 widget card trùng lặp thành 1 widget chung (sửa nhanh, chỉ ảnh hưởng 3 file).
2. Viết unit test cho `AnalyticsCalculator` và `Publication.fromJson` (lợi ích cao nhất, rủi ro bằng 0).
3. Chỉ tối ưu memoization của `ResearchProvider` nếu kích thước tập kết quả tăng lên trong tương lai — chưa cần thiết ngay lúc này.
