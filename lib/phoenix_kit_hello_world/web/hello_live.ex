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

  alias PhoenixKit.Users.Auth.Scope

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns[:phoenix_kit_current_scope]

    {:ok,
     assign(socket,
       page_title: "Hello World",
       user_email: scope && scope.user && scope.user.email,
       user_roles: scope && Scope.user_roles(scope),
       is_admin: scope && Scope.admin?(scope),
       module_access: scope && Scope.has_module_access?(scope, "hello_world")
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col mx-auto max-w-3xl px-4 py-6 gap-6">
      <%!-- Status card --%>
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body items-center text-center">
          <h2 class="card-title text-3xl">Hello World Plugin</h2>
          <p class="text-base-content/70 mt-1">
            This is an external PhoenixKit plugin module. Everything below confirms it's working.
          </p>

          <div class="flex flex-wrap gap-2 mt-4">
            <div class="badge badge-success gap-1">Auto-discovery</div>
            <div class="badge badge-success gap-1">Routing</div>
            <div class="badge badge-success gap-1">Permissions</div>
            <div class="badge badge-success gap-1">Admin layout</div>
            <div class="badge badge-success gap-1">Sidebar tab</div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <%!-- Module info --%>
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h3 class="card-title text-lg">Module Info</h3>
            <dl class="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-sm mt-2">
              <dt class="text-base-content/70">Module</dt>
              <dd class="font-mono text-xs">{inspect(PhoenixKitHelloWorld)}</dd>
              <dt class="text-base-content/70">Key</dt>
              <dd class="font-mono">{PhoenixKitHelloWorld.module_key()}</dd>
              <dt class="text-base-content/70">Version</dt>
              <dd class="font-mono">{PhoenixKitHelloWorld.version()}</dd>
              <dt class="text-base-content/70">Enabled</dt>
              <dd>
                <span class={[
                  "badge badge-sm",
                  if(PhoenixKitHelloWorld.enabled?(), do: "badge-success", else: "badge-error")
                ]}>
                  {to_string(PhoenixKitHelloWorld.enabled?())}
                </span>
              </dd>
            </dl>
          </div>
        </div>

        <%!-- Current user info (demonstrates Scope API) --%>
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h3 class="card-title text-lg">Current User</h3>
            <p class="text-base-content/60 text-xs">
              via <code class="bg-base-200 px-1 rounded">@phoenix_kit_current_scope</code>
            </p>
            <dl class="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-sm mt-2">
              <dt class="text-base-content/70">Email</dt>
              <dd class="font-mono text-xs">{@user_email || "—"}</dd>
              <dt class="text-base-content/70">Roles</dt>
              <dd>
                <div class="flex flex-wrap gap-1">
                  <span
                    :for={role <- @user_roles || []}
                    class="badge badge-sm badge-outline"
                  >
                    {role}
                  </span>
                </div>
              </dd>
              <dt class="text-base-content/70">Admin?</dt>
              <dd class="font-mono">{to_string(@is_admin)}</dd>
              <dt class="text-base-content/70">Module access?</dt>
              <dd class="font-mono">{to_string(@module_access)}</dd>
            </dl>
          </div>
        </div>
      </div>

      <%!-- Next steps --%>
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h3 class="card-title text-lg">Next Steps</h3>
          <p class="text-base-content/70 text-sm">
            This page is your starting point. Replace it with your own content.
          </p>
          <ul class="text-sm space-y-2 mt-2 list-none">
            <li class="flex gap-2">
              <span class="text-base-content/40">1.</span>
              <span>Edit <code class="bg-base-200 px-1 rounded text-xs">lib/phoenix_kit_hello_world/web/hello_live.ex</code> — this file</span>
            </li>
            <li class="flex gap-2">
              <span class="text-base-content/40">2.</span>
              <span>Update callbacks in <code class="bg-base-200 px-1 rounded text-xs">lib/phoenix_kit_hello_world.ex</code> — module key, name, tabs</span>
            </li>
            <li class="flex gap-2">
              <span class="text-base-content/40">3.</span>
              <span>Add more pages by returning additional tabs from <code class="bg-base-200 px-1 rounded text-xs">admin_tabs/0</code></span>
            </li>
            <li class="flex gap-2">
              <span class="text-base-content/40">4.</span>
              <span>Add a settings page via <code class="bg-base-200 px-1 rounded text-xs">settings_tabs/0</code></span>
            </li>
            <li class="flex gap-2">
              <span class="text-base-content/40">5.</span>
              <span>See the <code class="bg-base-200 px-1 rounded text-xs">README.md</code> for the full guide</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
