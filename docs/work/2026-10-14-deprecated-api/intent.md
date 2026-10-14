# Intent: Stop reading deprecated Blizzard globals
Author: Krowi (maintainer), from a deprecated-API scan across their addons. Source: idea. Status: accepted

## Problem
Nothing is broken for players today. But WoW 12.1.5 just deleted a batch of deprecated globals, which broke Krowi's Vendorer, and Extended Vendor UI still names old globals in two files: the bulk purchase window keeps fallbacks to the pre-C_Container and pre-C_Item globals, and the merchant filter menu calls `GetSpecializationInfo`, which Retail only keeps as a deprecated alias. When Blizzard deletes that alias, the spec filters in the merchant filter menu will error on Retail.

## Proposed outcome
Extended Vendor UI calls only the current APIs, so the next deprecation cleanup does not break it on any client it supports.

## Affected users and systems
Players on all four clients the TOC lists (Retail 12.0.7, Mists 5.5.4, Anniversary 2.5.6, Era 1.15.9): the bulk purchase window and, on Retail, the class and spec entries of the merchant filter menu.

## Constraints
No visible change on any client. No change to the bulk purchase maths or the filter values.

## Open questions
None.