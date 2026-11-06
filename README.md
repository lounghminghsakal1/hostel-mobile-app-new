# Our Hostel

The Flutter app for [Hostel-Management-Backend-Nodejs](../../Backend%20Projects/Hostel-Management-Backend-Nodejs).
One app, two roles: students mark attendance, apply for leave and read notices;
hostel admins track attendance, manage rooms, students, leave, notices, mess bills and settings.

| | |
| --- | --- |
| Display name | Our Hostel (`AppConfig.appName`, Android `android:label`, iOS `CFBundleDisplayName`) |
| Dart package | `our_hostel` |
| Android application id | `in.ourhostel.our_hostel` |
| iOS bundle id | `in.ourhostel.ourHostel` |

## App logo

![Our Hostel logo](assets/icon/app_icon_rounded.png)

A ribbon-style house with an "H" inside, in a mint-to-lavender gradient on deep indigo.
It is drawn in code (`OurHostelLogoPainter` in `lib/core/widgets/brand.dart`) from the theme
palette, and the launcher icons are exported from the same painter:

```bash
flutter test tool/app_icon_generator_test.dart
```

```bash
dart run flutter_launcher_icons
```

## Run it

1. Copy `.env.example` to `.env` and set `API_BASE_URL`. `.env` is git-ignored and is
   required, because it's bundled as an asset.
2. Run:

```bash
flutter pub get
flutter run
```

```bash
flutter test
```

`--dart-define=API_BASE_URL=…` overrides `.env`, for example in CI. With neither, the app uses
`https://api.ourhostel.in/api/v1/`. In debug builds the console prints `API base URL: …` at start.

**About ".env = secure":** `.env` keeps the URL out of the code and out of git, and lets each
developer point at their own server. It is **not** secret: it ships inside the app, and anyone
can unpack an APK and read it. The API URL isn't secret anyway, since every request shows it.
Never put API keys, passwords or other secrets in a mobile app. Keep those on the backend.

## Running against a local backend

The backend listens on port `2471` with the prefix `/api/v1`, so the URL is
`http://<host>:2471/api/v1/`. What `<host>` is depends on where the app runs:

| Running on | Use | Why |
| --- | --- | --- |
| Android emulator | `localhost` (the app swaps it for `10.0.2.2`) | Inside the emulator, `localhost` is the emulator itself. `10.0.2.2` is the emulator's alias for your PC. |
| Android phone (USB) | `localhost`, after running `adb reverse tcp:2471 tcp:2471` | Forwards the phone's port 2471 to your PC. |
| Android phone (Wi-Fi) | Your PC's IP, e.g. `192.168.1.20` (`ipconfig` → IPv4) | The phone and PC must be on the same Wi-Fi. Allow Node.js through Windows Firewall. |
| iOS simulator | `localhost` | The simulator shares the Mac's network. |

Plain `http://` is allowed only in **debug and profile** builds
(`android/app/src/debug/AndroidManifest.xml`; on iOS, `NSAllowsLocalNetworking`). Release builds
are https-only, so a release build must point at the https server. If the server can't be reached,
debug builds show the exact address that failed.

## Folder structure

```
lib/
  main.dart                 Loads .env and preferences, resolves the API URL, starts Riverpod
  app/
    app.dart                MaterialApp, theme from the active palette
    router/                 Every route, plus redirects by sign-in state and role
  core/                     Shared by everything, knows nothing about features
    config/                 .env reading (env.dart), app name, timeouts, page size
    theme/                  Colour palette, theme builder, text styles, spacing
    network/                Dio client, token refresh, endpoints, error mapping
    storage/                Secure token storage, shared preferences
    services/               Camera/gallery and GPS
    models/ utils/          Paging types, dates (IST), validators, formatting
    widgets/                Design-system components (buttons, cards, badges, sheets…)
  features/
    auth/                   Login, forgot/set/change password, session state
    common/                 Used by both roles: announcements, events, media upload,
                            leave/student/mess-bill models
    student/                Student flow only
      home/ attendance/ leave/ notices/ fees/ profile/ shell/
    admin/                  Hostel admin flow only
      home/ attendance/ rooms/ students/ leave/ notices/ mess_bills/ settings/ account/ shell/
```

Every feature uses the same three layers:

