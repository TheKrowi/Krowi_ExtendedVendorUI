# Intent: Plumber's Merchant Price hides the token banner
Author: hemmshoe, clicket, guino2377 and a player at Hallow's End on CurseForge (project 872787), collected by Krowi (maintainer). Source: GitHub issue #100 (reopened 2026-10-25), Plumber issue [#533](https://github.com/Peterodox/Plumber/issues/533). Status: accepted

## Problem
Since 23.0 (2026-10-21), Retail players with Plumber's Merchant Price module on see only their gold at the bottom right of the vendor window, and none of the currencies or items the vendor charges. One player went back to 22.2 to get them. At the candy vendor, a player saw a "coin" with the addon on and the candy with it off. The cause is Plumber: Merchant Price hides the bar the token banner sits in and draws its own box. Since 23.0 that box can no longer see the vendor's items, so it shows only gold. The addon's banner, which shows every cost of the list, stays hidden. Turning off only Merchant Price brings it back, but nothing tells the player that.

## Proposed outcome
- A player whose banner is hidden by Plumber's Merchant Price is told so once a session, at the first vendor: a notice window and a chat line saying how to get the banner back (turn off Merchant Price in Plumber's settings).
- The addon does not change its banner or work around Plumber (Krowi, 2026-10-25). The findings are on Plumber's issue #533.

## Affected users and systems
- Clients: Retail and WoW Forever, the only clients where Plumber loads Merchant Price.
- Windows: the vendor window (merchant tab), a new notice window, the chat frame.
- Options and saved variables: none new. Reads Plumber's account-wide saved variable `PlumberDB` (`MerchantPrice`).
- Other addons: Plumber 1.9.6 d (Merchant Price is off by default, so only players who turned it on are affected).
- Localization: one new string.

## Constraints
- Taint: the addon only reads a Blizzard frame (`GetParent`) and writes nothing Blizzard owns.
- The notice must not show without Plumber, with Merchant Price off, or once Plumber stops hiding the bar.
- WoW Forever's gamepad interface style: no window that needs the mouse to close (as for the existing Forever notice).
- No change on the other clients.

## Open questions
None. Answered in the spec's Decision (2026-10-25): also a Plugins page entry, a zhCN draft on CurseForge, and no change to the description.
