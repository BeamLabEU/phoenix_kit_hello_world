# PhoenixKitHelloWorld

A minimal PhoenixKit plugin module. Use this as a template for building your own.

## What this demonstrates

- Zero-config auto-discovery (just add the dep, no config line needed)
- Admin sidebar tab with automatic routing
- Enable/disable toggle on the admin Modules page
- Permission key in the roles/permissions matrix
- Live sidebar updates when the module is toggled

## Quick start

Add to your parent app's `mix.exs`:

```elixir
{:phoenix_kit_hello_world, path: "../phoenix_kit_hello_world"}
```

Run `mix deps.get` and start the server. The module appears in:

- **Admin sidebar** (under Modules section) — click to see the Hello World page
- **Admin > Modules** — toggle it on/off
- **Admin > Roles** — grant/revoke access per role

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

defp deps do
  [
    {:phoenix_kit, "~> 1.7"},
    {:phoenix_live_view, "~> 1.0"}
  ]
end
```

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
  use Phoenix.LiveView

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

```elixir
# In parent app's mix.exs
{:my_phoenix_kit_module, path: "../my_phoenix_kit_module"}
```

Run `mix deps.get`, start the server, and your module appears in the admin panel.

## Project structure

```
lib/
  phoenix_kit_hello_world.ex          # Main module (behaviour callbacks)
  phoenix_kit_hello_world/
    web/
      hello_live.ex                   # Admin LiveView page
test/
  phoenix_kit_hello_world_test.exs    # Behaviour compliance tests
mix.exs                               # Package configuration
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

## Common patterns

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

Tabs define sidebar entries. Key fields:

| Field | Type | Description |
|---|---|---|
| `:id` | atom | Unique identifier (prefix with your module name) |
| `:label` | string | Display text in sidebar |
| `:icon` | string | Heroicon name (e.g. `"hero-puzzle-piece"`) |
| `:path` | string | Relative path slug (e.g. `"my-module"`, use hyphens). Core prepends `/admin/` for admin tabs, `/admin/settings/` for settings tabs. Paths starting with `/` are used as-is. |
| `:priority` | integer | Sort order (lower = higher in sidebar) |
| `:level` | atom | `:admin` or `:settings` |
| `:permission` | string | Permission key (use `module_key()`) |
| `:group` | atom | Sidebar group (`:admin_modules` for module tabs) |
| `:match` | atom | `:exact` or `:prefix` for active state highlighting |
| `:live_view` | tuple | `{MyModule.Web.SomeLive, :action}` for auto-routing |
| `:parent` | atom | Parent tab ID (for subtabs, e.g. `:admin_settings`) |

### Routes (`PhoenixKit.Routes`)

Prefix-aware path helpers. Never hardcode `/phoenix_kit/...` paths.

