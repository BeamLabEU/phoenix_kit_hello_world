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

## Two Module Types

- **Full-featured**: Admin tabs, routes, UI, settings (this template)
- **Headless**: Functions/API only, no UI — still gets auto-discovery, toggles, and permissions
