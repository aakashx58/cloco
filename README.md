# Product Manager (Flutter · BLoC · go_router · get_it · Dio · ScreenUtil)

A small admin app for managing registered users and products.

- **Auth**: register and log in against users stored locally with `shared_preferences`
- **Users**: create, edit and delete registered users
- **Products**: create, edit and delete products through the [dummyjson](https://dummyjson.com/docs/products) API

## Run

```bash
flutter pub get
flutter run          # pick an emulator/device, or: flutter run -d chrome / -d windows
flutter test         # 40 tests: unit, bloc, router guard, end-to-end flow, layout at 5 screen sizes
```

Tested with Flutter 3.44 / Dart 3.12.

## How it meets the requirements

| Requirement | Where |
|---|---|
| 3.1.1 Login screen with a register option; after registering, return to login | `features/auth/view/` — the register page pops back to login with the email filled in and does **not** auto-login |
| 3.1.2 Already logged in → dashboard | `AuthStarted` is dispatched when the `AuthBloc` is created; the go_router guard (`AppRoutes.redirect`) sends signed-in users from splash/login to `/products` |
| 3.1.3 Log in with credentials from local storage | `AuthRepository.login` against `UserRepository` (`shared_preferences`) |
| 3.2.1 CRUD for registered users | Dashboard → **Users** tab (`UsersBloc`) |
| 3.2.2 CRUD for products via the API | Dashboard → **Products** tab (`ProductsBloc`, `ProductDetailBloc`, `ProductFormBloc`) |

### API endpoints used

| Endpoint | Used for |
|---|---|
| `GET /products?skip=&limit=10` | Paginated list with infinite scroll |
| `GET /products/{id}` | Refreshing the detail page |
| `GET /products/search?q=` | Search bar (400 ms debounce) |
| `GET /products/categories` | Category chips and the category dropdown in the form |
| `GET /products/category/{slug}` | Category filter |
| `POST /products/add` | Add product |
| `PUT /products/{id}` | Edit product (full form) |
| `PATCH /products/{id}` | Adjust stock on the detail page (sends only `{stock}`) |
| `DELETE /products/{id}` | Delete product |

## Design notes

**Architecture.**

```text
lib/
  core/
    di/injection.dart          get_it container (the composition root)
    network/dio_client.dart    Dio setup + DioException → ApiException
    router/                    go_router config, route paths, auth guard
    theme/ widgets/ utils/ ... shared UI and helpers
  data/                        models + repositories (no Flutter imports)
  features/<feature>/bloc      blocs (events/states)
  features/<feature>/view      screens and widgets
```

**Dependency injection (get_it).** `configureDependencies()` registers everything:
- **Singletons:** `SharedPreferences`, `Dio`, the repositories, and the app-wide `AuthBloc`, which the router also needs.
- **Factories:** screen and session blocs. `ProductDetailBloc` is a `registerFactoryParam` (product id plus the list item it was opened from).

get_it only constructs the blocs. The widget tree owns their lifecycle through `BlocProvider`, so they are closed automatically. Screens never construct repositories themselves.

**Routing (go_router).**

| Route | Screen |
|---|---|
| `/splash` | Checking the session |
| `/login`, `/login/register` | Sign in, register |
| `/products`, `/users` | Dashboard tabs (`StatefulShellRoute`, each tab keeps its state) |
| `/products/new`, `/products/:id/edit` | Full-screen form |
| `/products/:id` | Product detail |

- **Session shell.** Every signed-in route sits inside a session `ShellRoute` that provides `UsersBloc` and `ProductsBloc`. Logging out leaves the shell and disposes them, so the next login starts clean.
- **Auth guard.** `AppRoutes.redirect` is a pure function of the auth state and URL, and it is unit-tested. It remembers the requested page (`?from=`), so a deep link survives the login, and it rejects unsafe return paths.
- **When the router refreshes.** It re-evaluates only when the signed-in status changes, not on loading or error states. A refresh that races a `pop` would otherwise restore the page that was just closed.
- **Deep links.** `/products/:id` works from a bare URL (browser refresh or deep link): it fetches the product by id when no list item is passed.

**Networking (Dio).**
- **One configured instance.** A single `Dio` carries the base URL (`https://dummyjson.com`), JSON content type and 15 s timeouts. A `LogInterceptor` is added in debug builds only.
- **Error mapping.** `DioException`s are mapped to a user-facing `ApiException`: timeout, network error, cancellation, or the API's own `message` for 4xx/5xx responses.
- **Tests.** Tests swap only the `HttpClientAdapter`, so the real Dio configuration and error mapping are exercised.

**Responsive sizing (flutter_screenutil).**
- **Units.** Text uses `.sp`, and sizes use `.w`, `.h` and `.r`. The Material 3 type scale in the theme is scaled too, so every `Text` follows the screen.
- **Bounded scaling.** Plain screenutil would scale a phone design about 4× on a monitor and about 0.5× on a landscape phone. Instead, `Responsive.designSizeFor` derives the design size from the actual screen, so all scale factors equal one zoom of `clamp(shortestSide / 390, 0.85, 1.3)`.
- **Wide screens.** Breakpoints handle wide layouts: a navigation rail and centred content with a maximum width. They don't magnify the UI.
- **Accessibility.** The user's system text size still applies on top of the scaled sizes.
- **Tests.** `responsive_layout_test.dart` renders the login, dashboard, detail and users screens at small phone, phone, landscape phone, tablet and desktop sizes. It fails on any layout overflow.

**Local storage.** Users are kept as a JSON list under `registered_users`. The session is the logged-in user's **id**, stored under `session_user_id`. Because the session stores the id and not the email, an admin can change their own email without being logged out.

**Password security.** `shared_preferences` is an unencrypted file on disk, so passwords are never stored in plain text. Each user gets a random salt, and only `SHA-256(salt:password)` is stored. The login error is the same for an unknown email and a wrong password, so the form doesn't reveal which emails are registered.

**Users screen safeguards.**
- Emails are trimmed and lowercased, so `Admin@x.com` and `admin@x.com` count as the same user.
- The logged-in admin can't delete their own account.
- When editing a user, a blank password field keeps the current password.

**dummyjson doesn't persist writes.** POST, PUT, PATCH and DELETE return a success response, but the server data never changes. Also, every added product comes back with the same id (`195`). To make CRUD behave correctly, `ProductRepository` keeps an in-memory overlay for the session:
- Created products get their own local ids and show a **Local** badge.
- Edits and deletions are re-applied to every fetch.

As a result, changes survive paging, searching, filtering and pull-to-refresh, and are reset when the app restarts. Editing or deleting a product created in the app skips the API call, because dummyjson would return a 404 for its id.

**Search and category filters.** The API can't combine a search with a category filter. Typing a search clears the selected category, and picking a category clears the search. Responses to an outdated search are discarded.

**UX.**
- Material 3 with light and dark themes.
- Skeleton cards while loading, plus empty and error states with a retry button.
- Pull-to-refresh on the product list.
- Buttons show a spinner and are disabled while a request is in progress, which prevents double submits.
- Destructive actions ask for confirmation.
- Wide screens switch to a navigation rail with centred content.
