defmodule PhoenixKitHelloWorldTest do
  use ExUnit.Case

  # These tests verify that the module correctly implements the
  # PhoenixKit.Module behaviour. Copy and adapt them for your own module.

  describe "behaviour implementation" do
    test "implements PhoenixKit.Module" do
      behaviours =
        PhoenixKitHelloWorld.__info__(:attributes)
        |> Keyword.get_values(:behaviour)
        |> List.flatten()

      assert PhoenixKit.Module in behaviours
    end

    test "has @phoenix_kit_module attribute for auto-discovery" do
      attrs = PhoenixKitHelloWorld.__info__(:attributes)
      assert Keyword.get(attrs, :phoenix_kit_module) == [true]
    end
  end

  describe "required callbacks" do
    test "module_key/0 returns a non-empty string" do
      key = PhoenixKitHelloWorld.module_key()
      assert is_binary(key)
      assert key == "hello_world"
    end

    test "module_name/0 returns a non-empty string" do
      name = PhoenixKitHelloWorld.module_name()
      assert is_binary(name)
      assert name == "Hello World"
    end

    test "enabled?/0 returns a boolean" do
      # In test env without DB, this returns false (the rescue fallback)
      assert is_boolean(PhoenixKitHelloWorld.enabled?())
    end

    test "enable_system/0 is exported" do
      assert function_exported?(PhoenixKitHelloWorld, :enable_system, 0)
    end

    test "disable_system/0 is exported" do
      assert function_exported?(PhoenixKitHelloWorld, :disable_system, 0)
    end
  end

  describe "permission_metadata/0" do
    test "returns a map with required fields" do
      meta = PhoenixKitHelloWorld.permission_metadata()
      assert %{key: key, label: label, icon: icon, description: desc} = meta
      assert is_binary(key)
      assert is_binary(label)
      assert is_binary(icon)
      assert is_binary(desc)
    end

    test "key matches module_key" do
      meta = PhoenixKitHelloWorld.permission_metadata()
      assert meta.key == PhoenixKitHelloWorld.module_key()
    end

    test "icon uses hero- prefix" do
      meta = PhoenixKitHelloWorld.permission_metadata()
      assert String.starts_with?(meta.icon, "hero-")
    end
  end

  describe "admin_tabs/0" do
    test "returns a list of Tab structs" do
      tabs = PhoenixKitHelloWorld.admin_tabs()
      assert is_list(tabs)
      assert length(tabs) == 1
    end

    test "tab has all required fields" do
      [tab] = PhoenixKitHelloWorld.admin_tabs()
      assert tab.id == :admin_hello_world
      assert tab.label == "Hello World"
      assert String.starts_with?(tab.path, "/admin")
      assert tab.level == :admin
      assert tab.permission == PhoenixKitHelloWorld.module_key()
      assert tab.group == :admin_modules
    end

    test "tab has live_view for route generation" do
      [tab] = PhoenixKitHelloWorld.admin_tabs()
      assert {PhoenixKitHelloWorld.Web.HelloLive, :index} = tab.live_view
    end

    test "path uses hyphens not underscores" do
      [tab] = PhoenixKitHelloWorld.admin_tabs()
      refute String.contains?(tab.path, "_")
    end
  end

  describe "version/0" do
    test "returns a version string" do
      version = PhoenixKitHelloWorld.version()
      assert is_binary(version)
      assert version == "0.1.0"
    end
  end

  describe "optional callbacks have defaults" do
    test "get_config/0 returns a map" do
      config = PhoenixKitHelloWorld.get_config()
      assert is_map(config)
      assert Map.has_key?(config, :enabled)
    end

    test "settings_tabs/0 returns empty list" do
      assert PhoenixKitHelloWorld.settings_tabs() == []
    end

    test "user_dashboard_tabs/0 returns empty list" do
      assert PhoenixKitHelloWorld.user_dashboard_tabs() == []
    end

    test "children/0 returns empty list" do
      assert PhoenixKitHelloWorld.children() == []
    end

    test "route_module/0 returns nil" do
      assert PhoenixKitHelloWorld.route_module() == nil
    end
  end
end
