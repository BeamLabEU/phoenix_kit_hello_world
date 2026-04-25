defmodule PhoenixKitHelloWorld.Web.HelloLiveTest do
  @moduledoc """
  Smoke + delta-pinning tests for the Hello World overview page.

  The "Log demo event" button gates on `Scope.has_module_access?(scope,
  "hello_world")`, which checks `cached_permissions`. Tests that need
  the button visible call `put_test_scope(conn, fake_scope(...))`
  before `live/2`.
  """
  use PhoenixKitHelloWorld.LiveCase

  describe "mount" do
    test "renders the landing page", %{conn: conn} do
      conn = put_test_scope(conn, fake_scope())

      {:ok, _view, html} = live(conn, "/en/admin/hello-world")

      assert html =~ "Hello World Plugin"
      assert html =~ "Module Info"
      assert html =~ "Current User"
    end

    test "without scope, the demo button is hidden and a permission warning shows",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world")

      refute html =~ "Log demo event"
      assert html =~ "permission to log events"
    end

    test "with module access, the demo button is rendered", %{conn: conn} do
      conn = put_test_scope(conn, fake_scope(permissions: ["hello_world"]))

      {:ok, _view, html} = live(conn, "/en/admin/hello-world")

      assert html =~ "Log demo event"
    end
  end

  describe "phx-disable-with attr (C5 delta)" do
    test "Log demo event button has phx-disable-with set", %{conn: conn} do
      conn = put_test_scope(conn, fake_scope(permissions: ["hello_world"]))

      {:ok, _view, html} = live(conn, "/en/admin/hello-world")

      # The button must carry phx-disable-with so double-clicks don't
      # double-log activity. This regex pins C5's fix on the button —
      # if the attr is removed, this test fails.
      assert html =~ ~r/phx-click="log_demo_event"[^>]*phx-disable-with/s or
               html =~ ~r/phx-disable-with=[^>]*phx-click="log_demo_event"/s
    end
  end

  describe "log demo event flow" do
    test "click logs an activity row with the canonical action + actor", %{conn: conn} do
      scope = fake_scope(permissions: ["hello_world"])
      user_uuid = scope.user.uuid

      conn = put_test_scope(conn, scope)
      {:ok, view, _html} = live(conn, "/en/admin/hello-world")

      rendered = render_click(view, "log_demo_event", %{})

      # Flash text appears (verifies C7 flash rendering + C5 gettext-wrap)
      assert rendered =~ "Demo event logged — check the Events tab!"

      # Activity row landed with the right shape (pins canonical pattern + C9 helper)
      assert_activity_logged("hello_world.demo_event",
        actor_uuid: user_uuid,
        metadata_has: %{"source" => "showcase_button"}
      )
    end

    test "click without module access flashes the permission error", %{conn: conn} do
      # No scope — the button is hidden in the template, but we can still
      # trigger the event (it's a server-side handler) to verify the gate
      # behaves correctly under hostile input.
      {:ok, view, _html} = live(conn, "/en/admin/hello-world")

      rendered = render_click(view, "log_demo_event", %{})

      assert rendered =~ "permission to log events"
      refute_activity_logged("hello_world.demo_event")
    end
  end

  describe "navigation" do
    test "renders links to Events and Components subpages", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world")

      assert html =~ "Events feed"
      assert html =~ "Components showcase"
    end
  end
end
