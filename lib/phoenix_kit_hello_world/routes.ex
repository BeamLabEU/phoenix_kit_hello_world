defmodule PhoenixKitHelloWorld.Routes do
  @moduledoc """
  Route module for complex routing needs.

  For simple modules with a single admin page, the `live_view` field in
  `admin_tabs/0` is sufficient — PhoenixKit auto-generates the route.

  For modules with **multiple admin pages**, public-facing routes, or custom
  controllers, implement this module and return it from `route_module/0`.

  ## Available functions

  | Function                  | Position in router                        | Use for                               |
  |---------------------------|-------------------------------------------|---------------------------------------|
  | `admin_locale_routes/0`   | Inside admin live_session (localized)     | Admin LiveView routes                 |
  | `admin_routes/0`          | Inside admin live_session (non-localized) | Same, for non-locale-prefixed paths   |
  | `generate/1`              | Early, before localized routes            | Non-catch-all public routes           |
  | `public_routes/1`         | **Last**, after all other routes          | Catch-all public routes               |

  ## When you need this

  If your module has only one admin page, you DON'T need this — the `live_view`
  field on your admin tab handles it automatically. Delete this file and set
  `route_module/0` to `nil`.

  If your module has multiple admin pages (e.g., list + form + settings), you
  MUST define all admin LiveView routes here. The `live_view` field on
  `admin_tabs/0` only generates ONE route per tab — it can't handle sub-pages
  like `/admin/your-module/new` or `/admin/your-module/:id/edit`.

  ## Route ordering warning

  If your module has catch-all routes like `/:slug` or `/:group/*path`, they
  **must** go in `public_routes/1` — NOT `generate/1`. Routes in `generate/1`
  are placed early in the router and will intercept `/admin/*` paths, breaking
  the admin panel.

  ## Example: multi-page admin module

      def admin_locale_routes do
        quote do
          live "/admin/my-module", MyModule.Web.Index, :index, as: :my_module_localized
          live "/admin/my-module/new", MyModule.Web.Form, :new, as: :my_module_new_localized
          live "/admin/my-module/:id/edit", MyModule.Web.Form, :edit, as: :my_module_edit_localized
          live "/admin/settings/my-module", MyModule.Web.Settings, :index, as: :my_module_settings_localized
        end
      end

      def admin_routes do
        quote do
          live "/admin/my-module", MyModule.Web.Index, :index, as: :my_module
          live "/admin/my-module/new", MyModule.Web.Form, :new, as: :my_module_new
          live "/admin/my-module/:id/edit", MyModule.Web.Form, :edit, as: :my_module_edit
          live "/admin/settings/my-module", MyModule.Web.Settings, :index, as: :my_module_settings
        end
      end
  """

  # ── Admin routes ─────────────────────────────────────────────────────
  # Uncomment and customize these if your module has multiple admin pages.
  # Both functions must define the same routes — one for localized paths
  # (with /:locale prefix) and one for non-localized paths.
  #
  # IMPORTANT: Every route needs a unique `:as` name. Use a `_localized`
  # suffix to distinguish the two sets.

  # def admin_locale_routes do
  #   quote do
  #     live "/admin/hello-world", PhoenixKitHelloWorld.Web.HelloLive, :index,
  #       as: :hello_world_localized
  #   end
  # end

  # def admin_routes do
  #   quote do
  #     live "/admin/hello-world", PhoenixKitHelloWorld.Web.HelloLive, :index,
  #       as: :hello_world
  #   end
  # end

  # ── Public routes ────────────────────────────────────────────────────
  # Uncomment if your module needs public (non-admin) routes.

  # def generate(url_prefix) do
  #   quote do
  #     scope unquote(url_prefix) do
  #       pipe_through [:browser, :phoenix_kit_auto_setup]
  #
  #       post "/hello-world/submit",
  #            PhoenixKitHelloWorld.Web.SubmitController,
  #            :submit
  #     end
  #   end
  # end
end