| Layer | Holds | Depends on |
| --- | --- | --- |
| `domain/` | Entities, the repository interface, use cases with business rules | Nothing (pure Dart) |
| `data/` | JSON models, the remote data source (Dio calls), the repository implementation | `domain`, `core/network` |
| `presentation/` | Riverpod providers, screens, widgets | `domain` (and `data` only to wire providers) |

Use cases exist where there is a rule to enforce (leave dates, one pending request, room capacity,
reject needs a reason, event end after start, attendance = upload then submit). Plain reads go
straight from a provider to the repository.

### Adding a feature

1. `features/<role>/<feature>/domain/`: entity + `abstract interface class XRepository`.
2. `data/`: model with `fromJson`, a data source using `dioProvider`, `XRepositoryImpl` wrapping
   every call in `guardApi(...)` so screens only ever see `AppException`.
3. `presentation/`: providers + screens. Add the path to `app/router/routes.dart` and the route
   to `app_router.dart`.

## Theme: one place to change the colours

All colours live in `lib/core/theme/app_palette.dart` (`AppPalette.ourHostel`: Iris `#5B47E0`,
Coral `#FF7A59`, Mint `#12B886`). Widgets read them through `context.colors` and never use raw
hex values, so changing the palette re-colours the whole app.

`ThemeController` (`lib/core/theme/theme_controller.dart`) holds the active palette and caches
it on the device. A palette serialises to JSON (`toJson`/`fromJson`), so letting a hostel admin
pick colours later only needs:

1. A backend field or endpoint for the hostel's palette JSON.
2. After sign-in: `ref.read(themeControllerProvider.notifier).applyPalette(AppPalette.fromJson(json))`.
3. An admin screen that edits the colours and saves them.

Fonts: Bricolage Grotesque for headings, Plus Jakarta Sans for everything else (`google_fonts`).
For release builds, bundle the font files as assets so they work offline.

## Sign-in, access token and refresh token

How the backend works (`src/modules/auth/auth.service.js`):

- `POST /auth/login` returns `{user, tokens: {accessToken, refreshToken}}`.
- The access token lasts **15 minutes**. The session lasts **7 days**.
- `POST /auth/refresh {refreshToken}` returns a new access token and a new refresh token.
- A refresh token works **once**. Reusing one revokes the whole session.

How the app handles it:

- Tokens and the signed-in user are stored in the Keystore/Keychain (`TokenStorage`).
- `AuthInterceptor` adds `Authorization: Bearer …` to every request. On a 401 it refreshes and
  retries the request.
- It is a `QueuedInterceptor`: when several requests fail together, only the first one
  refreshes and the rest reuse the new token. This prevents a used refresh token from being
  sent again, which would log the user out. `test/core/auth_interceptor_test.dart` covers this.
- If the server rejects the refresh (expired, revoked or reused), tokens are cleared and the
  app returns to the login screen with "Your session ended". If the phone is offline, the
  tokens are kept.
- Sign-out calls `POST /auth/logout` (best effort) and always clears local tokens.
- On launch, a saved session opens the right home screen (student or admin) without a network call.

## Mess fees

- Hostel admins can create, edit and publish bills for **this month and next month only**
  (India time). The backend enforces the same rule; drafts for a past month can only be deleted.
- Students see the published bills. Online payment isn't built yet, so **Pay** opens a sheet that
  says to pay at the hostel office: Shift 1 students 2:00–4:00 PM, Shift 2 students 9:00–11:00 AM.
  The text and hours come from `GET /mess_fee/my_bills` (`paymentInfo`); the app keeps a copy as a
  fallback in `MessFeePaymentInfo.fallback`.

## Email links

Activation and reset emails link to `ourhostel://setup-password?token=…&mode=welcome|reset`.
Android (`AndroidManifest.xml`) and iOS (`Info.plist`) register the `ourhostel` scheme, and the
router sends the link to the Set password screen. Test it on an Android emulator with:

```bash
adb shell am start -a android.intent.action.VIEW -d "ourhostel://setup-password?token=test&mode=welcome"
```

Some email apps don't make custom-scheme links tappable. See section 5 of
[docs/API_GAPS.md](docs/API_GAPS.md) for switching to https App Links.

## Backend gaps

Screens whose API doesn't exist yet are built and wired, but their data-source method throws
`ApiPendingException`, so the screen shows a friendly "Coming soon". Each one is marked
`TODO(api)` and explained, with how to build it, in [docs/API_GAPS.md](docs/API_GAPS.md).
