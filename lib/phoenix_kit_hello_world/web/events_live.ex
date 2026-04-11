defmodule PhoenixKitHelloWorld.Web.EventsLive do
  @moduledoc """
  Activity events feed for the Hello World module.

  Shows a filterable, infinite-scroll list of activity entries scoped to
  `module: "hello_world"`. This is a generic pattern — every PhoenixKit
  module that logs activities can drop in a near-identical LiveView by
  changing the module filter and the path.

  ## Pattern walkthrough

  1. Uses `stream/4` with a custom `dom_id:` because `PhoenixKit.Activity.Entry`
     uses `:uuid` as the primary key (not `:id`).
  2. Reloads on filter change via `stream(..., reset: true)`.
  3. Infinite scroll via an IntersectionObserver hook on a sentinel div.
  4. All PhoenixKit.Activity calls are guarded with `Code.ensure_loaded?/1`
     so the module works even on hosts without activity logging.
  """

  use Phoenix.LiveView

  import PhoenixKitWeb.Components.Core.Icon, only: [icon: 1]

  alias PhoenixKit.Utils.Routes
  alias PhoenixKitHelloWorld.Paths

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: Gettext.gettext(PhoenixKitWeb.Gettext, "Events"),
       total: 0,
       page: 1,
       has_more: false,
       loading: false,
       filter_action: nil,
       action_types: []
     )
     |> stream(:entries, [], dom_id: &"entry-#{&1.uuid}")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      if connected?(socket) do
        socket
        |> apply_params(params)
        |> assign(:page, 1)
        |> load_filter_options()
        |> reset_and_load()
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filter = Map.get(params, "filter", %{})

    query_params =
      %{}
      |> maybe_put("action", filter["action"])

    path =
      case URI.encode_query(query_params) do
        "" -> Paths.events()
        query -> Paths.events() <> "?#{query}"
      end

    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: Paths.events())}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    if socket.assigns.has_more and not socket.assigns.loading do
      {:noreply, socket |> assign(:loading, true) |> load_next_page()}
    else
      {:noreply, socket}
    end
  end

  # ── Private ──────────────────────────────────────────────────────

  defp apply_params(socket, params) do
    assign(socket, :filter_action, blank_to_nil(params["action"]))
  end

  defp load_filter_options(socket) do
    if Code.ensure_loaded?(PhoenixKit.Activity) do
      all = PhoenixKit.Activity.list(module: "hello_world", per_page: 1000, preload: [])

      action_types =
        all.entries |> Enum.map(& &1.action) |> Enum.uniq() |> Enum.sort()

      assign(socket, action_types: action_types)
    else
      socket
    end
  rescue
    _ -> socket
  end

  defp reset_and_load(socket) do
    socket
    |> assign(:page, 1)
    |> stream(:entries, [], reset: true, dom_id: &"entry-#{&1.uuid}")
    |> load_next_page()
  end

  defp load_next_page(socket) do
    if Code.ensure_loaded?(PhoenixKit.Activity) do
      result =
        PhoenixKit.Activity.list(
          module: "hello_world",
          page: socket.assigns.page,
          per_page: @per_page,
          action: socket.assigns.filter_action,
          preload: [:actor]
        )

      socket
      |> stream(:entries, result.entries)
      |> assign(
        total: result.total,
        page: socket.assigns.page + 1,
        has_more: result.page < result.total_pages,
        loading: false
      )
    else
      assign(socket, loading: false)
    end
  rescue
    _ -> assign(socket, loading: false)
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(val), do: val

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @action_color_keywords [
    {"created", "badge-success"},
    {"restored", "badge-info"},
    {"deleted", "badge-error"},
    {"trashed", "badge-error"},
    {"updated", "badge-warning"},
    {"changed", "badge-warning"},
    {"moved", "badge-info"},
    {"demo", "badge-accent"}
  ]

  defp action_badge_color(action) do
    Enum.find_value(@action_color_keywords, "badge-ghost", fn {keyword, color} ->
      if String.contains?(action, keyword), do: color
    end)
  end

  defp mode_badge_class(mode) do
    case mode do
      "manual" -> "badge-warning"
      "auto" -> "badge-info"
      "cron" -> "badge-secondary"
      _ -> "badge-ghost"
    end
  end

  defp summarize_metadata(nil), do: nil

  defp summarize_metadata(meta) do
    meta
    |> Map.drop(["actor_role"])
    |> Enum.reject(fn {_k, v} -> v == nil or v == "" end)
    |> case do
      [] -> nil
      entries -> Enum.map_join(entries, ", ", fn {k, v} -> "#{k}: #{v}" end)
    end
  end

  defp format_time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 ->
        Gettext.gettext(PhoenixKitWeb.Gettext, "just now")

      diff < 3600 ->
        Gettext.gettext(PhoenixKitWeb.Gettext, "%{count}m ago", count: div(diff, 60))

      diff < 86_400 ->
        Gettext.gettext(PhoenixKitWeb.Gettext, "%{count}h ago", count: div(diff, 3600))

      diff < 604_800 ->
        Gettext.gettext(PhoenixKitWeb.Gettext, "%{count}d ago", count: div(diff, 86_400))

      true ->
        Calendar.strftime(datetime, "%b %d, %Y")
    end
  end

  # ── Render ───────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col mx-auto max-w-5xl px-4 py-6 gap-4">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold">Activity Events</h2>
          <p class="text-sm text-base-content/60 mt-1">
            Events logged by the Hello World module. Click the "Log demo event" button on the
            <.link navigate={Paths.index()} class="link link-primary">Overview</.link>
            page to add entries.
          </p>
        </div>
        <div class="text-sm text-base-content/60">
          {@total} events
        </div>
      </div>

      <%!-- Filters --%>
      <div class="bg-base-200 rounded-lg p-3">
        <.form for={%{}} phx-change="filter" class="flex flex-wrap gap-3 items-end">
          <div class="form-control">
            <label class="label"><span class="label-text text-xs">Action</span></label>
            <label class="select select-bordered select-sm">
              <select name="filter[action]">
                <option value="">All Actions</option>
                <%= for action <- @action_types do %>
                  <option value={action} selected={@filter_action == action}>
                    {action}
                  </option>
                <% end %>
              </select>
            </label>
          </div>

          <button type="button" phx-click="clear_filters" class="btn btn-ghost btn-sm">
            Clear
          </button>
        </.form>
      </div>

      <%!-- Events Feed --%>
      <div id="events-feed" phx-update="stream" class="flex flex-col gap-2">
        <div
          :for={{dom_id, entry} <- @streams.entries}
          id={dom_id}
          class="card card-compact bg-base-100 shadow-sm border border-base-200"
        >
          <div class="card-body flex-row items-center gap-3 py-2 px-4">
            <%!-- Action badge --%>
            <div class="min-w-[180px]">
              <span class={"badge badge-sm #{action_badge_color(entry.action)}"}>
                {entry.action}
              </span>
            </div>

            <%!-- Mode --%>
            <div class="min-w-[60px]">
              <%= if entry.mode do %>
                <span class={"badge badge-xs #{mode_badge_class(entry.mode)}"}>
                  {entry.mode}
                </span>
              <% end %>
            </div>

            <%!-- Details --%>
            <div class="flex-1 min-w-0">
              <% summary = summarize_metadata(entry.metadata) %>
              <%= if summary do %>
                <span
                  class="text-xs text-base-content/60 truncate inline-block max-w-[300px] align-bottom"
                  title={summary}
                >
                  {summary}
                </span>
              <% end %>
            </div>

            <%!-- Actor --%>
            <div class="text-sm text-base-content/70 hidden sm:block">
              <%= if entry.actor do %>
                {entry.actor.email}
              <% else %>
                <span class="text-base-content/40">System</span>
              <% end %>
            </div>

            <%!-- Time --%>
            <div class="text-xs text-base-content/50 min-w-[70px] text-right">
              {format_time_ago(entry.inserted_at)}
            </div>

            <%!-- Detail link --%>
            <.link
              navigate={Routes.path("/admin/activity/#{entry.uuid}")}
              class="btn btn-ghost btn-xs btn-square"
              title="View details"
            >
              <.icon name="hero-arrow-top-right-on-square" class="w-3.5 h-3.5" />
            </.link>
          </div>
        </div>
      </div>

      <%!-- Empty state --%>
      <%= if @total == 0 and not @loading do %>
        <div class="text-center py-12 text-base-content/60">
          <.icon name="hero-bell-slash" class="w-12 h-12 mx-auto mb-2 opacity-50" />
          <p>No events recorded yet</p>
          <p class="text-xs mt-1">
            Head back to the
            <.link navigate={Paths.index()} class="link link-primary">Overview</.link>
            page and click "Log demo event".
          </p>
        </div>
      <% end %>

      <%!-- Infinite scroll sentinel --%>
      <%= if @has_more do %>
        <div id="load-more-sentinel" phx-hook="HelloWorldInfiniteScroll" class="py-4">
          <div class="flex justify-center">
            <span class="loading loading-spinner loading-sm text-base-content/30"></span>
          </div>
        </div>
      <% end %>

      <%= if not @has_more and @total > 0 do %>
        <div class="text-center text-xs text-base-content/40 py-2">
          All events loaded
        </div>
      <% end %>
    </div>

    <script>
      window.PhoenixKitHooks = window.PhoenixKitHooks || {};
      window.PhoenixKitHooks.HelloWorldInfiniteScroll = window.PhoenixKitHooks.HelloWorldInfiniteScroll || {
        mounted() {
          this.observer = new IntersectionObserver((entries) => {
            const entry = entries[0];
            if (entry.isIntersecting) {
              this.pushEvent("load_more", {});
            }
          }, { rootMargin: "200px" });
          this.observer.observe(this.el);
        },
        updated() {
          this.observer.disconnect();
          this.observer.observe(this.el);
        },
        destroyed() {
          this.observer.disconnect();
        }
      };
    </script>
    """
  end
end
