# Plugin System

> Sources: Krowi-Frostmane EU, 2026-02-20
> Raw: [Krowi's Extended Vendor UI — Codebase Analysis](../../raw/krowi-extended-vendor-ui/krowi-extended-vendor-ui-codebase.md)

## Overview

Krowi's Extended Vendor UI provides a lightweight plugin registration system (`Api/PluginsApi.lua`) that allows third-party addons to hook into KEVU's initialization, event handling, localization, and options panel. Two first-party plugins ship with the addon: CanIMogIt integration and ElvUI skinning.

## Plugin Registration API (Api/PluginsApi.lua)

### RegisterPlugin(pluginName, plugin)
Adds a plugin table to the internal `Plugins` registry. The plugin name is used as a display key.

### RegisterEvent(event)
Creates a shared event frame and routes the WoW event to all registered plugins via each plugin's `OnEvent` method (if defined).

### LoadPluginLocalization(L)
Iterates all plugins and calls `plugin:LoadLocalization(L)` passing the addon locale table. Used to let plugins add their own strings to `addon.L`.

### InjectPluginOptions()
Calls `plugin:InjectOptions()` on each plugin. This is the hook point for injecting option entries into the AceConfig Plugins options tab.

### LoadPlugins()
Calls `plugin:Load()` on each plugin. Invoked near the end of the main ADDON_LOADED handler.

## Plugin Interface

All methods are optional. A plugin table may implement any subset:

| Method | Signature | Called When |
|---|---|---|
| OnEvent | plugin:OnEvent(event, ...) | A registered WoW event fires |
| LoadLocalization | plugin:LoadLocalization(L) | Localization load phase |
| InjectOptions | plugin:InjectOptions() | Before options panel is shown |
| Load | plugin:Load() | ADDON_LOADED handler |

## First-Party Plugin: CanIMogIt

File: `Plugins/CanIMogIt.lua`

Integrates with the [CanIMogIt](https://www.curseforge.com/wow/addons/can-i-mog-it) addon which overlays transmog collection status icons on item buttons.

**Problem:** When KEVU applies a filter, the merchant items are remapped to new display slots. CanIMogIt's overlay icons don't automatically reposition to match the new layout.

**Solution:** Hooks `MerchantFrame_SetFilter`. After any filter change, waits 0.1 seconds (via `C_Timer.After`) then calls `MerchantFrame_CIMIOnClick` — CanIMogIt's internal refresh function — to force icon re-evaluation on the current filtered layout.

**InjectOptions:** Adds a plugin entry in the KEVU options panel describing the CanIMogIt integration.

## First-Party Plugin: ElvUI

File: `Plugins/ElvUI.lua`

Full ElvUI skin integration. All skinning is conditional: checks `ElvUI` global is loaded AND the relevant skin setting is enabled in ElvUI's config.

### Skinned Components

| Component | Technique |
|---|---|
| Merchant item buttons (Modern) | Strip textures, create transparent backdrop, reposition price/name text and item icon, apply ElvUI border style |
| Merchant item buttons (Classic) | Same approach with Classic-specific frame offsets |
| Filter button | `HandleDropDownBox` |
| Search box | `HandleEditBox` + height adjustment |
| Options button (Classic) | `HandleButton` |
| Token Banner | `StripTextures` + transparent backdrop |
| Repair buttons | Hook into `UpdateRepairButtons` |

Quest icons are disabled on skinned item buttons (ElvUI uses its own icon textures). A hook on the slot update function ensures newly created slot frames (beyond the initial pool) also receive skinning.

**IsLoaded():** Returns true only when `ElvUI` global exists and the merchant skin is enabled in ElvUI's settings.

**InjectOptions:** Adds an ElvUI entry in the Plugins options tab.

## Public API (Api/Api.lua)

Exposes one global for external addon use:

```lua
KrowiEVU_MerchantItemsContainer  -- alias for addon.Gui.MerchantItemsContainer
```

This is consumed by [Vendorer](https://www.curseforge.com/wow/addons/vendorer) to integrate with KEVU's grid layout.

## UtilApi (Api/UtilApi.lua)

Exposes `addon.InjectOptions` as `KrowiEVU.UtilApi.InjectOptions` for external callers that need to inject options outside the plugin system.

## See Also

- [Overview and Architecture](overview-and-architecture.md)
- [Options and Configuration](options-and-configuration.md) — Plugins options tab
- [GUI Components](gui-components.md) — OptionsButton receives plugin-injected menu sections
