# PhoenixKitHelloWorld

A minimal PhoenixKit plugin module. Use this as a template for building your own.

Modules can be **full-featured** (admin pages, settings, routes) or **headless** (just functions and tools, no UI). This module demonstrates the full-featured pattern. See [Headless modules](#headless-modules) for the lightweight alternative.

## Table of Contents

- [What this demonstrates](#what-this-demonstrates)
- [Quick start](#quick-start)
- [Dependency types: development vs production](#dependency-types-development-vs-production)
- [Creating your own module](#creating-your-own-module)
- [Headless modules](#headless-modules)
- [Project structure](#project-structure)
- [Available callbacks](#available-callbacks)
- [Common patterns](#common-patterns)
- [Navigation system](#navigation-system)
- [Admin integration deep dive](#admin-integration-deep-dive)
- [Permissions system](#permissions-system)
- [Component reuse](#component-reuse)
- [JavaScript in modules](#javascript-in-modules)
- [Available PhoenixKit APIs](#available-phoenixkit-apis)
- [Cross-module integration](#cross-module-integration)
- [Database conventions](#database-conventions)
- [Testing](#testing)
- [Verifying your module](#verifying-your-module)
- [Tailwind CSS scanning for modules](#tailwind-css-scanning-for-modules)
- [Troubleshooting](#troubleshooting)
- [Publishing to Hex](#publishing-to-hex)

## What this demonstrates

- Zero-config auto-discovery (just add the dep and `:phoenix_kit` to `extra_applications`)
- Admin sidebar tab with automatic routing
- Enable/disable toggle on the admin Modules page
- Permission key in the roles/permissions matrix
- Live sidebar updates when the module is toggled

## Quick start

For local development, add to your parent app's `mix.exs` using a path dependency:

```elixir
{:phoenix_kit_hello_world, path: "../phoenix_kit_hello_world"}
```

Run `mix deps.get` and start the server. The module appears in:

- **Admin sidebar** (under Modules section) — click to see the Hello World page
- **Admin > Modules** — toggle it on/off
- **Admin > Roles** — grant/revoke access per role

## Dependency types: development vs production

PhoenixKit modules are standard Mix dependencies. How you reference them in the parent app's `mix.exs` depends on your workflow:

### Local development (`path:`)

```elixir
{:my_phoenix_kit_module, path: "../my_phoenix_kit_module"}
```

- **Best for**: active development where you're editing the module and the parent app together
- Changes to the module's source are picked up automatically on recompile — no `--force` needed
- The directory must exist on disk at the given relative path

### Git dependency (`git:`)

```elixir
{:my_phoenix_kit_module, git: "https://github.com/you/my_phoenix_kit_module.git"}
# or pin to a branch/tag/ref:
{:my_phoenix_kit_module, git: "https://github.com/you/my_phoenix_kit_module.git", branch: "main"}
{:my_phoenix_kit_module, git: "https://github.com/you/my_phoenix_kit_module.git", tag: "v1.0.0"}
```

- **Best for**: private modules not published to Hex, or referencing a specific commit/branch
- Lives in `deps/` after `mix deps.get` — the dev reloader does **not** watch deps
- After updating the remote, run `mix deps.update my_phoenix_kit_module`
- To pick up changes: `mix deps.compile my_phoenix_kit_module --force` + restart the server

### Hex package

```elixir
{:my_phoenix_kit_module, "~> 1.0"}
```

- **Best for**: published, versioned modules shared across projects
- Lives in `deps/` — same recompile/restart workflow as git deps
- See [Publishing to Hex](#publishing-to-hex) for how to publish your module

### Why `path:` deps behave differently

With `path:` dependencies, Mix treats the source directory as part of your project — file changes trigger recompilation automatically. With `git:` or Hex deps, the code lives in `deps/` and is compiled once. The Phoenix dev reloader only watches the parent app's own source files, not `deps/`. That's why non-path deps require `mix deps.compile <module> --force` and a server restart to pick up changes.

## Creating your own module

### 1. Copy this project

```bash
cp -r phoenix_kit_hello_world my_phoenix_kit_module
cd my_phoenix_kit_module
```

Rename everything:

- `PhoenixKitHelloWorld` → `MyPhoenixKitModule`
- `phoenix_kit_hello_world` → `my_phoenix_kit_module`
- `hello_world` → `my_module` (the module key)

### 2. Update mix.exs

```elixir
def project do
  [
    app: :my_phoenix_kit_module,
    version: "0.1.0",
    deps: deps()
  ]
end

# Required: :phoenix_kit must be in extra_applications for auto-discovery
def application do
  [
    extra_applications: [:logger, :phoenix_kit]
  ]
end

defp deps do
  [
    {:phoenix_kit, "~> 1.7"},
    {:phoenix_live_view, "~> 1.0"}
  ]
end
```

> **Important:** `:phoenix_kit` must be listed in `extra_applications`. Without it, `PhoenixKit.ModuleDiscovery` won't find your module and routes will return 404.

### 3. Implement the behaviour

The main module (`lib/my_phoenix_kit_module.ex`) needs `use PhoenixKit.Module` and 5 required callbacks:

```elixir
defmodule MyPhoenixKitModule do
  use PhoenixKit.Module

  alias PhoenixKit.Dashboard.Tab
  alias PhoenixKit.Settings

  # --- Required ---

  @impl true
  def module_key, do: "my_module"

  @impl true
  def module_name, do: "My Module"

  @impl true
  def enabled? do
    Settings.get_boolean_setting("my_module_enabled", false)
  rescue
    _ -> false
  end

  @impl true
  def enable_system do
    Settings.update_boolean_setting_with_module("my_module_enabled", true, module_key())
  end

  @impl true
  def disable_system do
    Settings.update_boolean_setting_with_module("my_module_enabled", false, module_key())
  end

  # --- Optional (remove what you don't need) ---

  @impl true
  def permission_metadata do
    %{
      key: module_key(),
      label: "My Module",
      icon: "hero-puzzle-piece",
      description: "Description shown in the permissions matrix"
    }
  end

  @impl true
  def admin_tabs do
    [
      %Tab{
        id: :admin_my_module,
        label: "My Module",
        icon: "hero-puzzle-piece",
        path: "my-module",
        priority: 650,
        level: :admin,
        permission: module_key(),
        match: :prefix,
        group: :admin_modules,
        live_view: {MyPhoenixKitModule.Web.IndexLive, :index}
      }
    ]
  end
end
```

### 4. Create your LiveView

```elixir
defmodule MyPhoenixKitModule.Web.IndexLive do
  use PhoenixKitWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "My Module")}
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 py-6">
      <h1 class="text-2xl font-bold">My Module</h1>
      <p class="text-base-content/70 mt-2">Your content here.</p>
    </div>
    """
  end
end
```

The admin layout (sidebar, header, theme) is applied automatically. You don't need to wrap anything in `LayoutWrapper`.

### 5. Add to parent app

For local development, add a path dependency to the parent app's `mix.exs`:

```elixir
# In parent app's mix.exs (local development)
{:my_phoenix_kit_module, path: "../my_phoenix_kit_module"}
```

Run `mix deps.get`, start the server, and your module appears in the admin panel.

See [Dependency types: development vs production](#dependency-types-development-vs-production) for git and Hex alternatives when deploying.

## Headless modules

Not every module needs admin pages. A **headless module** provides functions, tools, or background workers — no tabs, no routes, no LiveViews. It still gets auto-discovery, enable/disable toggles, and permission integration.

### Minimal example

```elixir
defmodule MyPhoenixKitUtils do
  use PhoenixKit.Module

  alias PhoenixKit.Settings

  # --- Required callbacks (5 total) ---

  @impl true
  def module_key, do: "my_utils"

  @impl true
  def module_name, do: "My Utils"

  @impl true
  def enabled? do
    Settings.get_boolean_setting("my_utils_enabled", false)
  rescue
    _ -> false
  end

  @impl true
  def enable_system do
    Settings.update_boolean_setting_with_module("my_utils_enabled", true, module_key())
  end

  @impl true
  def disable_system do
    Settings.update_boolean_setting_with_module("my_utils_enabled", false, module_key())
  end

  # --- Optional: permission metadata ---
  # Include this if you want the module to appear in the roles/permissions matrix.
  # Omit it if the module is always available to all users.

  @impl true
  def permission_metadata do
    %{
      key: module_key(),
      label: "My Utils",
      icon: "hero-wrench-screwdriver",
      description: "Utility functions for data processing"
    }
  end

  # --- Your public API ---
  # No admin_tabs, settings_tabs, user_dashboard_tabs, or route_module needed.
  # All default to empty/nil automatically.

  def calculate(x, y), do: x + y

  def format_currency(amount, currency \\ "USD") do
    # ...
  end

  def send_notification(user, message) do
    if enabled?() do
      # ...
      :ok
    else
      {:error, :module_disabled}
    end
  end
end
```

That's it. No LiveView, no routes, no templates. The module:

- **Auto-discovered** — just add the dep, appears on Admin > Modules
- **Toggleable** — enable/disable from the admin panel
- **Permission-gated** — custom roles can be granted or denied access via the permissions matrix
- **API-only** — other modules and the parent app call its functions directly

### What you get without any UI callbacks

| Feature | How |
|---|---|
| Shows on Admin > Modules page | Automatic (auto-discovery) |
| Enable/disable toggle | Via `enable_system/0` and `disable_system/0` |
| Permission in roles matrix | Via `permission_metadata/0` (optional) |
| Access check in code | `Scope.has_module_access?(scope, "my_utils")` |
| Background workers | Override `children/0` to return supervisor child specs |
| Config stats on Modules page | Override `get_config/0` to return a stats map |

### When to use headless vs full-featured

| Use headless when... | Use full-featured when... |
|---|---|
| Module provides utility functions | Module needs its own admin page |
| Module runs background jobs | Users need to view/edit data in a UI |
| Module extends other modules' APIs | Module has settings to configure |
| Module is a data pipeline or integration | Module has its own dashboard section |

### Adding a worker to a headless module

```elixir
@impl true
def children do
  if enabled?() do
    [{MyPhoenixKitUtils.SyncWorker, interval: :timer.minutes(5)}]
  else
    []
  end
end
```

### Guarding API calls with enabled?()

For modules that should no-op when disabled:

```elixir
def process(data) do
  if enabled?() do
    do_process(data)
  else
    {:error, :module_disabled}
  end
end
```

For modules where the API is always available but behavior changes:

```elixir
def enrich(record) do
  if enabled?() do
    %{record | ai_summary: generate_summary(record)}
  else
    record  # pass through unchanged
  end
end
```

### Real-world example

PhoenixKit's built-in **Connections** module follows this pattern — 50+ public API functions for follows, connections, and blocks. Zero admin tabs, zero routes. It's toggled on/off from the Modules page and its permission key gates access in the roles matrix, but all interaction happens through function calls from other modules and the parent app.

## Project structure

```
lib/
  my_phoenix_kit_module.ex                   # Main module (behaviour callbacks)
  my_phoenix_kit_module/
    paths.ex                                 # Centralized path helpers (recommended)
    web/
      index_live.ex                          # Main admin page
      detail_live.ex                         # Detail/edit page
      settings_live.ex                       # Settings page (optional)
      components/
        my_scripts.ex                        # JS hook component (if needed)
        shared_panel.ex                      # Shared UI components
test/
  my_phoenix_kit_module_test.exs             # Behaviour compliance tests
mix.exs                                      # Package configuration
```

For modules with database tables, add:

```
lib/
  my_phoenix_kit_module/
    schemas/
      item.ex                               # Ecto schema
    migration.ex                             # Migration coordinator
    migration/postgres/
      v01.ex                                # Initial tables
      v02.ex                                # Schema changes
mix/
  tasks/
    my_phoenix_kit_module.install.ex         # Install task
```

## Available callbacks

| Callback | Required | Default | Description |
|---|---|---|---|
| `module_key/0` | Yes | — | Unique string key |
| `module_name/0` | Yes | — | Display name |
| `enabled?/0` | Yes | — | Whether module is on |
| `enable_system/0` | Yes | — | Turn on |
| `disable_system/0` | Yes | — | Turn off |
| `version/0` | No | `"0.0.0"` | Version string |
| `get_config/0` | No | `%{enabled: enabled?()}` | Config/stats map for Modules page |
| `permission_metadata/0` | No | `nil` | Permission UI metadata |
| `admin_tabs/0` | No | `[]` | Admin sidebar tabs |
| `settings_tabs/0` | No | `[]` | Settings page subtabs |
| `user_dashboard_tabs/0` | No | `[]` | User dashboard tabs |
| `children/0` | No | `[]` | Supervisor child specs |
| `route_module/0` | No | `nil` | Custom route macros |
| `migration_module/0` | No | `nil` | Versioned migration coordinator |
| `css_sources/0` | No | `[]` | OTP app names for Tailwind CSS scanning |

## Common patterns

### Headless module (no UI)

See [Headless modules](#headless-modules) above for the full guide. The short version: don't override `admin_tabs/0`, `settings_tabs/0`, or `user_dashboard_tabs/0` — the defaults return `[]` and no sidebar entries or routes are created.

### Adding a settings subtab

```elixir
@impl true
def settings_tabs do
  [
    %Tab{
      id: :settings_my_module,
      label: "My Module",
      icon: "hero-puzzle-piece",
      path: "my-module",
      level: :settings,
      permission: module_key(),
      live_view: {MyPhoenixKitModule.Web.SettingsLive, :index}
    }
  ]
end
```

### Starting a GenServer with the module

```elixir
@impl true
def children do
  if enabled?() do
    [{MyPhoenixKitModule.Worker, []}]
  else
    []
  end
end
```

### Conditional children with optional dependencies

If your module optionally uses a library that provides a supervisor child (e.g., ChromicPDF for PDF generation), guard the child spec:

```elixir
@impl true
def children do
  if Code.ensure_loaded?(ChromicPDF) do
    [{MyPhoenixKitModule.PdfSupervisor, []}]
  else
    []
  end
end
```

This ensures the module loads even when the optional dependency isn't installed.

### Custom config for the Modules page

```elixir
@impl true
def get_config do
  %{
    enabled: enabled?(),
    items_count: MyPhoenixKitModule.count_items(),
    last_sync: MyPhoenixKitModule.last_sync_at()
  }
end
```

**Performance warning:** `get_config/0` is called on every render of the admin Modules page. Do not perform slow queries here. Use cached values or single aggregate queries.

### Multiple pages and sub-routes

Return multiple tabs from `admin_tabs/0`. Use `:match` and `:parent` to control sidebar behavior:

```elixir
@impl true
def admin_tabs do
  [
    # Main tab (visible in sidebar)
    %Tab{
      id: :admin_my_module,
      label: "My Module",
      icon: "hero-puzzle-piece",
      path: "my-module",
      priority: 650,
      level: :admin,
      permission: module_key(),
      match: :prefix,
      group: :admin_modules,
      live_view: {MyPhoenixKitModule.Web.IndexLive, :index}
    },
    # Detail page (not in sidebar, but keeps parent tab highlighted)
    %Tab{
      id: :admin_my_module_detail,
      path: "my-module/:id",
      level: :admin,
      permission: module_key(),
      visible: false,
      parent: :admin_my_module,
      live_view: {MyPhoenixKitModule.Web.DetailLive, :show}
    }
  ]
end
```

For pages that shouldn't appear in the sidebar, set `visible: false`. The `:parent` field keeps the parent tab highlighted when viewing the child page. Use `:match` with `:prefix` on the parent so `my-module/anything` keeps it active.

## Navigation system

Every path your module generates — in templates, redirects, or LiveView navigation — **must** go through `PhoenixKit.Utils.Routes.path/1`. This handles the configurable URL prefix (e.g., `/phoenix_kit`) and locale prefix (e.g., `/ja`) automatically.

### The Paths module pattern (recommended)

Create a dedicated `Paths` module to centralize all your module's navigation paths. This is the pattern used by production modules like Document Creator, and it ensures you have a single place to update if paths ever change.

```elixir
# lib/my_phoenix_kit_module/paths.ex
defmodule MyPhoenixKitModule.Paths do
  @moduledoc """
  Centralized path helpers for My Module.

  All navigation paths go through `PhoenixKit.Utils.Routes.path/1`, which
  handles the configurable URL prefix and locale prefix automatically.

  Use these helpers in templates and `redirect/2` calls instead of
  hardcoding paths.
  """

  alias PhoenixKit.Utils.Routes

  @base "/admin/my-module"

  # ── Main ──────────────────────────────────────────────────────────
  def index, do: Routes.path(@base)

  # ── Items ─────────────────────────────────────────────────────────
  def item_new, do: Routes.path("#{@base}/items/new")
  def item_edit(uuid), do: Routes.path("#{@base}/items/#{uuid}/edit")
  def item_show(uuid), do: Routes.path("#{@base}/items/#{uuid}")

  # ── Settings ──────────────────────────────────────────────────────
  def settings, do: Routes.path("#{@base}/settings")
end
```

### Using paths in LiveViews and templates

```elixir
# In LiveView mount or event handlers
alias MyPhoenixKitModule.Paths

# Redirect after save
{:noreply, redirect(socket, to: Paths.index())}

# Redirect to edit page after creation
{:noreply, redirect(socket, to: Paths.item_edit(item.uuid))}

# Handle not-found
case get_item(uuid) do
  nil ->
    socket
    |> put_flash(:error, "Item not found")
    |> redirect(to: Paths.index())

  item ->
    assign(socket, item: item)
end
```

```heex
<%!-- In templates --%>
<a href={Paths.item_edit(@item.uuid)} class="btn btn-sm">Edit</a>
<a href={Paths.index()} class="btn btn-ghost btn-sm">Back to list</a>
```

### Tab paths vs template paths — two different systems

| Where | How to specify paths |
|---|---|
| Tab struct `path` field | `"my-module"` (relative — core prepends `/admin/`) |
| Template `href` / `redirect` | `Paths.index()` (via your Paths module wrapping `Routes.path/1`) |
| Email URLs | `Routes.url("/users/confirm/#{token}")` (full URL) |

Tab structs use a relative convention where the core handles the `/admin/` prefix. Template paths and redirects are raw — they need the full path via `Routes.path/1`. The Paths module bridges this gap by centralizing the `/admin/my-module` base path in one `@base` attribute.

### Why relative paths break

**Never use relative paths** in `href` or `redirect(to:)`. The browser resolves them relative to the current URL. When locale segments (e.g., `/ja/`) or a URL prefix are in the path, relative paths resolve incorrectly:

```elixir
# If current URL is /phoenix_kit/ja/admin/my-module
# A relative href="items/new" would resolve to:
#   /phoenix_kit/ja/admin/my-module/items/new  (maybe correct by accident)
# But from /phoenix_kit/ja/admin/my-module/items/123:
#   /phoenix_kit/ja/admin/my-module/items/items/new  (broken!)

# Always use absolute paths via Routes.path/1:
Paths.item_new()  # → /phoenix_kit/ja/admin/my-module/items/new (always correct)
```

## Admin integration deep dive

### How routing works

You do **not** add routes manually. The `live_view` field in your tab structs tells PhoenixKit to generate routes at compile time. For a tab like:

```elixir
%Tab{
  path: "my-module",
  live_view: {MyPhoenixKitModule.Web.IndexLive, :index}
}
```

PhoenixKit generates:

```elixir
live "/admin/my-module", MyPhoenixKitModule.Web.IndexLive, :index
```

inside the admin `live_session` with the admin layout applied. This happens at compile time in `integration.ex`. After adding a new external module, the parent app needs a recompile (`mix deps.compile phoenix_kit --force` or restart the server).

### Admin layout is auto-applied

PhoenixKit's `on_mount` hook detects external plugin LiveViews and automatically applies the admin layout (sidebar, header, theme). **Do not** wrap your templates with `<PhoenixKitWeb.Components.LayoutWrapper.app_layout>` — this causes double sidebars. Just render your inner content directly.

This only applies to admin LiveViews. Public controller templates (rendered via `Phoenix.Controller.render/2`) still need the wrapper if they use the app layout.

### Route module for complex routes

For simple modules, the `live_view` field in `admin_tabs/0` is sufficient — PhoenixKit auto-generates the admin route. For modules with complex routing needs (multiple admin pages, public-facing routes, custom controllers), implement `route_module/0`:

```elixir
@impl PhoenixKit.Module
def route_module, do: MyPhoenixKitModule.Routes
```

Your route module can implement these functions:

| Function | Position in router | Use for |
|---|---|---|
| `admin_locale_routes/0` | Inside admin live_session (localized) | Complex admin LiveView routes |
| `admin_routes/0` | Inside admin live_session (non-localized) | Same, for non-locale-prefixed paths |
| `generate/1` | Early, before localized routes | Non-catch-all public routes |
| `public_routes/1` | **Last**, after all other routes | Catch-all public routes (`/:group/*path`) |

**Route ordering matters.** If your module has catch-all routes like `/:group` or `/:group/*path`, they **must** go in `public_routes/1` — not `generate/1`. Routes in `generate/1` are placed early and will intercept admin paths, breaking the entire admin panel. `public_routes/1` is placed last, after all admin and localized routes, so catch-alls only match when nothing else does.

### Assigns available in admin LiveViews

PhoenixKit's `on_mount` hooks inject these assigns into every admin LiveView:

| Assign | Type | Description |
|---|---|---|
| `@phoenix_kit_current_scope` | `Scope` | The authenticated user's scope (role, permissions) |
| `@current_locale` | `String` | The current locale string (e.g., `"en"`, `"ja"`) |
| `@url_path` | `String` | The current URL path (used for active nav highlighting) |
| `@page_title` | `String` | Set this in `mount/3` — shown in the browser tab |

### Tab struct complete reference

All fields available on `%PhoenixKit.Dashboard.Tab{}`:

| Field | Type | Default | Description |
|---|---|---|---|
| `:id` | atom | *required* | Unique identifier (prefix with `:admin_yourmodule`) |
| `:label` | string | *required* | Display text in sidebar |
| `:icon` | string | `nil` | Heroicon name (e.g., `"hero-puzzle-piece"`) |
| `:path` | string | *required* | Relative slug (`"my-module"`) or absolute (`"/admin/my-module"`) |
| `:priority` | integer | `500` | Sort order (lower = higher in sidebar) |
| `:level` | atom | `:user` | `:admin`, `:settings`, `:user`, or `:all` |
| `:permission` | string | `nil` | Permission key (use `module_key()`) |
| `:group` | atom | `nil` | Sidebar group (`:admin_modules` for module tabs) |
| `:match` | atom/fn | `:prefix` | `:exact`, `:prefix`, `{:regex, ~r/...}`, or `fn path -> bool end` |
| `:live_view` | tuple | `nil` | `{Module, :action}` for auto-routing |
| `:parent` | atom | `nil` | Parent tab ID (for hidden sub-pages or subtabs) |
| `:visible` | bool/fn | `true` | Show in sidebar. `false` hides it. Can be a `fn scope -> bool end` |
| `:badge` | `Badge` | `nil` | Badge indicator (count, dot, status) |
| `:tooltip` | string | `nil` | Hover text |
| `:external` | bool | `false` | Whether this links to an external site |
| `:new_tab` | bool | `false` | Whether to open in a new browser tab |
| `:attention` | atom | `nil` | Animation: `:pulse`, `:bounce`, `:shake`, `:glow` |
| `:metadata` | map | `%{}` | Custom metadata for advanced use cases |
| `:subtab_display` | atom | `:when_active` | When to show subtabs: `:when_active` or `:always` |
| `:subtab_indent` | string | `nil` | Tailwind padding class (e.g., `"pl-6"`) |
| `:subtab_icon_size` | string | `nil` | Icon size class (e.g., `"w-3 h-3"`) |
| `:subtab_text_size` | string | `nil` | Text size class (e.g., `"text-xs"`) |
| `:subtab_animation` | atom | `nil` | `:none`, `:slide`, `:fade`, `:collapse` |
| `:redirect_to_first_subtab` | bool | `false` | Navigate to first subtab when clicking parent |
| `:highlight_with_subtabs` | bool | `false` | Keep parent highlighted when subtab is active |

### Subtabs (visible child tabs)

Subtabs appear indented under their parent in the sidebar. Use them for section-level navigation within your module:

```elixir
@impl true
def admin_tabs do
  [
    # Parent tab with subtab configuration
    %Tab{
      id: :admin_my_module,
      label: "My Module",
      icon: "hero-puzzle-piece",
      path: "my-module",
      priority: 650,
      level: :admin,
      permission: module_key(),
      match: :prefix,
      group: :admin_modules,
      subtab_display: :when_active,        # Show subtabs only when parent is active
      highlight_with_subtabs: false,        # Don't highlight parent when subtab is active
      live_view: {MyPhoenixKitModule.Web.IndexLive, :index}
    },
    # Visible subtab — appears indented in sidebar under parent
    %Tab{
      id: :admin_my_module_reports,
      label: "Reports",
      icon: "hero-chart-bar",
      path: "my-module/reports",
      priority: 651,
      level: :admin,
      permission: module_key(),
      parent: :admin_my_module,
      live_view: {MyPhoenixKitModule.Web.ReportsLive, :index}
    },
    # Another visible subtab
    %Tab{
      id: :admin_my_module_settings,
      label: "Settings",
      icon: "hero-cog-6-tooth",
      path: "my-module/settings",
      priority: 652,
      level: :admin,
      permission: module_key(),
      parent: :admin_my_module,
      live_view: {MyPhoenixKitModule.Web.SettingsLive, :index}
    }
  ]
end
```

### Hidden pages (invisible child tabs)

For pages that should exist as routes but not appear in the sidebar (e.g., edit pages, detail views), set `visible: false`:

```elixir
# Hidden — route exists, but no sidebar entry
%Tab{
  id: :admin_my_module_item_edit,
  path: "my-module/items/:uuid/edit",
  level: :admin,
  permission: module_key(),
  parent: :admin_my_module,           # Keeps parent highlighted
  visible: false,                      # Not shown in sidebar
  live_view: {MyPhoenixKitModule.Web.ItemEditorLive, :edit}
}
```

### Conditional tabs via config flags

Use `Application.compile_env/3` to gate tabs behind configuration:

```elixir
@testing_mode Application.compile_env(:my_phoenix_kit_module, :testing_mode, false)

@impl true
def admin_tabs do
  base_tabs() ++ testing_tabs()
end

defp base_tabs do
  [
    %Tab{id: :admin_my_module, ...}
  ]
end

defp testing_tabs do
  if @testing_mode do
    [
      %Tab{
        id: :admin_my_module_testing,
        label: "Testing",
        icon: "hero-beaker",
        path: "my-module/testing",
        priority: 690,
        level: :admin,
        permission: module_key(),
        parent: :admin_my_module,
        live_view: {MyPhoenixKitModule.Web.TestingLive, :index}
      }
    ]
  else
    []
  end
end
```

Users enable testing tabs in their config:

```elixir
config :my_phoenix_kit_module, :testing_mode, true
```

### Real-world example: Document Creator's 14 tabs

The Document Creator module demonstrates a complex multi-page admin integration:

```elixir
def admin_tabs do
  [
    # Main landing page (visible in sidebar, with subtabs)
    %Tab{id: :admin_document_creator, path: "document-creator",
         subtab_display: :when_active, highlight_with_subtabs: false, ...},

    # Hidden CRUD pages (route exists, no sidebar entry)
    %Tab{id: :admin_document_creator_template_new, path: "document-creator/templates/new",
         visible: false, parent: :admin_document_creator, ...},
    %Tab{id: :admin_document_creator_template_edit, path: "document-creator/templates/:uuid/edit",
         visible: false, parent: :admin_document_creator, ...},
    %Tab{id: :admin_document_creator_document_edit, path: "document-creator/documents/:uuid/edit",
         visible: false, parent: :admin_document_creator, ...},

    # Visible subtabs (appear under parent in sidebar)
    %Tab{id: :admin_document_creator_headers, path: "document-creator/headers",
         parent: :admin_document_creator, ...},
    %Tab{id: :admin_document_creator_footers, path: "document-creator/footers",
         parent: :admin_document_creator, ...},

    # Hidden pages for subtab CRUD
    %Tab{id: :admin_document_creator_header_new, path: "document-creator/headers/new",
         visible: false, parent: :admin_document_creator, ...},
    # ... and so on for header_edit, footer_new, footer_edit

    # Conditional testing tabs (behind config flag)
    # ... only included when :testing_editors config is true
  ]
end
```

Key takeaways from this pattern:
- **One main tab** visible in the sidebar with `subtab_display: :when_active`
- **Subtabs** for major sections (Headers, Footers) — visible, with `parent` pointing to main
- **Hidden tabs** for CRUD pages (new, edit) — `visible: false`, still auto-routed
- **Path parameters** work in tab paths: `"document-creator/templates/:uuid/edit"`
- **All tabs** share the same `permission: module_key()` for consistent access control

### Priority ranges

Priority controls the sort order in the sidebar (lower number = higher position):

| Range | Used by |
|---|---|
| 100-199 | Core admin (Dashboard) |
| 200-299 | Users section |
| 300-399 | Media section |
| 400-599 | Reserved for future core sections |
| **600-899** | **Module tabs — use this range** |
| 900-999 | System section (Settings, Modules) |

Pick a priority in the **600-899** range for your module. Avoid exact conflicts with other modules by spacing them out (e.g., 650, 700, 750).

### Sidebar groups

| Group | Description |
|---|---|
| `:admin_main` | Top-level admin sections |
| `:admin_modules` | Feature modules (use this for your tabs) |
| `:admin_system` | Settings, Modules page, system tools |

### Icons

PhoenixKit uses [Heroicons v2](https://heroicons.com). Reference them with the `hero-` prefix:

```
hero-puzzle-piece       hero-chart-bar        hero-shopping-cart
hero-document-text      hero-cog-6-tooth      hero-bolt
hero-bell               hero-envelope         hero-globe-alt
hero-cube               hero-rocket-launch    hero-sparkles
```

Browse the full set at [heroicons.com](https://heroicons.com). Use outline style (the default) — just prefix with `hero-` and convert to kebab-case.

## Permissions system

### How permissions work

PhoenixKit uses a role-based permission system. Every module can register a permission key via `permission_metadata/0`.

| Role type | Default access | Can be changed? |
|---|---|---|
| **Owner** | Full access to everything | No — hardcoded, cannot be restricted |
| **Admin** | All permission keys by default | Yes — per key via Admin > Roles |
| **Custom roles** | No permissions initially | Yes — must be granted explicitly |

### Registering your permission

```elixir
@impl true
def permission_metadata do
  %{
    key: module_key(),          # MUST match module_key/0 exactly
    label: "My Module",         # Shown in the permissions matrix UI
    icon: "hero-puzzle-piece",  # Icon in the matrix
    description: "Access to the My Module admin pages"
  }
end
```

If you return `nil` (the default), the module has no dedicated permission key. Admins and owners can still see it, but custom roles never will.

### Checking permissions in code

The scope is available in admin LiveViews via `@phoenix_kit_current_scope`:

```elixir
alias PhoenixKit.Users.Auth.Scope

# In a LiveView
scope = socket.assigns.phoenix_kit_current_scope

Scope.has_module_access?(scope, "my_module")   # does user have this permission?
Scope.admin?(scope)                             # is user Owner or Admin?
Scope.system_role?(scope)                       # Owner, Admin, or User (not custom)?
Scope.owner?(scope)                             # is user Owner?
Scope.user_roles(scope)                         # list of role names
```

### Access guards on admin tabs

PhoenixKit's `on_mount` hook automatically checks the `:permission` field on each tab before rendering the LiveView. If the user's role doesn't have the permission, they get a 302 redirect. You don't need to add manual guards — just set the `:permission` field correctly.

For fine-grained checks within a page (e.g., showing/hiding a delete button):

```elixir
def render(assigns) do
  ~H"""
  <div>
    <h1>Items</h1>
    <button :if={Scope.admin?(@phoenix_kit_current_scope)} phx-click="delete">
      Delete
    </button>
  </div>
  """
end
```

### Permission validation at startup

The ModuleRegistry validates at boot:
- `permission_metadata().key` must match `module_key/0` — warns if mismatched
- Tabs with no `:permission` field — warns if the module has `permission_metadata`
- Duplicate tab IDs across modules — warns

These are warnings, not crashes, so a misconfigured module won't take down the app. But the symptom is that toggling the module works in the UI but permission checks use the wrong key.

## PhoenixKit components

Use `use PhoenixKitWeb, :live_view` in your LiveViews (not `use Phoenix.LiveView` directly). This imports PhoenixKit's core components, Gettext, layout config, and HTML helpers — giving you a consistent admin UI out of the box.

Available components include:

- `<.icon name="hero-*" />` — Heroicons
- `<.button>`, `<.simple_form>`, `<.input>`, `<.select>`, `<.textarea>`, `<.checkbox>`
- `<.flash>`, `<.header>`, `<.badge>`, `<.stat_card>`
- `<.form_field_label>`, `<.form_field_error>`

```elixir
defmodule MyModule.Web.DashboardLive do
  use PhoenixKitWeb, :live_view  # imports all PhoenixKit components

  def render(assigns) do
    ~H\"""
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title">
          <.icon name="hero-chart-bar" class="w-5 h-5" /> Dashboard
        </h2>
        <p class="text-base-content/70">Your module content here.</p>
      </div>
    </div>
    \"""
  end
end
```

For controllers, use `use PhoenixKitWeb, :controller`.

## Component reuse

As your module grows, extract shared UI into reusable function components. This keeps your LiveViews focused on business logic while shared presentation lives in dedicated component modules.

> **Important:** If your components use Tailwind CSS classes, implement `css_sources/0` in your main module so the parent app's Tailwind build can scan your templates. See [Tailwind CSS scanning for modules](#tailwind-css-scanning-for-modules) for details.

### Extracting a shared component

Create a component module under `web/components/`:

```elixir
# lib/my_phoenix_kit_module/web/components/item_card.ex
defmodule MyPhoenixKitModule.Web.Components.ItemCard do
  use Phoenix.Component

  attr :item, :map, required: true
  attr :on_edit, :string, default: nil
  attr :on_delete, :string, default: nil

  def item_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h3 class="card-title">{@item.name}</h3>
        <p class="text-base-content/70 text-sm">{@item.description}</p>
        <div class="card-actions justify-end">
          <button :if={@on_edit} class="btn btn-sm btn-ghost" phx-click={@on_edit} phx-value-uuid={@item.uuid}>
            Edit
          </button>
          <button :if={@on_delete} class="btn btn-sm btn-error btn-outline" phx-click={@on_delete} phx-value-uuid={@item.uuid}>
            Delete
          </button>
        </div>
      </div>
    </div>
    """
  end
end
```

### Using components in LiveViews

Import the component module and call the function:

```elixir
defmodule MyPhoenixKitModule.Web.IndexLive do
  use PhoenixKitWeb, :live_view

  import MyPhoenixKitModule.Web.Components.ItemCard

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 p-4">
      <.item_card :for={item <- @items} item={item} on_edit="edit_item" on_delete="delete_item" />
    </div>
    """
  end
end
```

The same component can be used across multiple LiveViews in your module:

```elixir
# In another LiveView
defmodule MyPhoenixKitModule.Web.SearchResultsLive do
  use PhoenixKitWeb, :live_view

  import MyPhoenixKitModule.Web.Components.ItemCard

  def render(assigns) do
    ~H"""
    <div class="space-y-4 p-4">
      <.item_card :for={item <- @results} item={item} on_edit="view_item" />
    </div>
    """
  end
end
```

### Shared editor panel pattern

For modules with multiple editor pages (e.g., editing different entity types with the same UI), extract the editor shell as a component:

```elixir
# lib/my_phoenix_kit_module/web/components/editor_panel.ex
defmodule MyPhoenixKitModule.Web.Components.EditorPanel do
  use Phoenix.Component

  attr :id, :string, required: true, doc: "Unique prefix for all element IDs"
  attr :hook, :string, required: true, doc: "Phoenix hook name"
  attr :save_event, :string, required: true, doc: "LiveView event name for saving"
  attr :show_toolbar, :boolean, default: true

  def editor_panel(assigns) do
    ~H"""
    <div class="flex-1">
      <div
        id={"#{@id}-wrapper"}
        phx-hook={@hook}
        phx-update="ignore"
        data-editor-id={"#{@id}-editor"}
        data-save-event={@save_event}
      >
        <div :if={@show_toolbar} id={"#{@id}-toolbar"} class="border-b border-base-300 p-2">
          <%!-- Toolbar rendered by JS hook --%>
        </div>
        <div id={"#{@id}-editor"} style="min-height: 500px;"></div>
      </div>
    </div>
    """
  end
end
```

Then each editor LiveView imports and uses it with different parameters:

```elixir
# Template editor
import MyPhoenixKitModule.Web.Components.EditorPanel
<.editor_panel id="template" hook="TemplateEditor" save_event="save_template" />

# Document editor
<.editor_panel id="document" hook="DocumentEditor" save_event="save_document" show_toolbar={false} />
```

### Multi-step modal component

For complex workflows, extract modal components:

```elixir
# lib/my_phoenix_kit_module/web/components/create_modal.ex
defmodule MyPhoenixKitModule.Web.Components.CreateModal do
  use Phoenix.Component

  attr :open, :boolean, required: true
  attr :step, :string, default: "choose"
  attr :templates, :list, default: []
  attr :creating, :boolean, default: false

  def modal(assigns) do
    ~H"""
    <div :if={@open} class="modal modal-open">
      <div class="modal-box max-w-lg">
        <%= case @step do %>
          <% "choose" -> %>
            <h3 class="text-lg font-bold">Choose Type</h3>
            <%!-- Step 1 content --%>
          <% "configure" -> %>
            <h3 class="text-lg font-bold">Configure</h3>
            <%!-- Step 2 content --%>
        <% end %>
      </div>
      <div class="modal-backdrop" phx-click="modal_close"></div>
    </div>
    """
  end
end
```

### Component design guidelines

1. **Use `attr` declarations** — they provide documentation, validation, and compile-time warnings
2. **Use daisyUI semantic classes** — `bg-base-100`, `text-base-content`, `btn btn-primary` (never hardcode colors)
3. **Use `text-base-content/70`** for muted text, not `text-gray-500`
4. **Prefix element IDs** with the component's `@id` attr to avoid collisions when multiple instances are on the same page
5. **Pass event names as attrs** (e.g., `on_edit="edit_item"`) rather than hardcoding them — this makes the component reusable across LiveViews with different event handlers

## JavaScript in modules

External modules **cannot inject files into the parent app's asset pipeline** (`app.js`). All JavaScript must be delivered inside your LiveView templates.

### Simple inline hooks

For small amounts of JS, use inline `<script>` tags. PhoenixKit's `app.js` collects hooks from `window.PhoenixKitHooks` when creating the LiveSocket.

```elixir
# lib/my_module/web/components/my_scripts.ex
defmodule MyModule.Web.Components.MyScripts do
  use Phoenix.Component

  def my_scripts(assigns) do
    ~H"""
    <script>
      window.PhoenixKitHooks = window.PhoenixKitHooks || {};
      window.PhoenixKitHooks.MyHook = {
        mounted() {
          // Your hook logic here
          this.el.addEventListener("click", () => {
            this.pushEvent("clicked", {id: this.el.dataset.id});
          });
        },
        destroyed() {
          // Cleanup when element is removed
        }
      };
    </script>
    """
  end
end
```

Then in your LiveView template:

```heex
<.my_scripts />
<div id="my-widget" phx-hook="MyHook" phx-update="ignore" data-id={@item.id}>
  ...
</div>
```

### Key rules for inline JS

- Register hooks on `window.PhoenixKitHooks` — PhoenixKit spreads this into the LiveSocket
- Pages using hooks must be entered via **full page load** (`redirect/2` or plain `<a href>`), not `navigate/2`, so the inline script executes
- Never assume access to `node_modules`, `esbuild`, or the parent app's JS build

### Base64-encoded JS delivery (for large scripts)

Large inline `<script>` tags inside LiveView renders **do not work reliably**. LiveView's morphdom DOM patching can corrupt script boundaries, and HTML-like strings inside JS confuse the rendering pipeline. Browser extensions (e.g., MetaMask's hardened JS) can also block `eval()` from inline scripts.

The solution is **compile-time base64 encoding**. The JS source file is read and encoded at compile time, then emitted as a `data-` attribute on a hidden `<div>`. A tiny bootstrapper decodes and executes it via `document.createElement("script")`:

```elixir
# lib/my_module/web/components/my_scripts.ex
defmodule MyModule.Web.Components.MyScripts do
  @moduledoc """
  JavaScript component that delivers hooks via base64-encoded compile-time embedding.

  The JS source lives in `my_hooks.js` alongside this module. After editing it,
  recompile from the parent app:

      mix deps.compile my_phoenix_kit_module --force

  Then restart the Phoenix server.
  """
  use Phoenix.Component

  # Read and encode JS at compile time
  @external_resource Path.join(__DIR__, "my_hooks.js")
  @js_source __DIR__ |> Path.join("my_hooks.js") |> File.read!()
  @js_base64 Base.encode64(@js_source)
  @js_version to_string(:erlang.phash2(@js_source))

  def my_scripts(assigns) do
    assigns =
      assigns
      |> assign(:js_base64, @js_base64)
      |> assign(:js_version, @js_version)

    ~H"""
    <div id="my-module-js-payload" hidden data-c={@js_base64} data-v={@js_version}></div>
    <script>
    (function(){
      var p=document.getElementById("my-module-js-payload");
      if(!p) return;
      var v=p.dataset.v;
      if(window.__MyModuleVersion===v) return;
      var old=document.getElementById("my-module-js-script");
      if(old) old.remove();
      window.__MyModuleVersion=v;
      var s=document.createElement("script");
      s.id="my-module-js-script";
      s.textContent=atob(p.dataset.c);
      document.head.appendChild(s);
    })();
    </script>
    """
  end
end
```

And the JS source file alongside it:

```javascript
// lib/my_module/web/components/my_hooks.js
// This file is read at compile time by my_scripts.ex, base64-encoded,
// and embedded in the rendered HTML. After editing, run:
//   mix deps.compile my_phoenix_kit_module --force
(function() {
  "use strict";

  if (window.__MyModuleInitialized) return;
  window.__MyModuleInitialized = true;

  window.PhoenixKitHooks = window.PhoenixKitHooks || {};

  window.PhoenixKitHooks.MyEditor = {
    mounted() {
      // Your hook logic here
      this.handleEvent("load-data", (data) => {
        // Handle server-pushed events
      });
    },
    destroyed() {
      // Cleanup
    }
  };
})();
```

**Why this works better than inline scripts:**

1. **No morphdom corruption** — base64 contains no HTML-significant characters (`<`, `>`, `</script>`)
2. **No HTML confusion** — JS code containing HTML strings (e.g., `'<h1>Title</h1>'`) won't break
3. **Browser extension safe** — `document.createElement("script")` bypasses extension blocks on `eval()`
4. **Version tracking** — the content hash (`@js_version`) ensures re-execution on LiveView navigations when JS changes
5. **Self-contained** — no files need to be copied to the parent app
6. **`@external_resource`** — tells Mix to track the JS file for recompilation

**Editing workflow:**

1. Edit `my_hooks.js`
2. From parent app: `mix deps.compile my_phoenix_kit_module --force`
3. Restart the Phoenix server (dev reloader only watches the app's own modules, not deps)

### Loading vendor libraries from CDN

For large third-party libraries (e.g., GrapesJS, CodeMirror), load them from CDN dynamically:

```javascript
// In your hooks JS file
var _libLoaded = false;
var _libCallbacks = [];

function ensureLibrary(callback) {
  if (typeof MyLibrary !== "undefined") {
    callback();
    return;
  }
  _libCallbacks.push(callback);
  if (_libLoaded) return;
  _libLoaded = true;

  // Load CSS
  var link = document.createElement("link");
  link.rel = "stylesheet";
  link.href = "https://cdn.jsdelivr.net/npm/my-library@1.0/dist/style.min.css";
  document.head.appendChild(link);

  // Load JS
  var script = document.createElement("script");
  script.src = "https://cdn.jsdelivr.net/npm/my-library@1.0/dist/lib.min.js";
  script.onload = function() {
    var cbs = _libCallbacks.slice();
    _libCallbacks = [];
    cbs.forEach(function(cb) { cb(); });
  };
  document.head.appendChild(script);
}

// In your hook:
window.PhoenixKitHooks.MyEditor = {
  mounted() {
    ensureLibrary(() => {
      // Library is now available
      this.editor = new MyLibrary.Editor(this.el, { /* options */ });
    });
  }
};
```

### Vendor JS files (bundled)

If you prefer to bundle the library instead of using a CDN:

1. Bundle the minified file in `priv/static/vendor/your_lib/`
2. Your install task copies it to the parent app's `priv/static/vendor/`
3. Load it via `<script src={~p"/vendor/your_lib/lib.min.js"}>` in your template

### LiveView JS interop

Communicate between your JS hooks and LiveView:

```javascript
// JS → Elixir (push events to the server)
this.pushEvent("save_content", {html: editor.getHtml(), css: editor.getCss()});

// Elixir → JS (handle server-pushed events)
this.handleEvent("load-content", ({html, css}) => {
  editor.setContent(html);
});

// Elixir → JS (push from server in handle_event)
// In your LiveView:
{:noreply, push_event(socket, "load-content", %{html: content.html, css: content.css})}
```

## Available PhoenixKit APIs

Your module has access to the full PhoenixKit API through the dependency. Here's what's available and where to look. Run `mix docs` in phoenix_kit for the full API reference.

### Settings (`PhoenixKit.Settings`)

Read and write persistent key/value settings stored in the database.

```elixir
Settings.get_setting("my_key")                          # returns string or nil
Settings.get_boolean_setting("my_key", false)            # returns boolean with default
Settings.get_json_setting("my_key")                      # returns decoded map/list
Settings.update_setting("my_key", "value")               # write a string
Settings.update_boolean_setting_with_module("my_key", true, module_key())  # write boolean tied to module
```

### Permissions & Scope (`PhoenixKit.Users.Permissions`, `PhoenixKit.Users.Auth.Scope`)

Check what the current user can access. The scope is available in LiveViews via `@phoenix_kit_current_scope`.

```elixir
# In a LiveView
scope = socket.assigns.phoenix_kit_current_scope

Scope.has_module_access?(scope, "my_module")   # does user have this permission?
Scope.admin?(scope)                             # is user Owner or Admin?
Scope.system_role?(scope)                       # Owner, Admin, or User (not custom)?
Scope.owner?(scope)                             # is user Owner?
```

### Tab struct (`PhoenixKit.Dashboard.Tab`)

See [Tab struct complete reference](#tab-struct-complete-reference) for all fields.

### Routes & Navigation (`PhoenixKit.Utils.Routes`)

See [Navigation system](#navigation-system) for the full guide.

```elixir
alias PhoenixKit.Utils.Routes

Routes.path("/admin/my-module")       # → /phoenix_kit/ja/admin/my-module
Routes.url("/users/confirm/#{token}") # full URL for emails
```

### Date formatting (`PhoenixKit.Utils.Date`)

```elixir
alias PhoenixKit.Utils.Date, as: UtilsDate

UtilsDate.utc_now()                              # truncated to seconds (safe for DB writes)
UtilsDate.format_datetime_with_user_format(dt)   # uses admin settings for format
```

### UI guidelines

- Use **daisyUI semantic classes** — `bg-base-100`, `text-base-content`, `btn btn-primary`, `badge badge-success`
- Never hardcode colors like `bg-white`, `text-gray-500`, etc. — these break with themes
- Use `text-base-content/70` for muted text
- The admin layout is applied automatically for plugin LiveViews — just render your content
- Use `card bg-base-100 shadow-xl` for card containers
- Use `badge badge-sm` for status indicators

## Cross-module integration

Your module can depend on other PhoenixKit modules or external plugins. There are two patterns depending on whether the dependency is required or optional.

### Required dependency

If your module won't work without another module, add it to `mix.exs`. Mix enforces it at install time — if the user doesn't have it, `mix deps.get` fails with a clear error.

```elixir
# mix.exs
defp deps do
  [
    {:phoenix_kit, "~> 1.7"},
    {:phoenix_kit_billing, "~> 1.0"}  # hard requirement
  ]
end
```

Then use it directly in your code — it's always available:

```elixir
alias PhoenixKit.Modules.Billing

def get_customer_for_user(user) do
  if Billing.enabled?() do
    Billing.get_customer(user)
  else
    nil  # billing code is installed but the feature is toggled off
  end
end
```

### Optional dependency

If your module has bonus features when another module is present but works fine without it, use `Code.ensure_loaded?/1` at runtime:

```elixir
def ai_features_available? do
  Code.ensure_loaded?(PhoenixKit.Modules.AI) and
    PhoenixKit.Modules.AI.enabled?()
end

def maybe_generate_summary(content) do
  if ai_features_available?() do
    PhoenixKit.Modules.AI.generate(content, "Summarize this")
  else
    {:ok, nil}
  end
end
```

This is how the Publishing module integrates with AI — translation features appear only when the AI module is installed and enabled, but publishing works fine without it.

### Pattern summary

| Scenario | How | What happens if missing |
|---|---|---|
| **Required** | Add to `mix.exs` deps | `mix deps.get` fails |
| **Optional, installed** | `Code.ensure_loaded?/1` + `enabled?()` | Feature hidden, no errors |
| **Feature flag** | `Settings.get_boolean_setting/2` | Feature toggled off at runtime |

## Database conventions

If your module needs database tables, follow these conventions to avoid collisions with other modules and phoenix_kit internals.

### Table naming

Prefix all tables with `phoenix_kit_` followed by your module key:

```
phoenix_kit_my_module_items
phoenix_kit_my_module_categories
```

Never use generic names like `items` or `posts` — another module or the parent app might use them.

### Versioned migrations

Use the **versioned migration** system for database tables. This lets users auto-upgrade their database schema when they update your dep — no manual migration files needed.

#### How it works

1. Your module implements `migration_module/0` returning a coordinator module
2. The coordinator tracks version numbers via SQL comments on a table
3. Each version is an immutable module (V01, V02, etc.) that creates or alters tables
4. `mix phoenix_kit.update` auto-detects all module migrations and runs them

#### Setting up versioned migrations

**1. Create version modules** — each one is immutable once shipped:

```elixir
# lib/my_module/migration/postgres/v01.ex
defmodule MyModule.Migration.Postgres.V01 do
  use Ecto.Migration

  def up(%{prefix: prefix} = _opts) do
    create_if_not_exists table(:phoenix_kit_my_module_items,
                            primary_key: false,
                            prefix: prefix) do
      add :uuid, :uuid, primary_key: true, default: fragment("uuid_generate_v7()")
      add :name, :string, null: false
      add :user_uuid, references(:phoenix_kit_users, column: :uuid, type: :uuid),
        null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:phoenix_kit_my_module_items, [:user_uuid], prefix: prefix)
  end

  def down(%{prefix: prefix} = _opts) do
    drop_if_exists table(:phoenix_kit_my_module_items, prefix: prefix)
  end
end
```

**2. Create a migration coordinator** — manages version detection and sequencing:

```elixir
# lib/my_module/migration.ex
defmodule MyModule.Migration do
  @moduledoc """
  Versioned migrations for My Module.

  ## Usage

  Create a migration in your parent app:

      defmodule MyApp.Repo.Migrations.AddMyModuleTables do
        use Ecto.Migration

        def up, do: MyModule.Migration.up()
        def down, do: MyModule.Migration.down()
      end

  Or use `mix phoenix_kit.update` which handles all PhoenixKit modules automatically.
  """

  use Ecto.Migration

  @initial_version 1
  @current_version 1
  @default_prefix "public"
  @version_table "phoenix_kit_my_module_items"  # table used for version tracking

  def current_version, do: @current_version

  def up(opts \\ []) do
    opts = with_defaults(opts, @current_version)
    initial = migrated_version(opts)

    cond do
      initial == 0 ->
        change(@initial_version..opts.version, :up, opts)

      initial < opts.version ->
        change((initial + 1)..opts.version, :up, opts)

      true ->
        :ok
    end
  end

  def down(opts \\ []) do
    opts =
      opts
      |> Enum.into(%{prefix: @default_prefix})
      |> Map.put_new(:quoted_prefix, inspect(@default_prefix))
      |> Map.put_new(:escaped_prefix, @default_prefix)

    current = migrated_version(opts)
    target = Map.get(opts, :version, 0)

    if current > target do
      change(current..(target + 1)//-1, :down, opts)
    end
  end

  def migrated_version(opts \\ []) do
    opts = with_defaults(opts, @initial_version)
    escaped_prefix = Map.fetch!(opts, :escaped_prefix)

    table_exists_query = """
    SELECT EXISTS (
      SELECT FROM information_schema.tables
      WHERE table_name = '#{@version_table}'
      AND table_schema = '#{escaped_prefix}'
    )
    """

    case repo().query(table_exists_query, [], log: false) do
      {:ok, %{rows: [[true]]}} ->
        version_query = """
        SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
        FROM pg_class
        LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_class.relname = '#{@version_table}'
        AND pg_namespace.nspname = '#{escaped_prefix}'
        """

        case repo().query(version_query, [], log: false) do
          {:ok, %{rows: [[version]]}} when is_binary(version) ->
            String.to_integer(version)

          _ -> 1
        end

      _ -> 0
    end
  end

  @doc """
  Runtime-safe version of `migrated_version/1`.

  Uses PhoenixKit's configured repo instead of the Ecto.Migration `repo()` helper,
  so it can be called from Mix tasks and other non-migration contexts.
  """
  def migrated_version_runtime(opts \\ []) do
    opts = with_defaults(opts, @initial_version)
    escaped_prefix = Map.fetch!(opts, :escaped_prefix)

    repo = PhoenixKit.Config.get_repo()

    unless repo do
      raise "Cannot detect repo — ensure PhoenixKit is configured"
    end

    table_exists_query = """
    SELECT EXISTS (
      SELECT FROM information_schema.tables
      WHERE table_name = '#{@version_table}'
      AND table_schema = '#{escaped_prefix}'
    )
    """

    case repo.query(table_exists_query, [], log: false) do
      {:ok, %{rows: [[true]]}} ->
        version_query = """
        SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
        FROM pg_class
        LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_class.relname = '#{@version_table}'
        AND pg_namespace.nspname = '#{escaped_prefix}'
        """

        case repo.query(version_query, [], log: false) do
          {:ok, %{rows: [[version]]}} when is_binary(version) ->
            String.to_integer(version)

          _ -> 1
        end

      _ -> 0
    end
  rescue
    _ -> 0
  end

  # ── Internal ──────────────────────────────────────────────────────

  defp change(range, direction, opts) do
    Enum.each(range, fn index ->
      pad = String.pad_leading(to_string(index), 2, "0")

      [MyModule.Migration.Postgres, "V#{pad}"]
      |> Module.concat()
      |> apply(direction, [opts])
    end)

    case direction do
      :up -> record_version(opts, Enum.max(range))
      :down -> record_version(opts, max(Enum.min(range) - 1, 0))
    end
  end

  defp record_version(_opts, 0), do: :ok

  defp record_version(%{prefix: prefix}, version) do
    execute("COMMENT ON TABLE #{prefix}.#{@version_table} IS '#{version}'")
  end

  defp with_defaults(opts, version) do
    opts = Enum.into(opts, %{prefix: @default_prefix, version: version})

    opts
    |> Map.put(:quoted_prefix, inspect(opts.prefix))
    |> Map.put(:escaped_prefix, String.replace(opts.prefix, "'", "\\'"))
  end
end
```

**3. Return the coordinator from your module:**

```elixir
@impl PhoenixKit.Module
def migration_module, do: MyModule.Migration
```

**4. Ship an install task** for first-time setup:

```elixir
# lib/mix/tasks/my_phoenix_kit_module.install.ex
defmodule Mix.Tasks.MyPhoenixKitModule.Install do
  @moduledoc """
  Installs My Module into the parent application.

      mix my_phoenix_kit_module.install

  Creates a database migration for the module's tables.
  """
  use Mix.Task

  @shortdoc "Installs My Module (creates migration)"

  @impl Mix.Task
  def run(_args) do
    app_name = Mix.Project.config()[:app]
    app_module = app_name |> to_string() |> Macro.camelize()
    migrations_dir = Path.join(["priv", "repo", "migrations"])
    File.mkdir_p!(migrations_dir)

    existing =
      migrations_dir
      |> File.ls!()
      |> Enum.find(&String.contains?(&1, "add_my_module_tables"))

    if existing do
      Mix.shell().info("Migration already exists: #{existing}")
    else
      timestamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%d%H%M%S")
      filename = "#{timestamp}_add_my_module_tables.exs"
      path = Path.join(migrations_dir, filename)

      content = """
      defmodule #{app_module}.Repo.Migrations.AddMyModuleTables do
        use Ecto.Migration

        def up, do: MyModule.Migration.up()
        def down, do: MyModule.Migration.down()
      end
      """

      File.write!(path, content)
      Mix.shell().info("Created migration: #{path}")
    end

    Mix.shell().info("""
    \nInstallation complete!
    - Run `mix ecto.migrate` to create the tables.
    """)
  end
end
```

#### How upgrades work

When a user updates your dep and runs `mix phoenix_kit.update`:

1. PhoenixKit discovers your module via beam scanning
2. Calls `migration_module/0` to find the coordinator
3. Compares `migrated_version_runtime(prefix: prefix)` with `current_version()`
4. If behind, generates a migration file and runs `mix ecto.migrate`

Fresh installs run V01 → V02 → ... sequentially. Upgrades only run the versions after the current DB version.

#### Adding a V02 migration

When you need to change the schema, **never edit V01**. Create a V02:

```elixir
# lib/my_module/migration/postgres/v02.ex
defmodule MyModule.Migration.Postgres.V02 do
  use Ecto.Migration

  def up(%{prefix: prefix} = _opts) do
    # Add new column
    alter table(:phoenix_kit_my_module_items, prefix: prefix) do
      add_if_not_exists :status, :string, default: "active", size: 20
      add_if_not_exists :metadata, :map, default: %{}
    end

    # Add index
    create_if_not_exists index(:phoenix_kit_my_module_items, [:status], prefix: prefix)
  end

  def down(%{prefix: prefix} = _opts) do
    alter table(:phoenix_kit_my_module_items, prefix: prefix) do
      remove_if_exists :metadata, :map
      remove_if_exists :status, :string
    end
  end
end
```

Then update `@current_version` in the coordinator:

```elixir
@current_version 2  # was 1
```

#### Key rules

- **Version modules are immutable** — never edit a shipped V01. Add a V02 instead.
- **V01 creates the original schema** — even if you later change it. V02 ALTERs it.
- **Use `create_if_not_exists`** and `add_if_not_exists` for idempotency
- **Track version via SQL comment** — `COMMENT ON TABLE {table} IS '{version}'`

### Schemas

```elixir
# In your schema
defmodule MyModule.Schemas.Item do
  use Ecto.Schema
  import Ecto.Changeset

  alias PhoenixKit.Schemas.UUIDv7

  @primary_key {:uuid, UUIDv7, autogenerate: true}

  schema "phoenix_kit_my_module_items" do
    field :name, :string
    field :status, :string, default: "active"

    belongs_to :user, PhoenixKit.Users.Auth.User,
      foreign_key: :user_uuid, references: :uuid, type: UUIDv7

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :status, :user_uuid])
    |> validate_required([:name])
    |> validate_inclusion(:status, ~w(active archived))
  end
end
```

### Foreign keys to phoenix_kit tables

These tables are part of the public schema contract and safe to reference:

| Table | Primary key | Notes |
|---|---|---|
| `phoenix_kit_users` | `uuid` (UUIDv7) | User accounts |
| `phoenix_kit_user_roles` | `uuid` (UUIDv7) | Role definitions |
| `phoenix_kit_settings` | `uuid` (UUIDv7) | Key/value settings |

Always reference the `uuid` column, not `id` (integer IDs are deprecated).

## Testing

Run tests with:

```bash
mix test
```

### Test levels

PhoenixKit modules have two distinct test levels:

- **Unit tests** — no database, test schemas/changesets/pure functions (`use ExUnit.Case, async: true`)
- **Integration tests** — need PostgreSQL, test context modules and data flow (`use MyModule.DataCase`)

Unit tests always run. Integration tests are automatically excluded when the database is unavailable.

### Unit tests (no database needed)

These verify your module implements the `PhoenixKit.Module` behaviour correctly. They work without any infrastructure:

```elixir
defmodule MyModuleTest do
  use ExUnit.Case, async: true

  # Behaviour compliance
  test "implements PhoenixKit.Module" do
    behaviours =
      MyModule.__info__(:attributes)
      |> Keyword.get_values(:behaviour)
      |> List.flatten()

    assert PhoenixKit.Module in behaviours
  end

  test "has @phoenix_kit_module attribute for auto-discovery" do
    attrs = MyModule.__info__(:attributes)
    assert Keyword.get(attrs, :phoenix_kit_module) == [true]
  end

  # Required callbacks
  test "module_key/0 returns expected key" do
    assert MyModule.module_key() == "my_module"
  end

  test "enabled?/0 returns false when DB unavailable" do
    # Will rescue since no DB is running in unit tests
    refute MyModule.enabled?()
  end

  # Permission metadata
  test "permission key matches module_key" do
    assert MyModule.permission_metadata().key == MyModule.module_key()
  end

  test "icon uses hero- prefix" do
    assert String.starts_with?(MyModule.permission_metadata().icon, "hero-")
  end

  # Tab conventions
  test "tab IDs are namespaced" do
    for tab <- MyModule.admin_tabs() do
      assert tab.id |> to_string() |> String.starts_with?("admin_my_module")
    end
  end

  test "tab paths use hyphens not underscores" do
    for tab <- MyModule.admin_tabs() do
      refute String.contains?(tab.path, "_"),
        "Tab path #{tab.path} contains underscores — use hyphens"
    end
  end

  test "all tabs have permission matching module_key" do
    for tab <- MyModule.admin_tabs() do
      assert tab.permission == MyModule.module_key()
    end
  end

  test "main tab has live_view for route generation" do
    [tab | _] = MyModule.admin_tabs()
    assert {_module, _action} = tab.live_view
  end

  test "all subtabs reference parent" do
    [main | subtabs] = MyModule.admin_tabs()
    for tab <- subtabs do
      assert tab.parent == main.id
    end
  end
end
```

For modules with Ecto schemas, you can test changesets without a database:

```elixir
test "changeset validates required fields" do
  changeset = MySchema.changeset(%MySchema{}, %{})
  refute changeset.valid?
  assert "can't be blank" in errors_on(changeset).name
end
```

### Integration test infrastructure

If your module uses the database, you need test infrastructure. Here's the complete setup:

#### 1. Update `mix.exs`

```elixir
def project do
  [
    # ... existing config ...
    elixirc_paths: elixirc_paths(Mix.env()),
  ]
end

defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]

defp aliases do
  [
    # ... existing aliases ...
    "test.setup": ["ecto.create --quiet", "ecto.migrate --quiet"],
    "test.reset": ["ecto.drop --quiet", "test.setup"]
  ]
end
```

#### 2. Create `config/config.exs` and `config/test.exs`

```elixir
# config/config.exs
import Config

if config_env() == :test do
  import_config "test.exs"
end
```

```elixir
# config/test.exs
import Config

# Your module's own test repo
config :my_module, ecto_repos: [MyModule.Test.Repo]

config :my_module, MyModule.Test.Repo,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  database: "my_module_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Wire repo for PhoenixKit.RepoHelper — without this, all DB calls crash
config :phoenix_kit, repo: MyModule.Test.Repo

config :logger, level: :warning
```

#### 3. Create test support modules

```elixir
# test/support/test_repo.ex
defmodule MyModule.Test.Repo do
  use Ecto.Repo,
    otp_app: :my_module,
    adapter: Ecto.Adapters.Postgres
end
```

```elixir
# test/support/data_case.ex
defmodule MyModule.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :integration

      alias MyModule.Test.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  alias Ecto.Adapters.SQL.Sandbox
  alias MyModule.Test.Repo, as: TestRepo

  setup tags do
    pid = Sandbox.start_owner!(TestRepo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
    :ok
  end
end
```

#### 4. Create `test/test_helper.exs`

```elixir
alias MyModule.Test.Repo, as: TestRepo

db_config = Application.get_env(:my_module, TestRepo, [])
db_name = db_config[:database] || "my_module_test"

# Check if test database exists
db_check =
  case System.cmd("psql", ["-lqt"], stderr_to_stdout: true) do
    {output, 0} ->
      exists =
        output
        |> String.split("\n")
        |> Enum.any?(fn line ->
          line |> String.split("|") |> List.first("") |> String.trim() == db_name
        end)

      if exists, do: :exists, else: :not_found

    _ ->
      :try_connect
  end

repo_available =
  if db_check == :not_found do
    IO.puts("\n  Test database \"#{db_name}\" not found — integration tests excluded.\n  Run: createdb #{db_name}\n")
    false
  else
    try do
      {:ok, _} = TestRepo.start_link()

      # Create uuid_generate_v7() — normally from PhoenixKit's V40 migration.
      # Your test DB won't have it unless you create it here.
      TestRepo.query!("""
      CREATE OR REPLACE FUNCTION uuid_generate_v7()
      RETURNS uuid AS $$
      DECLARE
        unix_ts_ms bytea;
        uuid_bytes bytea;
      BEGIN
        unix_ts_ms := substring(int8send(floor(extract(epoch FROM clock_timestamp()) * 1000)::bigint) FROM 3);
        uuid_bytes := unix_ts_ms || gen_random_bytes(10);
        uuid_bytes := set_byte(uuid_bytes, 6, (get_byte(uuid_bytes, 6) & 15) | 112);
        uuid_bytes := set_byte(uuid_bytes, 8, (get_byte(uuid_bytes, 8) & 63) | 128);
        RETURN encode(uuid_bytes, 'hex')::uuid;
      END;
      $$ LANGUAGE plpgsql VOLATILE;
      """)

      # Run your migration if you have one
      # Ecto.Migrator.up(TestRepo, 0, MyModule.Migration, log: false)

      Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
      true
    rescue
      e ->
        IO.puts("\n  Could not connect to test database — integration tests excluded.\n  Error: #{Exception.message(e)}\n")
        false
    catch
      :exit, reason ->
        IO.puts("\n  Could not connect to test database — integration tests excluded.\n  Error: #{inspect(reason)}\n")
        false
    end
  end

# Start minimal PhoenixKit services needed for tests
{:ok, _} = PhoenixKit.PubSub.Manager.start_link([])
{:ok, _} = PhoenixKit.ModuleRegistry.start_link([])

exclude = if repo_available, do: [], else: [:integration]
ExUnit.start(exclude: exclude)
```

#### 5. Create the database

```bash
createdb my_module_test
mix test
```

Integration tests are tagged `:integration` via the `DataCase` and automatically excluded when the database doesn't exist.

### Gotchas

These are common issues you'll hit when setting up tests for PhoenixKit modules:

**Use string keys for context module attrs.** PhoenixKit context modules (like `Connections.create_connection/1`) may inject string keys internally. If you pass atom keys, you'll get `Ecto.CastError: mixed keys`. Always use string keys:

```elixir
# Bad — will crash with mixed key error
Connections.create_connection(%{name: "Test", direction: "sender", site_url: "https://example.com"})

# Good
Connections.create_connection(%{"name" => "Test", "direction" => "sender", "site_url" => "https://example.com"})
```

**Use `UUIDv7.generate()` for foreign key fields.** Fields like `approved_by_uuid` reference the `phoenix_kit_users` table. Passing a plain string like `"admin"` causes `Ecto.ChangeError: does not match type UUIDv7`:

```elixir
# Bad
Connections.approve_connection(conn, "admin")

# Good
Connections.approve_connection(conn, UUIDv7.generate())
```

**Ecto schema types vs migration types.** Migrations use `:bigint` and `:text`, but Ecto schemas must use `:integer` and `:string` — Ecto doesn't have `:bigint` or `:text` as schema field types. The distinction only matters at the database level.

**`enabled?/0` hits the database.** Calling `enabled?/0` or `get_config/0` in unit tests triggers a DB call through `PhoenixKit.Settings`, which fails with a sandbox ownership error. Either tag those tests as `:integration` or just test `function_exported?/3`:

```elixir
# In unit tests (no DB) — test the export, not the call
test "get_config/0 is exported" do
  assert function_exported?(MyModule, :get_config, 0)
end
```

**Run migrations via `Ecto.Migrator`.** If your module has a migration, you can't call `MyModule.Migration.up()` directly — it uses `Ecto.Migration` macros that require a migrator process. Use `Ecto.Migrator.up/4`:

```elixir
# In test_helper.exs
Ecto.Migrator.up(TestRepo, 0, MyModule.Migration, log: false)
```

**ETS-based stores use hardcoded table names.** If your module has a GenServer with ETS (like a session store), the table name is global. Tests that start their own instance will conflict. Use `setup_all` with `already_started` handling:

```elixir
setup_all do
  case MyStore.start_link([]) do
    {:ok, _pid} -> :ok
    {:error, {:already_started, _pid}} -> :ok
  end
  :ok
end
```

**`uuid_generate_v7()` must be created manually in test DB.** PhoenixKit's V40 migration creates this PostgreSQL function, but your test database won't have it. The `test_helper.exs` template above includes the function definition.

## Verifying your module

After adding your module to the parent app and starting the server, check:

**Full-featured modules:**

1. **Admin > Modules page** — your module should appear with its name, icon, and toggle
2. **Admin sidebar** — your tab should appear under the Modules group (if enabled)
3. **Admin > Roles** — your permission key should appear in the permissions matrix
4. **Click the tab** — your LiveView should render inside the admin layout

**Headless modules:**

1. **Admin > Modules page** — your module should appear with its name, icon, and toggle
2. **Admin > Roles** — your permission key should appear (if you defined `permission_metadata/0`)
3. **No sidebar entry** — expected, since there are no tabs
4. **Call your functions** — verify your API works from `iex -S mix` or from another module

The Admin role automatically gets access to new modules. Custom roles need the permission granted by an Owner or Admin.

## Tailwind CSS scanning for modules

When your module has templates with Tailwind CSS classes (inline `~H` sigils or `.heex` files), the parent app's Tailwind build needs to know where to scan for those classes. Without this, Tailwind will purge your module's CSS classes and your UI will break (elements hidden, styles missing).

### How it works

PhoenixKit's installer (`mix phoenix_kit.install`) automatically discovers plugin modules and adds `@source` directives to the parent app's `assets/css/app.css`. Each module declares which OTP app to scan via the `css_sources/0` callback.

### Adding CSS source scanning to your module

If your module uses Tailwind classes in its templates, implement `css_sources/0`:

```elixir
@impl PhoenixKit.Module
def css_sources, do: [:my_phoenix_kit_module]
```

The return value is a list of OTP app name atoms. The installer resolves the correct file path automatically:

- **Hex deps** → scans `deps/my_phoenix_kit_module/`
- **Path deps** → scans the declared path from `mix.exs` (e.g. `../my_phoenix_kit_module`)

After adding a new module with CSS sources, the user runs `mix phoenix_kit.install` and the installer adds the `@source` line to their `app.css`. This is idempotent — safe to run multiple times.

### When you DON'T need this

- **Headless modules** (no templates, no UI) — skip the callback, the default `[]` is fine
- **Modules using only PhoenixKit's built-in components** — if all your Tailwind classes already exist in `phoenix_kit` or daisyUI, they're already scanned
- **Modules with no custom Tailwind classes** — if you only use classes that are already present in `phoenix_kit`'s templates

### When you DO need this

- Your module has `~H` sigils or `.heex` templates with Tailwind responsive classes (`sm:block`, `md:grid-cols-2`, etc.)
- You use Tailwind utility classes in module attributes or string literals that get rendered as HTML
- You have custom CSS class combinations not used anywhere in `phoenix_kit`

### Example: what the installer generates

For a path dep (`path: "../phoenix_kit_publishing"`):
```css
@source "../../../phoenix_kit_publishing";
```

For a Hex dep:
```css
@source "../../deps/phoenix_kit_publishing";
```

### Troubleshooting CSS issues

If elements are invisible or styles are missing after extracting a module:

1. Check that `css_sources/0` is implemented and returns your app name
2. Run `mix phoenix_kit.install` in the parent app
3. Verify the `@source` line was added to `assets/css/app.css`
4. Restart the Phoenix server (Tailwind watches for file changes, but the source config is read on startup)

## Troubleshooting

### Module doesn't show up in the admin sidebar

1. **Check the dep is installed** — run `mix deps.get` and verify no errors
2. **Check it compiles** — run `mix compile` and look for errors in your module
3. **Check `@phoenix_kit_module` attribute** — `use PhoenixKit.Module` sets this automatically. If you're not using the macro, you need `@phoenix_kit_module true` in your module
4. **Check `admin_tabs/0`** — returns a list of `%Tab{}` structs? Has `:live_view` field set?
5. **Check the module is enabled** — go to Admin > Modules and toggle it on
6. **Recompile the parent** — routes are generated at compile time: `mix deps.compile phoenix_kit --force`

### Tab shows but clicking gives a 404

1. **Check `:live_view` field** — must be `{MyModule.Web.SomeLive, :action}` with a real module
2. **Check the LiveView compiles** — typo in the module name?
3. **Check `:path` uses hyphens** — `"my-module"` not `"my_module"`
4. **Restart the server** — routes are compiled at startup, not hot-reloaded
5. **Check path parameters** — `:uuid` in the path must match params handled in `handle_params/3`

### Permission denied (302 redirect)

1. **Check `:permission` on your tab** — should match `module_key()`
2. **Check `permission_metadata/0`** — the `key` field must match `module_key()`
3. **Check the role has permission** — Admin gets it automatically, custom roles need it granted
4. **Check module is enabled** — disabled modules deny access to non-system roles

### `enabled?/0` crashes on startup

Your `enabled?/0` runs before migrations have created the settings table. Always wrap it:

```elixir
def enabled? do
  Settings.get_boolean_setting("my_module_enabled", false)
rescue
  _ -> false
end
```

### Settings not persisting

Make sure you're using `update_boolean_setting_with_module/3` (not `update_setting/2`) for the enable/disable toggle. The `_with_module` variant ties the setting to your module key for proper cleanup.

### JS hooks not registering

1. **Check the page is entered via full page load** — `redirect/2` or `<a href>`, not `navigate/2`
2. **Check `window.PhoenixKitHooks`** — open browser console, verify your hook is registered
3. **Check element has `phx-hook`** — must match the hook name exactly
4. **Check element has a unique `id`** — required for hooks to work

### Changes not taking effect

Stale compiled `.beam` files can persist old module versions. When changes aren't showing up:

1. **Force recompile your dep** — `mix deps.compile my_module --force` from the parent app
2. **Full clean rebuild** — `mix deps.clean my_module && mix deps.get && mix deps.compile my_module --force`
3. **Restart the server** — the dev reloader doesn't watch deps for changes
4. **Recompile the parent too** — `mix compile --force` (needed when routes or callbacks change)

This is especially common when debugging route registration, CSS scanning, or callback changes.

### Base64 JS not updating

1. **Recompile the dep** — `mix deps.compile my_module --force` from the parent app
2. **Restart the server** — dev reloader doesn't pick up dep changes automatically
3. **Check `@external_resource`** — must point to the JS file so Mix tracks it

## Publishing to Hex

When your module is ready to share:

1. Add hex metadata to `mix.exs`:

```elixir
def project do
  [
    app: :my_phoenix_kit_module,
    version: "1.0.0",
    description: "A PhoenixKit plugin that does X",
    package: package(),
    deps: deps()
  ]
end

defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/you/my_phoenix_kit_module"},
    files: ~w(lib mix.exs README.md LICENSE)
  ]
end
```

2. Switch the phoenix_kit dep from path to hex version:

```elixir
{:phoenix_kit, "~> 1.7"}  # not path: "../phoenix_kit"
```

3. Publish:

```bash
mix hex.publish
```

Users install with:

```elixir
{:my_phoenix_kit_module, "~> 1.0"}
```

No config needed — auto-discovery handles the rest.

## Important rules

1. **`module_key/0`** must be unique across all modules
2. **`permission_metadata().key`** must match `module_key/0`
3. **Tab `:id`** must be unique across all modules (prefix with `:admin_yourmodule`)
4. **Tab `:path`** — use relative slugs with **hyphens** (e.g., `"my-module"`). Core prepends `/admin/` or `/admin/settings/` based on context. Use absolute paths (starting with `/`) only for special cases.
5. **Tab `:permission`** should match `module_key/0` so custom roles get proper access
6. **`enabled?/0`** should rescue and return `false` — it's called before migrations run
7. **Settings keys** must be namespaced (e.g., `"my_module_enabled"`, not `"enabled"`)
8. **`get_config/0`** is called on every Modules page render — keep it fast
9. **Paths** must go through `Routes.path/1` — never use relative paths in templates
10. **JS hooks** must register on `window.PhoenixKitHooks` — no access to parent app's build pipeline

## License

MIT
