defmodule PhoenixKitHelloWorld.Web.HelloWidget do
  @moduledoc """
  The **reference dashboard widget** — a live example of every capability in the
  `phoenix_kit_dashboards` widget API, in one component. If you're writing a
  widget for your own module, copy this file and the definition in
  `PhoenixKitHelloWorld.phoenix_kit_widgets/0`.

  ## What a widget IS

  A plain `Phoenix.LiveComponent`. The dashboards host renders it as:

      <.live_component
        module={HelloWidget}
        id={instance_id}
        settings={%{"greeting" => "Hi", ...}}  # this instance's saved settings
        view={"card" | "counter" | "contract"} # the selected render variant
        size={%{w: 4, h: 2}}                   # the instance's current span (cells)
        scope={@phoenix_kit_current_scope}     # the viewer — personalize with it
      />

  It runs inside the host LiveView's process (LiveComponents have no process of
  their own). When the catalog entry declares a `refresh_interval`, the host
  re-`send_update/2`s the component on that cadence — `update/2` runs again and
  any state kept in the socket persists between ticks (the counter view uses
  exactly that).

  ## The three views (each declares its own `min_size` in the catalog entry)

  - `"card"` — a greeting card built from the settings (the simple case).
  - `"counter"` — proves live refresh: counts host ticks and shows the last
    tick time, stepping by the `"step"` setting.
  - `"contract"` — the living documentation: prints the exact assigns this
    component received, so you can SEE the contract on a real dashboard.

  ## Notes for widget authors

  - No DB guard here on purpose: this widget renders purely from its assigns.
    The dashboards Registry already gates visibility on `module_key` (module
    enabled + permission), so an in-component `enabled?/0` guard is only needed
    when the widget queries data of its own (see the projects widgets).
  - Render defensively: every setting read uses a default, `size`/`view`/`scope`
    may be nil, and a widget must NEVER crash the host dashboard.
  - A single-row instance (`size.h < 2`) renders compact — tighter paddings,
    smaller text — so the minimum box fits without scrollbars.
  """
  use Phoenix.LiveComponent

  @impl true
  def update(assigns, socket) do
    settings = assigns[:settings] || %{}
    size = assigns[:size]

    # Live-refresh state: `update/2` runs on every host tick; assigns kept in
    # the socket persist between ticks, so this is a real counter.
    ticks = (socket.assigns[:ticks] || 0) + step(settings)

    {:ok,
     socket
     |> assign(:id, assigns.id)
     |> assign(:settings, settings)
     |> assign(:view, assigns[:view] || "card")
     |> assign(:size, size)
     |> assign(:scope, assigns[:scope])
     |> assign(:greeting, Map.get(settings, "greeting", "Hello"))
     |> assign(:note, Map.get(settings, "note", ""))
     |> assign(:tone, tone_class(Map.get(settings, "tone", "")))
     |> assign(:punctuation, Map.get(settings, "punctuation", "!"))
     |> assign(:show_size, Map.get(settings, "show_size", true) in [true, "true"])
     |> assign(:who, viewer_name(assigns[:scope]))
     |> assign(:ticks, ticks)
     |> assign(:ticked_at, DateTime.utc_now())
     |> assign(:compact, compact?(size))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[
      "card h-full overflow-hidden bg-base-100",
      "flex flex-col",
      if(@compact, do: "p-2", else: "p-3")
    ]}>
      <div class={["flex items-center gap-2", if(@compact, do: "mb-1", else: "mb-2")]}>
        <span aria-hidden="true">👋</span>
        <h3 class={["truncate font-semibold", if(@compact, do: "text-xs", else: "text-sm")]}>
          {Gettext.gettext(PhoenixKitWeb.Gettext, "Hello world")}
        </h3>
        <span class="ml-auto badge badge-ghost badge-xs">{@view}</span>
      </div>

      <div class="min-h-0 flex-1 overflow-auto">
        <%!-- view "card": settings-driven greeting (string/text/select settings) --%>
        <div :if={@view == "card"} class="flex h-full flex-col items-center justify-center gap-1 text-center">
          <p class={["font-semibold", @tone, if(@compact, do: "text-lg", else: "text-2xl")]}>
            {@greeting}, {@who}{@punctuation}
          </p>
          <p :if={@note != ""} class="text-xs text-base-content/60">{@note}</p>
          <p :if={@show_size and @size} class="text-[11px] text-base-content/40 tabular-nums">
            {@size.w} × {@size.h} {Gettext.gettext(PhoenixKitWeb.Gettext, "cells")}
          </p>
        </div>

        <%!-- view "counter": proves refresh_interval — host ticks re-run update/2
        and socket assigns persist, so the count climbs while you watch --%>
        <div :if={@view == "counter"} class="flex h-full flex-col items-center justify-center gap-1 text-center">
          <span class={["font-bold tabular-nums", @tone, if(@compact, do: "text-2xl", else: "text-4xl")]}>
            {@ticks}
          </span>
          <p class="text-[11px] text-base-content/40 tabular-nums">
            {Gettext.gettext(PhoenixKitWeb.Gettext, "last tick")} {Calendar.strftime(@ticked_at, "%H:%M:%S")}
          </p>
        </div>

        <%!-- view "contract": the living documentation — the assigns this
        component actually received from the host, verbatim --%>
        <dl :if={@view == "contract"} class="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 font-mono text-xs">
          <dt class="text-base-content/50">view</dt>
          <dd class="truncate">{inspect(@view)}</dd>
          <dt class="text-base-content/50">size</dt>
          <dd class="truncate">{inspect(@size)}</dd>
          <dt class="text-base-content/50">scope</dt>
          <dd class="truncate">
            {if @who == default_who(), do: "(none)", else: "user: " <> @who}
          </dd>
          <dt class="text-base-content/50">settings</dt>
          <dd class="whitespace-pre-wrap break-all">{inspect(@settings, pretty: true)}</dd>
        </dl>
      </div>
    </div>
    """
  end

  # `step` demonstrates a :number setting — form values arrive as strings.
  defp step(settings) do
    case Integer.parse(to_string(settings["step"] || "")) do
      {n, _} when n > 0 -> n
      _ -> 1
    end
  end

  # `tone` demonstrates a :select with {label, value} tuples — the stored value
  # is the machine key, the label is what the settings form shows.
  defp tone_class("primary"), do: "text-primary"
  defp tone_class("success"), do: "text-success"
  defp tone_class("warning"), do: "text-warning"
  defp tone_class(_default), do: "text-base-content"

  # `scope` is the personalization hook: the host passes the viewer's scope, so
  # a widget can address the current user. Always pattern-match defensively.
  defp viewer_name(%{user: %{email: email}}) when is_binary(email) do
    email |> String.split("@") |> List.first()
  end

  defp viewer_name(_scope), do: default_who()

  defp default_who, do: Gettext.gettext(PhoenixKitWeb.Gettext, "world")

  defp compact?(%{h: h}) when is_integer(h), do: h < 2
  defp compact?(_size), do: false
end
