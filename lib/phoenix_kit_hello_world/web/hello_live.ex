defmodule PhoenixKitHelloWorld.Web.HelloLive do
  @moduledoc """
  Admin LiveView for the Hello World plugin module.

  This is the page users see when they click the "Hello World" tab in the
  admin sidebar. PhoenixKit wraps it in the admin layout automatically —
  you get the sidebar, header, and theme for free.

  ## How routing works

  You do NOT need to add routes manually. The `live_view` field in
  `PhoenixKitHelloWorld.admin_tabs/0` tells PhoenixKit to generate:

      live "/admin/hello-world", PhoenixKitHelloWorld.Web.HelloLive, :index

  at compile time, inside the admin `live_session` with the admin layout applied.

  ## Assigns available

  PhoenixKit's `on_mount` hooks inject these assigns into every admin LiveView:

  - `@phoenix_kit_current_scope` — the authenticated user's scope (role, permissions)
  - `@current_locale` — the current locale string
  - `@url_path` — the current URL path (used for active nav highlighting)

  ## Tips for your own LiveView

  - Use daisyUI semantic classes (`bg-base-100`, `text-base-content`) for theme support
  - Set `@page_title` in mount — it appears in the browser tab
  - You can use `Phoenix.PubSub` for real-time updates just like any LiveView
  - For forms, use `Phoenix.Component.assign/2` and standard LiveView patterns
  """
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Hello World")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col mx-auto max-w-2xl px-4 py-6">
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body items-center text-center">
          <div class="text-6xl mb-4">👋</div>
          <h2 class="card-title text-3xl">Hello World!</h2>
          <p class="text-base-content/70 mt-2">
            This is a demo PhoenixKit plugin module installed as an external package.
            If you can see this page, auto-discovery, routing, and permissions are all working.
          </p>

          <div class="divider"></div>

          <div class="bg-base-200 rounded-lg p-4 w-full text-left">
            <h3 class="font-semibold mb-3">Module Info</h3>
            <dl class="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-sm">
              <dt class="text-base-content/70">Module</dt>
              <dd class="font-mono">{inspect(PhoenixKitHelloWorld)}</dd>
              <dt class="text-base-content/70">Version</dt>
              <dd class="font-mono">{PhoenixKitHelloWorld.version()}</dd>
              <dt class="text-base-content/70">Key</dt>
              <dd class="font-mono">{PhoenixKitHelloWorld.module_key()}</dd>
              <dt class="text-base-content/70">Enabled</dt>
              <dd class="font-mono">{to_string(PhoenixKitHelloWorld.enabled?())}</dd>
            </dl>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
