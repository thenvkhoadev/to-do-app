# Nexus AI (to_do_app)

Ứng dụng Flutter theo hướng **productivity / task management** với giao diện dark-mode, đăng nhập/đăng ký qua **Supabase Auth** và cấu hình môi trường bằng **`.env`**.

> Lưu ý: Tên package hiện tại là `to_do_app` nhưng UI/branding trong app đang hiển thị là **Nexus AI**.

## Tính năng chính

- Landing page (marketing) + điều hướng sang trang đăng nhập.
- Đăng nhập / đăng ký bằng email & password (Supabase).
- Dashboard sau khi đăng nhập (tab Home/Tasks/AI; một số màn hình mang tính demo/UI).
- Mẫu schema Supabase cho bảng `users`, `tasks`, RLS policies và trigger tạo profile người dùng.

## Công nghệ sử dụng

- Flutter / Dart (SDK: `^3.7.0`)
- Supabase: `supabase_flutter`
- Quản lý biến môi trường: `flutter_dotenv` (load `.env` như asset)

## Cấu trúc thư mục (rút gọn)

- `lib/main.dart`: Entry point, load `.env`, khởi tạo Supabase.
- `lib/screens/`: Landing + Sign in/Sign up + dashboard shell đang được dùng bởi entrypoint.
- `lib/features/`: Các module theo hướng feature-first (auth/tasks/ai/calendar/profile). Một số phần có thể đang trong quá trình tích hợp.
- `supabase_schema.sql`: SQL tạo bảng + RLS policies + trigger cho Supabase.

## Yêu cầu

- Flutter SDK (khuyến nghị dùng Flutter stable)
- Một project Supabase (URL + anon key)

## Cài đặt & chạy nhanh

### 1) Cài dependencies

```bash
flutter pub get
```

### 2) Tạo file `.env`

Tạo file `.env` ở thư mục gốc project (cùng cấp `pubspec.yaml`). File này đã được ignore trong `.gitignore`.

Bạn có thể lấy `SUPABASE_URL` và `SUPABASE_ANON_KEY` tại Supabase Dashboard → Project Settings → API.

Ví dụ:

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

# Optional: nếu bạn có backend riêng (mặc định sẽ fallback về SUPABASE_URL)
API_BASE_URL=
```

### 3) Khởi tạo database trên Supabase

Mở `supabase_schema.sql` và chạy trong **Supabase SQL Editor** để tạo:

- `public.users` (profile)
- `public.tasks`
- Row Level Security (RLS) + policies
- Trigger `handle_new_user()` để tự tạo/cập nhật profile khi có user mới

Ngoài ra, hãy bật Email/Password provider trong Supabase Auth (Authentication → Providers).

### 4) Run app

```bash
flutter run
```

Chạy web (ví dụ Chrome):

```bash
flutter run -d chrome
```

## Lệnh hữu ích

Format code:

```bash
dart format .
```

Phân tích/lint:

```bash
flutter analyze
```

Chạy test:

```bash
flutter test
```

Build release:

```bash
flutter build apk
flutter build ios
flutter build web
```

Ghi chú: `flutter build ios` chỉ chạy được trên macOS.

## Ghi chú

- `.env` được khai báo trong `pubspec.yaml` (assets) và được load ở runtime trong `lib/main.dart`.
- Nếu bạn muốn version hóa schema DB, hãy cân nhắc **bỏ `supabase_schema.sql` khỏi `.gitignore`** (hiện tại file này đang bị ignore).

## Tài liệu tham khảo

- Flutter docs: https://docs.flutter.dev/
- Supabase Flutter: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter
