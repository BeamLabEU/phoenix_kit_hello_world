defmodule PhoenixKitHelloWorld.Web.HelloLive do
  @moduledoc """
  Admin LiveView for the Hello World plugin module — the "landing page" of the showcase.

  This is the page users see when they click the "Hello World" tab in the admin sidebar.
  PhoenixKit wraps it in the admin layout automatically — you get the sidebar, header,
  and theme for free.

  ## How routing works

  You do NOT need to add routes manually. The `live_view` field in
  `PhoenixKitHelloWorld.admin_tabs/0` tells PhoenixKit to generate:

      live "/admin/hello-world", PhoenixKitHelloWorld.Web.HelloLive, :index

  at compile time, inside the admin `live_session` with the admin layout applied.

  ## Activity logging demo

  The "Log demo event" button below shows the canonical PhoenixKit activity logging
  pattern. Every mutating operation in your module should log an activity so actions
  are auditable in the Events tab and the global /admin/activity page.

  See `log_demo_event/1` for the pattern — all logging is wrapped in
  `Code.ensure_loaded?/1` so your module doesn't hard-require PhoenixKit.Activity.

  ## Assigns available

  PhoenixKit's `on_mount` hooks inject these assigns into every admin LiveView:

  - `@phoenix_kit_current_scope` — the authenticated user's scope (role, permissions)
  - `@phoenix_kit_current_user` — the authenticated user struct (has `.uuid`, `.email`, etc.)
  - `@current_locale` — the current locale string
  - `@url_path` — the current URL path (used for active nav highlighting)
  """
  use PhoenixKitWeb, :live_view

  require Logger

  alias PhoenixKit.Users.Auth.Scope
  alias PhoenixKitHelloWorld.Paths

  @demo_event_snippet """
  PhoenixKit.Activity.log(%{
    action: "hello_world.demo_event",
    module: "hello_world",
    mode: "manual",
    actor_uuid: current_user.uuid,
    resource_type: "hello_world",
    metadata: %{"source" => "showcase_button"}
  })
  """

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns[:phoenix_kit_current_scope]

    {:ok,
     assign(socket,
       page_title: Gettext.gettext(PhoenixKitWeb.Gettext, "Hello World"),
       user_email: scope && scope.user && scope.user.email,
       user_roles: scope && Scope.user_roles(scope),
       is_admin: scope && Scope.admin?(scope),
       module_access: scope && Scope.has_module_access?(scope, "hello_world"),
       last_logged_at: nil,
       demo_event_snippet: @demo_event_snippet
     )}
  end

  @impl true
  def handle_event("log_demo_event", _params, socket) do
    if socket.assigns[:module_access] do
      handle_demo_event_log(socket)
    else
      {:noreply,
       put_flash(
         socket,
         :error,
         Gettext.gettext(PhoenixKitWeb.Gettext, "You do not have permission to log events.")
       )}
    end
  end

  defp handle_demo_event_log(socket) do
    case log_demo_event(socket) do
      {:ok, _entry} ->
        {:noreply,
         socket
         |> assign(:last_logged_at, DateTime.utc_now())
         |> put_flash(
           :info,
           Gettext.gettext(PhoenixKitWeb.Gettext, "Demo event logged — check the Events tab!")
         )}

      :activity_unavailable ->
        {:noreply,
         put_flash(
           socket,
           :error,
           Gettext.gettext(
             PhoenixKitWeb.Gettext,
             "PhoenixKit.Activity is not loaded. Make sure the host app is up to date."
           )
         )}

      {:error, reason} ->
        Logger.warning("[HelloWorld] Failed to log demo event: #{inspect(reason)}")

        {:noreply,
         put_flash(
           socket,
           :error,
           Gettext.gettext(PhoenixKitWeb.Gettext, "Failed to log event. Check the server logs.")
         )}
    end
  end

  # ── Activity logging ────────────────────────────────────────────

  # Canonical PhoenixKit activity logging pattern for external modules.
  # Guarded with Code.ensure_loaded?/1 so the module works even when Activity
  # isn't available (e.g. on a very old PhoenixKit version).
  defp log_demo_event(socket) do
    if Code.ensure_loaded?(PhoenixKit.Activity) do
      PhoenixKit.Activity.log(%{
        action: "hello_world.demo_event",
        module: "hello_world",
        mode: "manual",
        actor_uuid: actor_uuid(socket),
        resource_type: "hello_world",
        metadata: %{
          "source" => "showcase_button",
          "triggered_at" => DateTime.to_iso8601(DateTime.utc_now())
        }
      })
    else
      :activity_unavailable
    end
  rescue
    e ->
      Logger.warning("[HelloWorld] Activity logging error: #{Exception.message(e)}")
      {:error, e}
  end

  # Extract current user UUID from the socket for actor attribution.
  # Returns nil if no user is logged in (e.g. system/background actions).
  defp actor_uuid(socket) do
    case socket.assigns[:phoenix_kit_current_user] do
      %{uuid: uuid} -> uuid
      _ -> nil
    end
  end

  # ── Render ───────────────────────────────────────────────────────

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

          <div class="flex flex-wrap justify-center gap-2 mt-4">
            <div class="badge badge-success gap-1">
              <.icon name="hero-check-circle-mini" class="w-3 h-3" /> Auto-discovery
            </div>
            <div class="badge badge-success gap-1">
              <.icon name="hero-check-circle-mini" class="w-3 h-3" /> Routing
            </div>
            <div class="badge badge-success gap-1">
              <.icon name="hero-check-circle-mini" class="w-3 h-3" /> Permissions
            </div>
            <div class="badge badge-success gap-1">
              <.icon name="hero-check-circle-mini" class="w-3 h-3" /> Admin layout
            </div>
            <div class="badge badge-success gap-1">
              <.icon name="hero-check-circle-mini" class="w-3 h-3" /> Sidebar tab
            </div>
            <div class="badge badge-success gap-1">
              <.icon name="hero-check-circle-mini" class="w-3 h-3" /> Activity logging
            </div>
          </div>
        </div>
      </div>

      <%!-- Activity logging demo --%>
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h3 class="card-title text-lg">
            <.icon name="hero-bolt" class="w-5 h-5" /> Activity Logging Demo
          </h3>
          <p class="text-base-content/70 text-sm">
            Click the button below to log an activity event.
            Then visit the <.link navigate={Paths.events()} class="link link-primary">Events tab</.link>
            to see it appear in the feed.
          </p>

          <div class="flex items-center gap-3 mt-3">
            <button
              :if={@module_access}
              type="button"
              phx-click="log_demo_event"
              class="btn btn-primary btn-sm"
            >
              <.icon name="hero-play" class="w-4 h-4" />
              {Gettext.gettext(PhoenixKitWeb.Gettext, "Log demo event")}
            </button>

            <div :if={!@module_access} class="alert alert-warning py-2">
              <.icon name="hero-lock-closed" class="w-4 h-4" />
              <span class="text-xs">
                {Gettext.gettext(
                  PhoenixKitWeb.Gettext,
                  "You need the 'hello_world' permission to log events."
                )}
              </span>
            </div>

            <span :if={@last_logged_at} class="text-xs text-base-content/60">
              {Gettext.gettext(PhoenixKitWeb.Gettext, "Last logged at")} {Calendar.strftime(
                @last_logged_at,
                "%H:%M:%S"
              )}
            </span>
          </div>

          <details class="mt-3">
            <summary class="text-xs text-base-content/60 cursor-pointer">
              Show the code pattern
            </summary>
            <pre class="text-xs bg-base-200 p-3 rounded mt-2 overflow-x-auto"><code>{@demo_event_snippet}</code></pre>
          </details>
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

      <%!-- Explore more --%>
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h3 class="card-title text-lg">
            <.icon name="hero-map" class="w-5 h-5" /> Explore the showcase
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-3 mt-2">
            <.link navigate={Paths.events()} class="btn btn-outline btn-sm justify-start">
              <.icon name="hero-clock" class="w-4 h-4" />
              <span>Events feed</span>
              <.icon name="hero-arrow-right" class="w-4 h-4 ml-auto" />
            </.link>
            <.link navigate={Paths.components()} class="btn btn-outline btn-sm justify-start">
              <.icon name="hero-squares-2x2" class="w-4 h-4" />
              <span>Components showcase</span>
              <.icon name="hero-arrow-right" class="w-4 h-4 ml-auto" />
            </.link>
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
              <span>Log all mutations via <code class="bg-base-200 px-1 rounded text-xs">PhoenixKit.Activity.log/1</code> — see the demo button above</span>
            </li>
            <li class="flex gap-2">
              <span class="text-base-content/40">4.</span>
              <span>Browse <.link navigate={Paths.components()} class="link link-primary">Components</.link> to see what's available</span>
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
