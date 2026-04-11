## 0.1.3 - 2026-04-11

### Added
- Add Events subtab with infinite-scroll activity feed filtered to `module: "hello_world"` — universal pattern that works as a drop-in for any module
- Add Components subtab showcasing commonly-used PhoenixKit core components (icons, badges, buttons, alerts, stat cards, form inputs, modals, tables, pagination, empty states, loading states) with copy-paste snippets
- Add "Log demo event" button on Overview page demonstrating the canonical activity logging pattern with `Code.ensure_loaded?/1` guard and rescue handling
- Add `PhoenixKitHelloWorld.Paths` module for centralized path helpers

### Changed
- Restructure `admin_tabs/0` to include parent tab + three subtabs (Overview, Events, Components)
- Bump `phoenix_live_view` dep from `~> 1.0` to `~> 1.1` for consistency with other PhoenixKit modules
- Update `HelloLive` with navigation to the new subtabs and activity logging demo
- Update AGENTS.md with activity logging pattern documentation and expanded file layout

## 0.1.2 - 2026-04-05

### Added
- Add `required_integrations/0` and `integration_providers/0` callbacks to template
- Add tests for new integration callbacks

## 0.1.1 - 2026-04-04

### Fixed
- Fix auto-discovery by adding `phoenix_kit` to `extra_applications`

### Changed
- Update AGENTS.md with standardized sections and auto CSS source compiler docs

## 0.1.0 - 2026-03-24

### Added
- Initial PhoenixKit module template with `PhoenixKit.Module` behaviour
- Admin LiveView page with status dashboard and user info
- Route module template for multi-page modules
- Implement `css_sources/0` for Tailwind CSS scanning support
- Add test infrastructure with dual-level testing (unit + integration)
- Add behaviour compliance test suite
- Comprehensive README documentation covering all PhoenixKit module patterns
