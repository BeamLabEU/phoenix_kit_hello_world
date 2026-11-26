defmodule PhoenixKitHelloWorld.Web.CSP do
  @moduledoc """
  The module's one door to core's Content-Security-Policy support
  (`PhoenixKitWeb.CSP`). **Copy this file with the rest of the template.**

  A host may run a policy that allows inline code by nonce only
  (`script-src 'self' 'nonce-…'`). The policy is the host's; a module only has
  to work under it. Three rules do that:

  1. **An inline `<style>` or `<script>` carries the page's nonce:**

         <style nonce={PhoenixKitHelloWorld.Web.CSP.nonce(:style)}>
         <script nonce={PhoenixKitHelloWorld.Web.CSP.nonce(:script)}>

     (A script that registers a LiveView hook or holds real logic does not
     belong in a template at all: ship it through `js_sources/0`.)

  2. **No inline event handlers** (`onclick="…"`, `onerror="…"`): no nonce can
     cover an attribute. Use a `phx-` binding or `Phoenix.LiveView.JS`, or a
     hook / delegated listener in the module's own bundle, keyed on an
     attribute of the module's own (`data-my-module-copy`, not core's
     `data-pk-*`, which older cores do not listen for).

  3. **A LiveView another page embeds with `live_render/3` restores the
     nonces itself:** it is its own process and skips the live session's
     `on_mount`, so it adds `on_mount PhoenixKitHelloWorld.Web.CSP` (see
     `Web.ProjectHelloTabLive`). The embedding page hands the nonces over in
     the session (core's `PhoenixKitWeb.CSP.nested_session/1`). Routed views
     get core's own `on_mount` from the live session and need nothing.

  ## Why a wrapper and not a direct call

  `PhoenixKitWeb.CSP` is newer than this module's core floor. A direct
  `PhoenixKitWeb.CSP.nonce(:style)` would not compile against the floor, and
  raising the floor for it would lock out every host on an older core. So the
  call is **feature-detected**: on a core without the module `nonce/1` answers
  `nil` (HEEx renders no attribute for `nonce={nil}`, exactly the old markup)
  and the `on_mount` does nothing. It goes through `apply/3`, which both the
  compiler (`--warnings-as-errors`) and dialyzer accept on either core.
  Once the floor in `mix.exs` reaches a core that has `PhoenixKitWeb.CSP`,
  this file can be deleted and its callers can name core directly.

  This template renders no inline `<style>` or `<script>` of its own, so
  `nonce/1` has no caller here; a module copied from it starts with the helper
  in place. `test/csp_inline_tags_test.exs` fails on an inline tag without the
  nonce and on any inline handler: copy that too.
  """

  @core PhoenixKitWeb.CSP

  @type kind :: :script | :style

  @doc """
  The page's nonce for `kind`, or `nil`: the host set none, or the installed
  core has no nonce support.
  """
  @spec nonce(kind) :: String.t() | nil
  def nonce(kind) when kind in [:script, :style] do
    case core(:nonce, [kind], nil) do
      value when is_binary(value) and value != "" -> value
      _ -> nil
    end
  end

  @doc false
  # `on_mount PhoenixKitHelloWorld.Web.CSP` in a view embedded with
  # `live_render/3`: restores the nonces the embedding page put in the session.
  def on_mount(_arg, params, session, socket) do
    core(:on_mount, [:default, params, session, socket], {:cont, socket})
  end

  # The one call into core. `apply/3`, because the core floor has no such
  # module: a direct call would fail the compiler and dialyzer there.
  defp core(function, args, default) do
    if Code.ensure_loaded?(@core) and function_exported?(@core, function, length(args)) do
      apply(@core, function, args)
    else
      default
    end
  end
end
