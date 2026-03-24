# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhoenixKit plugin module template — a minimal, production-ready example for building PhoenixKit plugin modules. Implements the `PhoenixKit.Module` behaviour for auto-discovery by a parent Phoenix application.

## Common Commands

```bash
mix deps.get          # Install dependencies
mix test              # Run all tests
mix test test/phoenix_kit_hello_world_test.exs  # Run specific test file
mix test --only tag   # Run tests matching a tag
mix format            # Format code (imports Phoenix LiveView rules)
mix credo             # Static analysis / linting
mix dialyzer          # Type checking
mix docs              # Generate documentation
```

## Architecture

This is a **library** (not a standalone Phoenix app) — there is no `config/` directory, no endpoint, no router.

### Key Modules

- **`PhoenixKitHelloWorld`** (`lib/phoenix_kit_hello_world.ex`) — Main module implementing `PhoenixKit.Module` behaviour. Declares required callbacks (`module_key`, `module_name`, `enabled?`, `enable_system`, `disable_system`) and optional ones (`admin_tabs`, `permission_metadata`, `get_config`, etc.).

- **`PhoenixKitHelloWorld.Web.HelloLive`** (`lib/phoenix_kit_hello_world/web/hello_live.ex`) — LiveView page for the admin panel. PhoenixKit wraps it in the admin layout automatically.

### How It Works

1. Parent app adds this as a dependency in `mix.exs`
2. PhoenixKit scans `.beam` files at startup and auto-discovers modules (zero config)
3. `admin_tabs/0` callback registers admin pages; PhoenixKit generates routes at compile time
4. Settings are persisted via `PhoenixKit.Settings` API (DB-backed in parent app)
5. Permissions are declared via `permission_metadata/0` and checked via `Scope.has_module_access?/2`

## Critical Conventions

- **Module key** must be consistent across all callbacks: lowercase with underscores (`"hello_world"`)
- **Tab IDs**: prefixed with `:admin_` (e.g., `:admin_hello_world`)
- **URL paths**: use hyphens, not underscores (`"hello-world"`)
- **Navigation paths**: always use `PhoenixKit.Utils.Routes.path/1`, never relative paths
- **`enabled?/0`**: must rescue errors and return `false` as fallback (DB may not be available)
- **LiveViews use `PhoenixKitWeb` macros** — use `use PhoenixKitWeb, :live_view` (not `use Phoenix.LiveView` directly). This imports PhoenixKit's core components (`<.icon>`, `<.button>`, etc.), Gettext, layout config, and HTML helpers. Use PhoenixKit components for consistent admin UI.
- **JavaScript hooks**: must be inline `<script>` tags; register on `window.PhoenixKitHooks`
- **LiveView assigns** available in admin pages: `@phoenix_kit_current_scope`, `@current_locale`, `@url_path`

## Routing: Single Page vs Multi-Page

**Single admin page** (this template): The `live_view:` field on `admin_tabs/0` auto-generates the route. No route module needed.

**Multiple admin pages**: You MUST use a route module. The `live_view:` field only generates ONE route per tab — it can't handle sub-pages like `/admin/your-module/new` or `/admin/your-module/:id/edit`. Steps:

1. Uncomment the routes in `lib/phoenix_kit_hello_world/routes.ex`
2. Uncomment `route_module/0` in the main module
3. Remove the `live_view:` field from `admin_tabs/0` (the route module takes over)
4. Define ALL admin LiveView routes in both `admin_locale_routes/0` AND `admin_routes/0`

Both functions define the same routes — one for localized paths (`:locale` prefix) and one for non-localized. Every route needs a unique `:as` name (use `_localized` suffix).

**Catch-all public routes** (`/:slug`, `/:group/*path`): MUST go in `public_routes/1`, NOT `generate/1`. Routes in `generate/1` are placed early and will intercept `/admin/*` paths.

## Tailwind CSS Scanning

Modules with templates using Tailwind classes must implement `css_sources/0` returning their OTP app name as an atom list (e.g., `[:my_module]`). PhoenixKit's installer (`mix phoenix_kit.install`) discovers these and adds `@source` directives to the parent's `app.css`. Without this, Tailwind purges the module's CSS classes. Headless modules without UI can skip this.

## PR Reviews

Store review files in `dev_docs/pull_requests/{year}/{pr_number}-{slug}/`.

| File | Status | Purpose |
|------|--------|---------|
| `README.md` | Required | PR summary: goal, what changed, why, how |
| `{AGENT}_REVIEW.md` | Optional | Review feedback, issues found, analysis |
| `FOLLOW_UP.md` | Optional | Post-merge issues, discovered bugs, refactor notes |
| `CONTEXT.md` | Optional | Alternatives considered, trade-offs, deep dive |

Directory naming: `{pr_number}-{short-slug}/` (e.g., `6-routing-scaffold-css-scanning`). Review file naming: `CLAUDE_REVIEW.md`, `GEMINI_REVIEW.md`, etc.

## Two Module Types

- **Full-featured**: Admin tabs, routes, UI, settings (this template)
- **Headless**: Functions/API only, no UI — still gets auto-discovery, toggles, and permissions
