# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

PhoenixKit plugin module template — a minimal, production-ready example for building PhoenixKit plugin modules. Implements the `PhoenixKit.Module` behaviour for auto-discovery by a parent Phoenix application.

## Common Commands

### Setup & Dependencies

```bash
mix deps.get                # Install dependencies
```

### Testing

```bash
mix test                        # Run all tests
mix test test/phoenix_kit_hello_world_test.exs  # Run specific test file
mix test test/file_test.exs:42  # Run specific test by line
```

### Code Quality

```bash
mix format                  # Format code (imports Phoenix LiveView rules)
mix credo --strict          # Lint / code quality (strict mode)
mix dialyzer                # Static type checking
mix precommit               # compile + format + credo --strict + dialyzer
mix quality                 # format + credo --strict + dialyzer
mix quality.ci              # format --check-formatted + credo --strict + dialyzer
mix docs                    # Generate documentation
```

## Dependencies

This is a **library** (not a standalone Phoenix app) — there is no `config/` directory, no endpoint, no router. The full dependency chain:

- `phoenix_kit` (path: `"../phoenix_kit"`) — provides Module behaviour, Settings, RepoHelper, Dashboard tabs
- `phoenix_live_view` — web framework (LiveView UI)

## Architecture

This is a **PhoenixKit module** that implements the `PhoenixKit.Module` behaviour. It depends on the host PhoenixKit app for Repo, Endpoint, and Settings.

### How It Works

1. Parent app adds this as a dependency in `mix.exs`
2. PhoenixKit scans `.beam` files at startup and auto-discovers modules (zero config)
3. `admin_tabs/0` callback registers admin pages; PhoenixKit generates routes at compile time
4. Settings are persisted via `PhoenixKit.Settings` API (DB-backed in parent app)
5. Permissions are declared via `permission_metadata/0` and checked via `Scope.has_module_access?/2`

### Key Modules

- **`PhoenixKitHelloWorld`** (`lib/phoenix_kit_hello_world.ex`) — Main module implementing `PhoenixKit.Module` behaviour. Declares required callbacks (`module_key`, `module_name`, `enabled?`, `enable_system`, `disable_system`) and optional ones (`admin_tabs`, `permission_metadata`, `get_config`, etc.).

- **`PhoenixKitHelloWorld.Web.HelloLive`** (`lib/phoenix_kit_hello_world/web/hello_live.ex`) — LiveView page for the admin panel. PhoenixKit wraps it in the admin layout automatically.

### Settings Keys

`hello_world_enabled`

### File Layout

```
lib/phoenix_kit_hello_world.ex                    # Main module (PhoenixKit.Module behaviour)
lib/phoenix_kit_hello_world/
├── routes.ex                                    # Route module scaffold (for multi-page modules)
└── web/
    └── hello_live.ex                            # Admin LiveView page
```

## Critical Conventions

- **Module key** must be consistent across all callbacks: lowercase with underscores (`"hello_world"`)
- **Tab IDs**: prefixed with `:admin_` (e.g., `:admin_hello_world`)
- **URL paths**: use hyphens, not underscores (`"hello-world"`)
- **Navigation paths**: always use `PhoenixKit.Utils.Routes.path/1`, never relative paths
- **`enabled?/0`**: must rescue errors and return `false` as fallback (DB may not be available)
- **LiveViews**: use `use PhoenixKitWeb, :live_view` which imports PhoenixKit's core components (`<.icon>`, `<.button>`, etc.), Gettext, layout config, and HTML helpers. External modules that use `use Phoenix.LiveView` directly must import helpers explicitly instead.
- **JavaScript hooks**: must be inline `<script>` tags; register on `window.PhoenixKitHooks`
- **LiveView assigns** available in admin pages: `@phoenix_kit_current_scope`, `@current_locale`, `@url_path`

### Commit Message Rules

Start with action verbs: `Add`, `Update`, `Fix`, `Remove`, `Merge`.

## Routing: Single Page vs Multi-Page

**Single admin page** (this template): The `live_view:` field on `admin_tabs/0` auto-generates the route. No route module needed.

**Multiple admin pages**: You MUST use a route module. The `live_view:` field only generates ONE route per tab — it can't handle sub-pages like `/admin/your-module/new` or `/admin/your-module/:id/edit`. Steps:

1. Uncomment the routes in `lib/phoenix_kit_hello_world/routes.ex`
2. Uncomment `route_module/0` in the main module
3. Remove the `live_view:` field from `admin_tabs/0` (the route module takes over)
4. Define ALL admin LiveView routes in both `admin_locale_routes/0` AND `admin_routes/0`

