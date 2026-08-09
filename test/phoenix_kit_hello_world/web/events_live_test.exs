defmodule PhoenixKitHelloWorld.Web.EventsLiveTest do
  @moduledoc """
  Smoke + delta-pinning tests for the Hello World events feed.

  EventsLive reads from `phoenix_kit_activities` directly via
  `PhoenixKit.Activity.list/1`. The empty-state path is the one we
  pin here — testing populated lists requires cross-process sandbox
  visibility for rows seeded from the test process to be visible to
  the LiveView's process. The activity_logging test in
  `hello_live_test.exs` covers the populated path end-to-end via the
  same process (button click → activity row → flash assertion).
  """
  use PhoenixKitHelloWorld.LiveCase

  describe "mount" do
    test "renders the total counter", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/events")

      # C5 delta: total is gettext-wrapped now
      assert html =~ "0 events"
    end

    test "renders no page-level header or width cap (issue #23)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/events")

      # `page_title` is rendered once by the admin layout. The page must not
      # render a second in-body title, and must not cap the page-level wrapper.
      refute html =~ "Activity Events"
      refute html =~ "<h2"
      assert html =~ ~s|<div class="flex flex-col px-4 py-6 gap-4">|
    end

    test "shows the empty state when no events recorded", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/events")

      # C5 delta: empty-state text wrapped in gettext.
      # Issue #23 delta: rendered by core's `<.empty_state>`, not hand-rolled.
      assert html =~ "No events recorded yet"
      assert html =~ "Head back to the Overview page"
    end
  end

  describe "infinite scroll (issue #24)" do
    test "uses core's InfiniteScroll hook, not a page-local inline script", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/events")

      # The old inline <script> registered `HelloWorldInfiniteScroll` from
      # inside render/1, so it never executed when the page was reached via
      # `navigate/2`. Core's `InfiniteScroll` hook ships in PhoenixKit's own
      # JS bundle instead, so it is registered on every page load.
      refute html =~ "HelloWorldInfiniteScroll"
      refute html =~ "<script"

      source = File.read!("lib/phoenix_kit_hello_world/web/events_live.ex")
      assert source =~ "import PhoenixKitWeb.Components.Core.Pagination, only: [load_more: 1]"
      assert source =~ ~s|id="events-load-more"|
    end
  end

  describe "filter form (C5 delta — gettext-wrapped labels)" do
    test "renders gettext-wrapped Action label and Clear button", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/events")

      # Issue #27 delta: the filter is core's `<.select>` now, which renders
      # its label through `FormFieldLabel.label/1` — a multi-line
      # `<span class="label-text ...">`, so match it with whitespace slack
      # rather than the old `>Action</span>` exact form. `>Clear<` likewise
      # would NOT match because the button uses multi-line HEEX; match the
      # button by its phx-click target instead.
      assert html =~ ~r/class="label-text[^"]*">\s*Action\s*<\/span>/
      assert html =~ ~r/phx-click="clear_filters"[^>]*>\s*Clear\s*</s
      assert html =~ "All Actions"
    end

    test "filter uses core's <.select>, not a hand-rolled <select> (issue #27)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/events")

      # `<.select>` wires the feedback container and the id/name pairing for
      # us — a raw `<select name="filter[action]">` has neither.
      assert html =~ ~s|phx-feedback-for="filter[action]"|
      assert html =~ ~s|id="filter-action"|

      source = File.read!("lib/phoenix_kit_hello_world/web/events_live.ex")
      assert source =~ "import PhoenixKitWeb.Components.Core.Select, only: [select: 1]"
      refute source =~ ~s|<select name="filter[action]">|
    end

    test "detail-link title literal is wrapped in Gettext.gettext (Batch 2 delta)" do
      # Empty list → no entries → no detail link rendered, so we can't
      # assert against rendered HTML. Instead pin the wrap directly by
      # reading the module source: a regression that drops the wrap
      # would re-introduce a bare `title="View details"` literal.
      source = File.read!("lib/phoenix_kit_hello_world/web/events_live.ex")

      refute source =~ ~s(title="View details"),
             "expected `title=\"View details\"` to be wrapped in Gettext.gettext/2"

      assert source =~
               ~s|title={Gettext.gettext(PhoenixKitWeb.Gettext, "View details")}|
    end
  end

  describe "handle_info catch-all (Batch 2 — defensive)" do
    test "swallows unknown OTP messages without crashing", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/en/admin/hello-world/events")

      send(view.pid, :unknown_pubsub_event)
      send(view.pid, {:something, :random, "payload"})

      html = render(view)
      assert is_binary(html)
      assert html =~ "0 events"
    end
  end
end
