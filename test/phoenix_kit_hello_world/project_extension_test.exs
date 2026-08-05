defmodule PhoenixKitHelloWorld.ProjectExtensionTest do
  @moduledoc """
  Pins the reference `phoenix_kit_project_extensions/0` contract entry.

  This module is the ecosystem's copyable example of the projects-hub
  extension contract (the analogue of the `phoenix_kit_widgets/0` reference
  above it) — these tests keep the reference honest: every contract field
  present, the tab LV off-router-mountable, and NO dependency on
  `phoenix_kit_projects` (the contract is duck-typed one-way).
  """

  use ExUnit.Case, async: true

  test "exports the duck-typed provider with a full-contract entry" do
    assert function_exported?(PhoenixKitHelloWorld, :phoenix_kit_project_extensions, 0)

    assert [ext] = PhoenixKitHelloWorld.phoenix_kit_project_extensions()

    # Every contract field is demonstrated (the reference's job).
    for field <- [
          :key,
          :name,
          :description,
          :icon,
          :module_key,
          :tabs,
          :config_schema,
          :feature_flags,
          :permission_actions,
          :notification_types,
          :on_enable,
          :on_disable,
          :default_enabled
        ] do
      assert Map.has_key?(ext, field), "reference entry is missing #{inspect(field)}"
    end

    assert ext.key == "hello_world_tab"
    assert ext.module_key == "hello_world"
    assert ext.default_enabled == false
  end

  test "the tab LV mounts off-router from session alone (the hub's render mode)" do
    assert [%{tabs: [%{lv: lv}]}] = PhoenixKitHelloWorld.phoenix_kit_project_extensions()
    assert Code.ensure_loaded?(lv)

    # The hub mounts tab LVs via live_render (:not_mounted_at_router):
    # exporting handle_params/3 would make Phoenix refuse the mount — the
    # exact trap phoenix_kit_projects' embedding_audit documents.
    refute function_exported?(lv, :handle_params, 3)
    assert function_exported?(lv, :mount, 3)
    assert function_exported?(lv, :render, 1)
  end

  test "the provider does not depend on phoenix_kit_projects" do
    deps = Mix.Project.config()[:deps] |> Enum.map(&elem(&1, 0))
    refute :phoenix_kit_projects in deps
  end
end
