# Firebase Setup — Journexa (PRM393 Lab 03)

App tích hợp 6 dịch vụ Firebase: **Authentication (Google Sign-In), Storage,
Cloud Messaging, Analytics, Crashlytics, Remote Config**. Trước khi cấu hình,
app vẫn chạy được ở **chế độ khách** (nút "Continue as guest" trên màn Login) —
mọi tính năng Firebase tự động tắt an toàn.

## 1. Tạo project & sinh cấu hình (bắt buộc)

```bash
# Cài CLI (1 lần)
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Đăng nhập Google
firebase login

# Từ thư mục project — tạo/chọn Firebase project và sinh config
flutterfire configure
```

`flutterfire configure` sẽ:
- Ghi đè `lib/firebase_options.dart` (hiện là placeholder) bằng options thật.
- Tạo `android/app/google-services.json`.

> Gradle được cấu hình **conditional**: plugin google-services/crashlytics chỉ
> apply khi `google-services.json` tồn tại, nên trước bước này app vẫn build.

## 2. Bật Google Sign-In

1. Firebase Console → **Authentication → Sign-in method** → bật **Google**.
2. Thêm SHA-1 debug vào project (Console → Project settings → Your apps →
   Add fingerprint):
   ```bash
   cd android && ./gradlew signingReport
   # copy SHA-1 của variant debug
   ```
3. Tải lại `google-services.json` sau khi thêm SHA-1 (hoặc chạy lại
   `flutterfire configure`).

## 3. Storage (upload PDF report)

> **Cần gói Blaze (pay-as-you-go).** Firebase Storage không còn hỗ trợ gói
> Spark (free) cho project mới — Console sẽ yêu cầu "Upgrade project" trước
> khi bật được Storage. Gói Blaze vẫn có hạn mức miễn phí hàng tháng (5GB
> lưu trữ, 1GB/ngày tải xuống), nên dùng cho lab này thường **không tốn phí**,
> nhưng bắt buộc phải nhập thẻ thanh toán khi nâng cấp.
>
> **Chưa nâng cấp cũng không sao** — app đã xử lý graceful fallback: nút
> "Export PDF report" luôn tạo file PDF thành công; nếu bước upload lên
> Storage thất bại (chưa bật/chưa nâng cấp), app tự hiển thị đường dẫn file
> **lưu local** thay vì báo lỗi (xem `ProfileScreen._exportPdf`). Khi nào
> nâng cấp Blaze và làm xong các bước dưới đây, upload sẽ tự động hoạt
> động — không cần sửa code.

Console → **Storage → Get started** (yêu cầu nâng cấp Blaze trước nếu chưa).
Rules cho lab (yêu cầu đăng nhập):

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /reports/{userId}/{file} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 4. Cloud Messaging (FCM)

Không cần cấu hình thêm. Chạy app, xem logcat dòng `FCM registration token:`,
rồi Console → **Messaging → New campaign → Send test message** dán token đó.
Thông báo nhận khi app foreground sẽ hiện trong **Profile → Notification
Center**.

## 5. Remote Config

Console → **Remote Config → Create configuration**, thêm 2 parameter:

| Key | Type | Default gợi ý |
|---|---|---|
| `max_journals` | Number | 10 |
| `max_keywords` | Number | 15 |

Publish changes → trong app bấm **Profile → Remote Config → Refresh** để thấy
giá trị mới (màn Journals/Keywords cũng đổi số item theo).

## 6. Crashlytics

Console → **Crashlytics → Enable**. Trong app: **Profile → Crashlytics**:
- *Handled exception* → gửi non-fatal error.
- *Force test crash* → crash app; mở lại app để report được upload.
  (Report có thể mất vài phút để hiện trên console.)

## 7. Analytics

Tự động sau khi configure. Events app gửi: `login`, `search_topic(keyword)`,
`view_publication(publication_title, publication_year)`,
`view_journal(journal_name)`, `view_keyword(keyword)`, `export_pdf(topic)`,
`logout`. Xem realtime: Console → **Analytics → DebugView** (bật debug mode:
`adb shell setprop debug.firebase.analytics.app com.example.journal_trend_analyzer`).

## 8. Patrol E2E tests

```bash
dart pub global activate patrol_cli
patrol test          # chạy toàn bộ integration_test/ trên thiết bị/emulator
patrol test -t integration_test/authentication_test.dart   # 1 file
```

Lưu ý: Test Case 1 (Google Sign-In) và 9 (PDF upload) cần Firebase đã cấu
hình + có tài khoản Google trên thiết bị; các test còn lại chạy được cả ở
guest mode.

## Ghi chú `.env`

Firebase **không** dùng biến `.env` (cấu hình nằm trong
`firebase_options.dart` + `google-services.json`). File `.env` chỉ chứa
`OPENALEX_API_KEY` như trước.