Both functions define the same routes — one for localized paths (`:locale` prefix) and one for non-localized. Every route needs a unique `:as` name (use `_localized` suffix).

**Catch-all public routes** (`/:slug`, `/:group/*path`): MUST go in `public_routes/1`, NOT `generate/1`. Routes in `generate/1` are placed early and will intercept `/admin/*` paths.

### How route discovery works

Module routes are auto-discovered at compile time — no manual registration needed:

1. `use PhoenixKit.Module` persists a `@phoenix_kit_module` marker in the `.beam` file
2. PhoenixKit's `ModuleDiscovery` scans beam files of deps that depend on `:phoenix_kit`
3. For each discovered module, it calls `route_module/0` to get the route module
4. Admin routes (`admin_routes/0`, `admin_locale_routes/0`) and public routes (`generate/1`, `public_routes/1`) are compiled into the host router via the `phoenix_kit_routes()` macro
5. The host router auto-recompiles when module deps are added or removed (via `__mix_recompile__?/0` hash comparison)

## Tailwind CSS Scanning

Modules with templates using Tailwind classes must implement `css_sources/0` returning their OTP app name as an atom list (e.g., `[:phoenix_kit_hello_world]`). CSS source discovery is **automatic at compile time** — the `:phoenix_kit_css_sources` compiler scans all discovered modules and writes `assets/css/_phoenix_kit_sources.css`. The parent app's `app.css` imports this generated file.

## Database & Migrations

This template module has no database tables. Modules that need DB tables should have their migrations created in the parent `phoenix_kit` project as a new versioned migration (e.g., `V90`).

## Testing

### Running tests

```bash
mix test                                        # All tests
mix test test/phoenix_kit_hello_world_test.exs  # Module behaviour tests
```

### Version compliance test

The test file verifies `module_key/0`, `module_name/0`, `version/0`, `permission_metadata/0`, `admin_tabs/0`, and `css_sources/0`.

## Versioning & Releases

This project follows [Semantic Versioning](https://semver.org/).

### Version locations

The version must be updated in **three places** when bumping:

1. `mix.exs` — `@version` module attribute
2. `lib/phoenix_kit_hello_world.ex` — `def version, do: "x.y.z"`
3. `test/phoenix_kit_hello_world_test.exs` — version compliance test

### Tagging & GitHub releases

Tags use **bare version numbers** (no `v` prefix):

```bash
git tag 0.1.0
git push origin 0.1.0
```

GitHub releases are created with `gh release create`:

```bash
gh release create 0.1.0 \
  --title "0.1.0 - 2026-03-24" \
  --notes "$(changelog body for this version)"
```

### Full release checklist

1. Update version in `mix.exs`, `lib/phoenix_kit_hello_world.ex` (`version/0`), and the version test
2. Add changelog entry in `CHANGELOG.md`
3. Run `mix precommit` — ensure zero warnings/errors before proceeding
4. Commit all changes: `"Bump version to x.y.z"`
5. Push to main and **verify the push succeeded** before tagging
6. Create and push git tag: `git tag x.y.z && git push origin x.y.z`
7. Create GitHub release: `gh release create x.y.z --title "x.y.z - YYYY-MM-DD" --notes "..."`

**IMPORTANT:** Never tag or create a release before all changes are committed and pushed. Tags are immutable pointers — tagging before pushing means the release points to the wrong commit.

## Pull Requests

### PR Reviews

PR review files go in `dev_docs/pull_requests/{year}/{pr_number}-{slug}/` directory. Use `{AGENT}_REVIEW.md` naming (e.g., `CLAUDE_REVIEW.md`, `GEMINI_REVIEW.md`).

Severity levels for review findings:

- `BUG - CRITICAL` — Will cause crashes, data loss, or security issues
- `BUG - HIGH` — Incorrect behavior that affects users
- `BUG - MEDIUM` — Edge cases, minor incorrect behavior
- `IMPROVEMENT - HIGH` — Significant code quality or performance issue
- `IMPROVEMENT - MEDIUM` — Better patterns or maintainability
- `NITPICK` — Style, naming, minor suggestions

## External Dependencies

- **PhoenixKit** (`~> 1.7`) — Module behaviour, Settings API, shared components, RepoHelper
- **Phoenix LiveView** (`~> 1.0`) — Admin LiveViews

## Two Module Types

- **Full-featured**: Admin tabs, routes, UI, settings (this template)
- **Headless**: Functions/API only, no UI — still gets auto-discovery, toggles, and permissions