```elixir
Routes.path("/admin/my-module")       # respects configured URL prefix
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

## Verifying your module

After adding your module to the parent app and starting the server, check:

1. **Admin > Modules page** — your module should appear with its name, icon, and toggle
2. **Admin sidebar** — your tab should appear under the Modules group (if enabled)
3. **Admin > Roles** — your permission key should appear in the permissions matrix
4. **Click the tab** — your LiveView should render inside the admin layout

The Admin role automatically gets access to new modules. Custom roles need the permission granted by an Owner or Admin.

## Testing

The template includes behaviour compliance tests. Run them with:

```bash
mix test
```

These tests verify your module implements all required callbacks correctly, that permission metadata matches the module key, and that tab definitions are valid.

For integration testing (LiveView rendering, database interactions), you'll need a parent app with phoenix_kit installed. The template's tests focus on what can be verified without a running application.

## Sidebar priority and groups

### Priority ranges

Priority controls the sort order in the sidebar (lower number = higher position):

| Range | Used by |
|---|---|
| 100–199 | Core admin (Dashboard) |
| 200–299 | Users section |
| 300–399 | Media section |
| 400–599 | Reserved for future core sections |
| **600–899** | **Module tabs — use this range** |
| 900–999 | System section (Settings, Modules) |

Pick a priority in the **600–899** range for your module. Avoid exact conflicts with other modules by spacing them out (e.g. 650, 700, 750).

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

## Troubleshooting

### Module doesn't show up in the admin sidebar

1. **Check the dep is installed** — run `mix deps.get` and verify no errors
2. **Check it compiles** — run `mix compile` and look for errors in your module
3. **Check `@phoenix_kit_module` attribute** — `use PhoenixKit.Module` sets this automatically. If you're not using the macro, you need `@phoenix_kit_module true` in your module
4. **Check `admin_tabs/0`** — returns a list of `%Tab{}` structs? Has `:live_view` field set?
5. **Check the module is enabled** — go to Admin > Modules and toggle it on

### Tab shows but clicking gives a 404

1. **Check `:live_view` field** — must be `{MyModule.Web.SomeLive, :action}` with a real module
2. **Check the LiveView compiles** — typo in the module name?
3. **Check `:path` uses hyphens** — `"my-module"` not `"my_module"`
4. **Restart the server** — routes are compiled at startup, not hot-reloaded

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

## Database conventions

If your module needs database tables, follow these conventions to avoid collisions with other modules and phoenix_kit internals.

### Table naming

Prefix all tables with `phoenix_kit_` followed by your module key:

```
phoenix_kit_hello_world_items
phoenix_kit_hello_world_categories
```

Never use generic names like `items` or `posts` — another module or the parent app might use them.

### Migrations

External plugins can't add to phoenix_kit's internal versioned migration sequence (V01–V62). Instead, ship a mix task that generates migrations into the parent app:

```elixir
# lib/mix/tasks/my_module.install.ex
defmodule Mix.Tasks.MyModule.Install do
  use Mix.Task

  @shortdoc "Generates MyModule database migrations"

  def run(_args) do
    source = Application.app_dir(:my_phoenix_kit_module, "priv/templates/migrations")
    target = Path.join(Mix.Project.app_path(), "../../priv/repo/migrations")

    # Copy migration templates with timestamps
    # ...
  end
end
```

Then the user runs:

```bash
mix my_module.install
mix ecto.migrate
```

This is the same pattern phoenix_kit itself uses with `mix phoenix_kit.install`.

### Foreign keys to phoenix_kit tables

These tables are part of the public schema contract and safe to reference:

| Table | Primary key | Notes |
|---|---|---|
| `phoenix_kit_users` | `uuid` (UUIDv7) | User accounts |
| `phoenix_kit_user_roles` | `uuid` (UUIDv7) | Role definitions |
| `phoenix_kit_settings` | `uuid` (UUIDv7) | Key/value settings |

Always reference the `uuid` column, not `id` (integer IDs are deprecated):

```elixir
# In your migration
create table(:phoenix_kit_hello_world_items, primary_key: false) do
  add :uuid, :uuid, primary_key: true, default: fragment("uuid_generate_v7()")
  add :name, :string, null: false
  add :user_uuid, references(:phoenix_kit_users, column: :uuid, type: :uuid),
    null: false

  timestamps(type: :utc_datetime)
end
```

```elixir
# In your schema
schema "phoenix_kit_hello_world_items" do
  field :uuid, UUIDv7, primary_key: true, autogenerate: true
  field :name, :string

  belongs_to :user, PhoenixKit.Users.Auth.User,
    foreign_key: :user_uuid, references: :uuid, type: UUIDv7

  timestamps(type: :utc_datetime)
end
```

### Idempotent migrations

Wrap table creation in existence checks so migrations are safe to re-run:

```elixir
def up do
  unless table_exists?("phoenix_kit_hello_world_items") do
    create table(:phoenix_kit_hello_world_items, primary_key: false) do
      # ...
    end
  end
end

defp table_exists?(name) do
  query = "SELECT 1 FROM information_schema.tables WHERE table_name = '#{name}'"
  case repo().query(query) do
    {:ok, %{num_rows: n}} when n > 0 -> true
    _ -> false
  end
end
```

## License

MIT
