### Added
- Support for WoW 12.0.0 (Midnight)

### Changed
- Columns menu presets now start at 2 (removed 1-column preset)

### Fixed
- Token Banner now uses `C_MerchantFrame.GetItemInfo` instead of deprecated `GetMerchantItemInfo` for better compatibility

### Mists Classic
- Added `C_MerchantFrame.GetItemInfo` polyfill for Classic versions that lack this API
- Housing Quantity menu is now hidden

### WoW Classic
- Added `C_MerchantFrame.GetItemInfo` polyfill for Classic versions that lack this API
- Housing Quantity menu is now hidden