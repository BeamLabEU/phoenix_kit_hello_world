defmodule PhoenixKitHelloWorld.Web.ProjectHelloTabLive do
  @moduledoc """
  The reference **project-extension tab** — the render side of the
  `phoenix_kit_project_extensions/0` contract (see that function in
  `PhoenixKitHelloWorld` for the catalog side; copy the pair when adding a
  project tab to your module).

  The projects hub renders contributed tabs via `live_render` with an
  embed-session contract, so a tab LV must be mountable **off-router**
  (`:not_mounted_at_router`): read everything from `session`, export no
  `handle_params/3`, and never assume router assigns. Session keys the hub
  supplies:

    * `"project_uuid"` — the host project. The ONLY required key.
    * `"ext_key"` / `"instance_key"` — which enablement row this render is.
    * `"config"` — the instance's config map (whitelisted, admin-edited in
      the project's Modules panel).
    * `"current_user_uuid"` — viewer identity for user-aware behavior
      (may be absent; degrade to read-only/anonymous, never crash).
    * `"locale"` — set the Gettext locale when present.
    * `"wrapper_class"`, and the emit-mode keys (`"mode"`,
      `"pubsub_topic"`, `"frame_ref"`) — same semantics as
      `phoenix_kit_projects`' own embedding contract.

  This demo renders the received contract verbatim — the "contract debug"
  card for hub tabs, mirroring what `HelloWidget`'s contract view does for
  dashboard widgets.
  """

  use Phoenix.LiveView

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       project_uuid: session["project_uuid"],
       ext_key: session["ext_key"],
       instance_key: session["instance_key"] || "default",
       config: session["config"] || %{},
       current_user_uuid: session["current_user_uuid"],
       locale: session["locale"]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 border border-base-200">
      <div class="card-body gap-3">
        <h3 class="card-title text-base">Hello from a project extension tab</h3>
        <p class="text-sm opacity-70">
          This tab was contributed by <code>phoenix_kit_hello_world</code> through the
          <code>phoenix_kit_project_extensions/0</code> contract and rendered by the
          projects hub via <code>live_render</code>.
        </p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm">
          <div class="bg-base-200 rounded-lg p-3">
            <div class="font-semibold opacity-60 text-xs uppercase">project_uuid</div>
            <code class="break-all">{@project_uuid || "—"}</code>
          </div>
          <div class="bg-base-200 rounded-lg p-3">
            <div class="font-semibold opacity-60 text-xs uppercase">ext_key / instance</div>
            <code>{@ext_key || "—"} / {@instance_key}</code>
          </div>
          <div class="bg-base-200 rounded-lg p-3">
            <div class="font-semibold opacity-60 text-xs uppercase">viewer</div>
            <code class="break-all">{@current_user_uuid || "anonymous"}</code>
          </div>
          <div class="bg-base-200 rounded-lg p-3">
            <div class="font-semibold opacity-60 text-xs uppercase">config</div>
            <code class="break-all">{inspect(@config)}</code>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
