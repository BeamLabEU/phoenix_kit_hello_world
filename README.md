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
        path: "/admin/my-module",
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
      path: "/admin/settings/my-module",
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

## Important rules

1. **`module_key/0`** must be unique across all modules
2. **`permission_metadata().key`** must match `module_key/0`
3. **Tab `:id`** must be unique across all modules (prefix with `:admin_yourmodule`)
4. **Tab `:path`** must start with `/admin` and use **hyphens** not underscores
5. **Tab `:permission`** should match `module_key/0` so custom roles get proper access
6. **`enabled?/0`** should rescue and return `false` — it's called before migrations run

## License

MIT
