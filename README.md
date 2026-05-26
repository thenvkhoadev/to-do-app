# NexusAI (to_do_app)

Ứng dụng Flutter theo hướng **productivity / task management** (dark mode) với xác thực bằng **Supabase Auth** và cấu hình môi trường bằng **`.env`**.

> Ghi chú:
>
> - Package name hiện tại là `to_do_app`.
> - Tên app trong code (ví dụ `AppConstants.appName`) là **NexusAI**; một vài màn hình legacy có thể hiển thị branding khác.

## Mục lục

- [Tính năng](#tính-năng)
- [Luồng ứng dụng](#luồng-ứng-dụng)
- [Tech stack](#tech-stack)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Cấu hình môi trường](#cấu-hình-môi-trường)
- [Supabase: schema + bảo mật](#supabase-schema--bảo-mật)
- [Chạy dự án](#chạy-dự-án)
- [Troubleshooting](#troubleshooting)
- [Ghi chú bảo mật](#ghi-chú-bảo-mật)

## Tính năng

- Landing page (marketing) + điều hướng sang đăng nhập.
- Đăng nhập / đăng ký bằng email & password (Supabase).
- Dashboard sau khi đăng nhập (Home / Tasks / AI / Calendar / Profile; một số màn hình hiện tại mang tính demo UI).
- Mẫu schema Supabase: bảng `users`, `tasks`, RLS policies và trigger tạo profile.

## Luồng ứng dụng

Entrypoint hiện tại dùng `MaterialApp.router` + `GoRouter` (xem `lib/app.dart`, `lib/core/router/app_router.dart`). Router sẽ tự redirect dựa trên trạng thái đăng nhập Supabase session.

```mermaid
flowchart LR
	A[main.dart] --> B[NexusApp (MaterialApp.router)]
	B --> C[/splash]
	C -->|chưa đăng nhập| D[/ (Landing)]
	D --> E[/login]
	E -->|đăng nhập| F[Dashboard]
	F -->|sign out| E
```

Ghi chú về Dashboard hiện tại:

- Router có route `/home` trỏ tới `DashboardScreen` (UI dashboard mới, có responsive desktop/mobile).
- Màn `SignInPage` trong `lib/screens/sign_in_page.dart` hiện đang điều hướng sang `BlankPage` (legacy dashboard) bằng `Navigator.pushReplacement`.

Vì vậy, tuỳ đường đi (GoRouter vs Navigator legacy), bạn có thể thấy dashboard khác nhau.

## Tech stack

Đang được sử dụng bởi app hiện tại:

- Flutter / Dart (SDK: `^3.7.0`)
- Supabase: `supabase_flutter`
- Biến môi trường: `flutter_dotenv` (load `.env` như asset)
- State management: `flutter_riverpod`
- Routing: `go_router`
- HTTP client: `dio`
- Secure storage: `flutter_secure_storage`
- Fonts: `google_fonts`
- i18n/date utils: `intl`

## Cấu trúc thư mục

- `pubspec.yaml`: dependencies + khai báo asset `.env`.
- `lib/main.dart`: load `.env`, khởi tạo Supabase, chạy `NexusApp` (bọc `ProviderScope`).
- `lib/app.dart`: `MaterialApp.router` + theme dark.
- `lib/core/router/app_router.dart`: cấu hình `GoRouter` + redirect theo session.
- `lib/screens/` (một phần UI legacy):
  - `home.dart`: landing page.
  - `sign_in_page.dart`, `sign_up_page.dart`: auth UI.
  - `blank_page.dart`: legacy dashboard tabs + sign out.
- `lib/screens/dashboard/`: dashboard UI mới (responsive).
- `lib/features/`: modules theo feature-first (auth/tasks/ai/calendar/profile).
- `supabase_schema.sql`: schema + RLS policies + trigger (file local; hiện đang bị ignore trong `.gitignore` nên clone repo có thể không có).

## Cấu hình môi trường

### File `.env`

Project dùng `.env` ở root (cùng cấp `pubspec.yaml`). File này đã được ignore trong `.gitignore`.

Có sẵn file mẫu: `.env.example`.

Trên Windows (PowerShell):

```powershell
Copy-Item .env.example .env
```

Các biến môi trường:

| Key                 | Bắt buộc | Mô tả                                                       |
| ------------------- | -------: | ----------------------------------------------------------- |
| `SUPABASE_URL`      |       ✅ | URL project Supabase                                        |
| `SUPABASE_ANON_KEY` |       ✅ | Anon public key (client-side)                               |
| `API_BASE_URL`      |       ⛔ | Optional. Nếu không set, code sẽ fallback về `SUPABASE_URL` |

Bạn có thể lấy `SUPABASE_URL` và `SUPABASE_ANON_KEY` tại Supabase Dashboard → Project Settings → API.

Quy ước khuyến nghị cho `.env`:

- Không bọc giá trị bằng dấu nháy.
- Tránh khoảng trắng ở đầu/cuối (code có `.trim()` ở entrypoint).
- Chỉ dùng key public (`anon`), không dùng `service_role`.

> Nếu bạn chỉnh `assets:` trong `pubspec.yaml`, hãy chạy lại `flutter pub get`.

## Supabase: schema + bảo mật

### 1) Tạo project & bật Auth

- Tạo project trên Supabase.
- Authentication → Providers → bật **Email**.

### 2) Apply schema

Nếu workspace của bạn có file `supabase_schema.sql`, hãy mở và chạy trong **Supabase SQL Editor**.

Nếu bạn clone repo mà không thấy file này, kiểm tra `.gitignore` (file đang được ignore theo mặc định) hoặc xin lại script schema từ owner.

Nếu gặp lỗi kiểu `function gen_random_uuid() does not exist`, hãy bật extension `pgcrypto` trong Supabase (Database → Extensions) rồi chạy lại.

Schema hiện có:

- `public.users`: bảng profile, tham chiếu `auth.users(id)`.
- `public.tasks`: bảng tasks, có `user_id` tham chiếu `auth.users(id)`.

RLS & policies (tóm tắt):

- `public.users`: user chỉ đọc/insert/update chính họ (`auth.uid() = id`).
- `public.tasks`: user chỉ thao tác tasks của họ (`auth.uid() = user_id`).

Trigger:

- `handle_new_user()` chạy sau khi tạo `auth.users` để upsert profile vào `public.users`.

### 3) (Tuỳ chọn) Realtime cho tasks

Nếu bạn dùng stream realtime (ví dụ code ở `lib/features/tasks/data/datasource/task_remote_datasource.dart`), hãy đảm bảo table `tasks` được bật Realtime trong Supabase (Database → Replication / Realtime). Tùy cấu hình dự án, bạn có thể cần bật publication cho table.

## Chạy dự án

### Cài dependencies

```bash
flutter pub get
```

### Run

```bash
flutter run
```

Chạy web (Chrome):

```bash
flutter run -d chrome
```

## Lệnh hữu ích

Format:

```bash
dart format .
```

Analyze:

```bash
flutter analyze
```

Test:

```bash
flutter test
```

Build:

```bash
flutter build apk
flutter build web
flutter build ios
```

Ghi chú: `flutter build ios` chỉ chạy được trên macOS.

## Troubleshooting

### 1) App crash: “Missing SUPABASE_URL in .env” / “Missing SUPABASE_ANON_KEY in .env”

- Kiểm tra file `.env` có tồn tại ở root và đúng key.
- Đảm bảo bạn đã chạy `flutter pub get` (vì `.env` đang được khai báo trong assets).

### 2) Sign in thất bại (AuthException)

- Kiểm tra Email provider đã bật trong Supabase.
- Kiểm tra email/password đúng, hoặc user đã được tạo.

### 3) Query bị “permission denied” / không thấy data

- Kiểm tra RLS policies trong `supabase_schema.sql` đã apply.
- Đảm bảo đang đăng nhập và `auth.uid()` match đúng với `users.id` / `tasks.user_id`.

### 4) Stream realtime không cập nhật

- Kiểm tra Realtime đã bật cho table `tasks`.
- Kiểm tra table có primary key đúng (code stream đang dùng `primaryKey: ['id']`).

### 5) `flutter analyze` báo thiếu package (ví dụ Riverpod/GoRouter/Dio/secure storage)

Nếu bạn gặp lỗi analyze liên quan tới import/package:

- Chạy lại `flutter pub get`.
- Kiểm tra `pubspec.yaml` đã có dependency tương ứng.

Repo hiện đã khai báo sẵn các package chính như `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`.

## Ghi chú bảo mật

- Chỉ dùng `SUPABASE_ANON_KEY` (public) ở client. **Không** đưa `service_role` key vào app.
- Với Flutter web, `.env` là asset và sẽ nằm trong bundle build; vì vậy chỉ nên chứa thông tin “public” (URL + anon key là chấp nhận được theo mô hình Supabase).

## Tham khảo

- Flutter docs: https://docs.flutter.dev/
- Supabase Flutter: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter
