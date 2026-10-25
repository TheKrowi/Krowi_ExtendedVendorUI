local _, addon = ...
local L = addon.Localization.NewLocale("zhCN")
if not L then return end

KrowiEVU.PluginsApi:LoadPluginLocalization(L)

-- [[ 此行之后的所有内容均由 CurseForge 自动生成，请勿手动编辑 - SOURCETOKEN - AUTOGENTOKEN ]] --

-- [[ Exported at 2026-10-25 09-47-27 ]] --
L["Are you sure you want to hide the options button?"] = [=[是否隐藏设置按钮？
可在此重新显示：主菜单 → 选项 → 插件 → {addonName} → {general} → {options}]=]
L["Arsenals"] = "军械库"
L["Both"] = "全显示"
L["Bulk Purchase"] = "批量购买"
L["Buy"] = "购买"
L["Columns"] = "列数"
L["Columns first"] = "优先按列排列"
L["Custom"] = "自定义"
L["Default filters"] = "默认筛选器"
L["Deselect All"] = "取消全选"
L["Direction"] = "排列方向"
L["Enable bulk purchase"] = "启用批量购买"
L["Enable bulk purchase Desc"] = "Shift+点击商人物品以打开批量购买窗口。"
L["Ensembles"] = "家具"
L["Enter housing quantity"] = "输入住宅装饰数量 (1-999):"
L["Enter number of columns"] = "输入列数 (2-99):"
L["Enter number of rows"] = "输入行数 (1-99):"
L["Filters"] = "筛选器"
L["ForeverGamepadNotLoaded"] = "Extended Vendor UI 无法与 WoW Forever 的手柄界面同时使用，因此未加载。如需使用，请在游戏选项的手柄页面关闭手柄界面，然后输入 /reload。"
L["ForeverGamepadReload"] = "WoW Forever 的手柄界面已开启，Extended Vendor UI 无法与其同时使用。输入 /reload 以使用暴雪的商人窗口。"
L["Gear"] = "装备"
L["Gold total"] = "金币总计"
L["Have"] = "已拥有"
L["Hide collected"] = "隐藏已收集物品"
L["Hide currencies you have none of"] = "隐藏未拥有的货币"
L["Hide sub-optimal armor"] = "隐藏非最佳护甲类型"
L["Housing"] = "住宅装饰"
L["Housing Quantity"] = "住宅装饰数量"
L["Icon Left click"] = "打开商人窗口选项"
L["Icon Right click"] = "打开设置选项"
L["Illusions"] = "幻象（实验性）"
L["Max"] = "最大"
L["Maximum purchase"] = "最大购买数量"
L["Minimum quality"] = "最低品质"
L["Mounts"] = "坐骑"
L["Need"] = "未拥有"
L["Only show"] = "仅显示"
L["Only usable items"] = "仅显示可用物品"
L["Options button"] = "设置按钮"
L["Options Desc"] = "通过商人窗口右上方的设置按钮也能打开选项设置。"
L["Other"] = "其他"
L["Partial stack"] = "不满一组"
L["Pets"] = "宠物"
L["Plugin_CanIMogIt_Desc"] = [=[此插件修复了应用不同筛选条件时，物品图标叠加显示问题。

此插件无设置项。]=]
L["Plugin_CanIMogIt_Name"] = "Can I Mog It"
L["Plugin_EllesmereUI_Desc"] = [=[此插件为商人物品应用 EllesmereUI 的商人皮肤并显示物品等级。

此插件无设置项。]=]
L["Plugin_EllesmereUI_ListModeNotLoaded"] = [=[Extended Vendor UI 无法与 EllesmereUI 的商人列表模式同时使用，因此未加载。

如需使用 Extended Vendor UI，请在 EllesmereUI 的商人选项中关闭 Show As List（列表显示）。]=]
L["Plugin_EllesmereUI_Name"] = "EllesmereUI"
L["Plugin_ElvUI_Desc"] = [=[以下各项设置均由 ElvUI 控制，仅作信息展示。

如需修改这些设置，请前往游戏菜单 -> ElvUI -> 皮肤，并勾选所需选项。可参考下方各选项说明确认需勾选的内容。]=]
L["Plugin_ElvUI_Name"] = "ElvUI"
L["Plugin_ElvUI_SkinMerchant"] = "商人界面皮肤"
L["Plugin_ElvUI_SkinMerchant_Desc"] = [=[为商人窗口应用 ElvUI 皮肤。
-> 暴雪界面 + 商人窗口]=]
L["Plugin_ElvUI_SkinMiscFrames"] = "杂项窗口皮肤"
L["Plugin_ElvUI_SkinMiscFrames_Desc"] = [=[为筛选菜单和设置菜单应用 ElvUI 皮肤。
-> 暴雪界面 + 杂项窗口]=]
L["Plugin_ElvUI_SkinTooltip"] = "提示框皮肤"
L["Plugin_ElvUI_SkinTooltip_Desc"] = [=[为提示框应用 ElvUI 皮肤。
-> 暴雪界面 + 提示框]=]
L["Plugin_GW2UI_Desc"] = [=[此插件为商人物品应用 GW2 UI 的商人皮肤。

此插件无设置项。]=]
L["Plugin_GW2UI_Name"] = "GW2 UI"
L["Plugin_Plumber_Desc"] = [=[当 Plumber 的商品价格模块隐藏代币窗口时，此插件会在每次登录后的第一个商人处提示你。开启商品价格后，商人窗口底部只显示你的金币。

如需再次查看列表中物品的花费，请在 Plumber 的设置中关闭商品价格。

此插件无设置项。]=]
L["Plugin_Plumber_MerchantPriceHidesTokenBanner"] = "Plumber 的商品价格模块隐藏了 Extended Vendor UI 的代币窗口，因此商人窗口只显示你的金币。如需再次查看列表中物品的花费，请在 Plumber 的设置中关闭商品价格。"
L["Plugin_Plumber_Name"] = "Plumber"
L["Plugin_TransmogLootHelper_Desc"] = [=[此插件在翻页、更改筛选或搜索时，更新 Transmog Loot Helper 在商人物品上的图标叠加。需要 Transmog Loot Helper 12.1.5-02 或更高版本。

此插件无设置项。]=]
L["Plugin_TransmogLootHelper_Name"] = "Transmog Loot Helper"
L["Recipes"] = "配方"
L["Recipes my other characters know"] = "我的其他角色已学会的配方"
L["RememberFilter"] = "记住筛选条件"
L["RememberSearch"] = "记住搜索内容"
L["RememberSearchBetweenVendors"] = "保存搜索历史"
L["Rows"] = "行数"
L["Rows first"] = "优先按行排列"
L["Select All"] = "全选"
L["Set custom"] = "自定义设置"
L["Show Hide option"] = "菜单添加'{hide}'选项"
L["Show Hide option Desc"] = "在[{optionsButton}]菜单中添加[{hide}]选项。"
L["Show options button"] = "显示设置按钮"
L["Show options button Desc"] = "显示/隐藏商人窗口中的设置按钮。"
L["Show purchase confirmation"] = "显示购买确认"
L["Show purchase confirmation Desc"] = "购买超过一组时显示确认对话框。"
L["Stack"] = "一组"
L["Stack purchase"] = "按组购买"
L["Stack size"] = "每组数量"
L["Token Banner"] = "代币窗口"
L["Token Format"] = "代币格式"
L["Toys"] = "玩具"
L["Vendor has"] = "商人库存"
L["You can afford"] = "可负担"
L["You can fit"] = "背包可容纳"