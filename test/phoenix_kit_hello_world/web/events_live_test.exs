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
    test "renders the page heading and total counter", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/events")

      # C5 delta: heading + total are gettext-wrapped now
      assert html =~ "Activity Events"
      assert html =~ "0 events"
    end

    test "shows the empty state when no events recorded", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/events")

      # C5 delta: empty-state text wrapped in gettext
      assert html =~ "No events recorded yet"
      assert html =~ "Head back to the Overview page"
    end
  end

  describe "filter form (C5 delta — gettext-wrapped labels)" do
    test "renders gettext-wrapped Action label and Clear button", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/events")

      # `>Action<` matches because <span> renders Action with no surrounding
      # whitespace. `>Clear<` would NOT match because the button uses
      # multi-line HEEX so there's `>\n  Clear\n</button>`. Match the
      # button by its phx-click target instead.
      assert html =~ ">Action</span>"
      assert html =~ ~r/phx-click="clear_filters"[^>]*>\s*Clear\s*</s
      assert html =~ "All Actions"
    end
  end
end
