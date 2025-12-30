# Changelog
All notable changes to this project will be documented in this file.

## 19.0 - 2025-12-31
### Added
- Full ElvUI support

## 18.0 - 2025-12-30
### Added
- Remember search option: Keep search text when reopening the same vendor
- Remember search between vendors option: Keep search text across different vendors
- Options button positioned next to search box for quick access

### Changed
- Search functionality with "Search" filter option to search for items by name
- Improved UI element positioning and sizing logic for search box and options button
- Updated filter button to use localized strings instead of global strings
- Enhanced search box behavior with proper filter restoration

### Fixed
- Search box now properly clears when switching between non-search filters
- Options button and search box visibility when switching between merchant info and buyback modes
- Filter button positioning adjustments based on column count

## 17.0 - 2025-12-29
### Change
- Menu generation and handling (dev note: for classic user this should be an invisible change; for mainline users this should reflect in modern looking drop down menus)

## 16.3 - 2025-12-27
### Fixed
- Pop up dialogs should work again

## 16.2 - 2025-12-25
### Mists Classic
- Removed The Merchant Window now remembers your last selected filter between vendor visits; Can be toggled in the options

### WoW Classic
- Removed The Merchant Window now remembers your last selected filter between vendor visits; Can be toggled in the options

## 16.1 - 2025-12-25
### Fixed
- Removed rogue print

## 16.0 - 2025-12-23
### Added
- The Merchant Window now remembers your last selected filter between vendor visits; Can be toggled in the options

## 15.2 - 2025-12-08
### Fixed
- Missing reference

## 15.1 - 2025-12-08
### Changed
- Packaging

## 15.0 - 2025-12-03
### Added
- Filter Housing items with an option to select when housing items are considered collected based on quantity (1-10)

## 14.4 - 2025-11-24
### Added
- Credits

## 14.3 - 2025-11-03
### Fixed
- Links in the pop up window should once again be full length

## 14.2 - 2025-07-05
### Fixed
- Removed unwanted print statements to the chat window

## 14.1 - 2025-07-05
### Mists Classic
- Resolved an ElvUI compatibility issue

### WoW Classic
- Disabled recipe filtering

## 14.0 - 2025-07-02
### Mists Classic
- Added support
- Removed pet filtering option

### Cata Classic
- Removed support

## 13.3 - 2025-05-25
### Cata Classic
- Disabled pet filtering

### WoW Classic
- Disabled pet filtering

## 13.2 - 2025-05-20
### Cata Classic
- Disabled recipe filtering

### WoW Classic
- Disabled recipe filtering

## 13.1 - 2025-05-15
### Added
- Added Russian translation

### Fixed
- The 3 new extra tokens should now also align to the right of the window

## 13.0 - 2025-04-22
### Added
- Illusions can now also be filtered

## 12.1 - 2025-03-31
### Fixed
- Compatibility issue with TSM

## 12.0 - 2025-03-01
### Added
- Transmog sets likes ensembles and arsenals can now also filtered
- Addon category

## 11.1 - 2025-02-14
### Cata Classic
- Silver Shafted Arrow and Truesilver Shafted Arrow are no longer considered pets

## 11.0 - 2025-01-18
### Cata Classic
- First port from retail

### WoW Classic
- First port from retail

## 10.1 - 2025-01-02
### Fixed
- Some text localizations

## 10.0 - 2025-01-02
### Added
- More filters for transmogs

### Fixed
- Items considered mounts should once again behave

## 9.1 - 2024-12-23
### Fixed
- Removed unwanted recipe ids printed to the chat window

## 9.0 - 2024-12-18
### Added
- Show the hide button option in the options button
- Recipes filters

## 8.6 - 2024-10-27
### Fixed
- Removed unwanted item ids printed to the chat window

## 8.5 - 2024-10-27
### Added
- Italian localization

### Fixed
- Dorothy (alliance) and Chub (horde) no longer classify the Magic Broom as a mount

## 8.4 - 2024-10-26
### Fixed
- Vendor items should once again have the correct name, icon and price when filters are applied

## 8.3 - 2024-09-07
### Added
- Simplified Chinese localization and missing French text

## 8.2 - 2024-09-07
### Fixed
- The options button should (finally) remember to stay hidden

## 8.1 - 2024-08-15
### Fixed
- Library bug

## 8.0 - 2024-07-24
### Fixed
- Several bugs due to The War Within changes

## 7.0 - 2024-04-04
### Added
- Transmog filters

## 6.3 - 2024-03-23
### Fixed
- NPCs that have items with incorrect data should no longer throw errors

## 6.2 - 2024-01-06
### Added
- CIMI compatibility

### Fixed
- Alt currencies should now have the correct tooltip
- Check if an item is a pet is now more reliable

## 6.1 - 2023-11-20
### Fixed
- Any potential errors that would occur when using both KAF and KEVU

## 6.0 - 2023-11-20
### Added
- Hide collected pets filter
- Hide collected mounts filter
- Hide collected toys filter
- Custom filter to show a combination of items
- Search field

### Fixed
- Sell All Junk Items button now stays on the left side of the window
- Auctionator compatibility
- Torghast should no longer throw errors
- Extra currency slot is now also anchored to the right of the window

## 5.1 - 2023-09-06
### Fixed
- Removed the not existing UndoFrame

## 5.0 - 2023-09-04
### Changed
- Optimized exports
- Updated Util lib

## 4.0 - 2023-08-15
### Added
- Implemented proper handling of profile change, copy and reset

## 3.0 - 2023-08-14
### Added
- Left clicking the minimap icon or addon compartment record now opens the options for the vendor window

### Changed
- Renamed the addon from Krowi's Merchant Frame Extended to Krowi's Extended Vendor UI

## 2.1 - 2023-08-11
### Changed
- Updated Util lib

## 2.0 - 2023-08-09
### Added
- Now uses the Addon compartment (minimap button is still available for those who use it)
- Introduced Profiles

### Changed
- Lots of backend code is now shared between all my addons

## 1.0 - 2023-07-22
### Added
- First release
- Adjust the Merchant Window's number of rows and columns and the direction the items should be shown
- Options can now be changed from the full options menu
- The options button can now be hidden