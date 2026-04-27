defmodule PhoenixKitHelloWorld.Web.ComponentsLiveTest do
  @moduledoc """
  Smoke + delta-pinning tests for the Components showcase.

  The most important test here is the **section count**: PR #12's
  decomposition split a 742-line `render/1` into 22 per-section
  function components. If a future edit removes a section from
  `render/1` while leaving the `defp` in place (or vice versa), the
  count test fails.
  """
  use PhoenixKitHelloWorld.LiveCase

  describe "mount" do
    test "renders the page heading and section count (PR #12 pinning test)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/components")

      assert html =~ "PhoenixKit Components"

      # `<.showcase_section>` renders `<section class="card bg-base-100 shadow-xl">`.
      # The Phase 1 decomposition emits exactly 22 of these. If a section is
      # accidentally removed from `render/1` (or its `defp x_section/1` is
      # deleted), this count drops and the test fails.
      section_count = count_substring(html, ~s|<section class="card bg-base-100 shadow-xl">|)
      assert section_count == 22, "expected 22 showcase sections, found #{section_count}"
    end

    test "renders all major category labels", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/components")

      # A representative sample of section titles. Picking the ones whose
      # absence would clearly indicate a missing section function.
      for title <- [
            "Icons",
            "Badges",
            "Buttons",
            "Alerts",
            "Stat cards",
            "Form inputs",
            "Modals",
            "Tables",
            "Pagination",
            "Empty states",
            "Loading states",
            "Collapsible sections",
            "Nav tabs",
            "Number formatter",
            "Time display",
            "File display",
            "Language switcher",
            "PhoenixKit links",
            "Form helpers",
            "Draggable list",
            "Components not shown here"
          ] do
        assert html =~ title,
               "expected section titled #{inspect(title)} in rendered components page"
      end
    end

    test "section dividers render with their gettext labels", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/en/admin/hello-world/components")

      assert html =~ "PhoenixKit Core Components"
      assert html =~ "Context-dependent components"
    end

    test "modal toggles state without crashing", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/en/admin/hello-world/components")

      # The modals_section snippet `<details>` block contains the literal
      # text "modal-open" as a code example, so a simple substring match
      # always matches. Pin the actual rendered class on the dialog
      # element instead.
      #
      # Phoenix's `class={["modal", false]}` renders as `class="modal "`
      # (trailing space where the false falls out), so the closed-state
      # regex allows whitespace before the closing quote.

      # Open the basic daisyUI modal
      rendered = render_click(view, "open_modal", %{})
      assert rendered =~ ~r/<dialog class="modal modal-open"/

      # Close
      rendered = render_click(view, "close_modal", %{})
      refute rendered =~ ~r/<dialog class="modal modal-open"/
      assert rendered =~ ~r/<dialog class="modal\s*"/
    end

    test "confirm modal flow increments the counter and flashes", %{conn: conn} do
      {:ok, view, html} = live(conn, "/en/admin/hello-world/components")

      assert html =~ "counter: 0"

      rendered = render_click(view, "open_confirm", %{})
      assert rendered =~ "Confirm action"

      rendered = render_click(view, "confirmed", %{})
      assert rendered =~ "counter: 1"
      assert rendered =~ "Confirmed! Counter is now 1"
    end

    test "nav_tabs state changes on switch_tab", %{conn: conn} do
      {:ok, view, html} = live(conn, "/en/admin/hello-world/components")

      assert html =~ "Active tab: <strong>overview"

      rendered = render_click(view, "switch_tab", %{"tab" => "settings"})
      assert rendered =~ "Active tab: <strong>settings"
    end

    test "switch_tab silently ignores unknown tab IDs (input validation)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/en/admin/hello-world/components")

      rendered = render_click(view, "switch_tab", %{"tab" => "evil"})

      # State unchanged — still on the default "overview"
      assert rendered =~ "Active tab: <strong>overview"
      refute rendered =~ "Active tab: <strong>evil"
    end

    test "reorder_items rejects mismatched id list (input validation)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/en/admin/hello-world/components")

      # Send only 2 IDs (assigns has 6 items — should reject)
      rendered = render_click(view, "reorder_items", %{"ordered_ids" => ["1", "2"]})

      # Original order preserved — first item still id=1
      assert rendered =~ "Item 1"
      assert rendered =~ "Item 6"
    end

    test "reorder_items accepts a valid permutation", %{conn: conn} do
      {:ok, view, html} = live(conn, "/en/admin/hello-world/components")

      assert html =~ ~r/Item 1.*Item 2.*Item 3/s

      rendered =
        render_click(view, "reorder_items", %{
          "ordered_ids" => ["6", "5", "4", "3", "2", "1"]
        })

      # New order — Item 6 appears before Item 1
      assert rendered =~ ~r/Item 6.*Item 5.*Item 1/s
    end

    test "handle_info catch-all swallows unknown messages (Batch 2)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/en/admin/hello-world/components")

      # Without the catch-all, sending an unknown message crashes the LV
      # with FunctionClauseError on the next render. With it, the LV
      # stays alive and the page re-renders normally.
      send(view.pid, :unknown_pubsub_event)
      send(view.pid, {:something, :random, "payload"})

      html = render(view)
      assert is_binary(html)
      assert html =~ "PhoenixKit Components"
    end
  end

  defp count_substring(string, substring) do
    string
    |> String.split(substring)
    |> length()
    |> Kernel.-(1)
  end
end
