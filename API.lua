-- [[ Namespaces ]] --
local addonName, addon = ...;

do --[[ KrowiV_InjectOptions ]]
	KrowiMFE_InjectOptions = {};

    function KrowiMFE_InjectOptions:SetOptionsTable(optionsTable)
        self.OptionsTable = optionsTable;
    end

	function KrowiMFE_InjectOptions:AddTable(destTablePath, key, table)
		local destTable;
		if type(destTablePath) == "table" then
			destTable = destTablePath;
		elseif type(destTablePath) == "string" then
			destTable = self.OptionsTable.args;
			local pathParts = strsplittable(".", destTablePath);
			for _, part in next, pathParts do
				destTable = destTable[part];
			end
		end
		destTable[key] = table;
		return destTable[key];
	end

	function KrowiMFE_InjectOptions:GetTable(destTablePath)
		local destTable = self.OptionsTable.args;
		local pathParts = strsplittable(".", destTablePath);
		for _, part in next, pathParts do
			destTable = destTable[part];
		end
		return destTable;
	end

	function KrowiMFE_InjectOptions:TableExists(destTablePath)
		local destTable = KrowiMFE_InjectOptions:GetTable(destTablePath)
		return destTable and true or false;
	end

	-- function KrowiV_InjectOptions:DeleteTable(destTablePath)
	-- 	local destTable = self.OptionsTable.args;
	-- 	local pathParts = strsplittable(".", destTablePath);
	-- 	for _, part in next, pathParts do
	-- 		destTable = destTable[part];
	-- 	end
	-- 	destTable = nil;
	-- end

    function KrowiMFE_InjectOptions:SetOptions(options)
        self.Options = options;
    end

	function KrowiMFE_InjectOptions:AddDefaults(destTablePath, key, table)
		local destTable = self.Options;
		local pathParts = strsplittable(".", destTablePath);
		for _, part in next, pathParts do
			destTable = destTable[part];
		end
		destTable[key] = table;
	end

	function KrowiMFE_InjectOptions:DefaultsExists(destTablePath)
		local destTable = self.Options;
		local pathParts = strsplittable(".", destTablePath);
		for _, part in next, pathParts do
			destTable = destTable[part];
		end
		return destTable and true or false;
	end

	local autoOrder = 1;
	function KrowiMFE_InjectOptions.AutoOrderPlusPlus(amount)
		local current = autoOrder;
		autoOrder = autoOrder + (1 or amount);
		return current;
	end

	function KrowiMFE_InjectOptions.PlusPlusAutoOrder(amount)
		autoOrder = autoOrder + (1 or amount);
		return autoOrder;
	end

	function KrowiMFE_InjectOptions.AdjustedWidth(number)
		return (number or 1) * addon.Options.WidthMultiplier;
	end

	local OrderPP = KrowiMFE_InjectOptions.AutoOrderPlusPlus;
	function KrowiMFE_InjectOptions.AddPluginTable(pluginName, pluginDisplayName, desc, loadedFunc)
		return KrowiMFE_InjectOptions:AddTable("Plugins.args", pluginName, {
			type = "group",
			name = pluginDisplayName,
			args = {
				Loaded = {
					order = OrderPP(), type = "toggle", width = "full",
					name = addon.L["Loaded"],
					desc = addon.L["Loaded Desc"],
					descStyle = "inline",
					get = loadedFunc,
					disabled = true
				},
				Line = {
					order = OrderPP(), type = "header", width = "full",
					name = ""
				},
				Description = {
					order = OrderPP(), type = "description", width = "full",
					name = desc,
					fontSize = "medium"
				}
			}
		}).args;
	end
end

do --[[ KrowiV_RegisterAutoJunkOptions ]]
    local function InjectOptionsDefaults(expansion, instanceId, junkByDefault)
		if junkByDefault == nil then
			junkByDefault = false;
		end
		if not KrowiMFE_InjectOptions:DefaultsExists("AutoJunk.Instances") then
			KrowiMFE_InjectOptions:AddDefaults("AutoJunk", "Instances", { });
		end
		KrowiMFE_InjectOptions:AddDefaults("AutoJunk.Instances", instanceId, junkByDefault);
	end

    local OrderPP = KrowiMFE_InjectOptions.AutoOrderPlusPlus;
	local AdjustedWidth = KrowiMFE_InjectOptions.AdjustedWidth;
	local function InjectOptionsTable(expansion, expansionDisplayName, instanceType, instanceTypeDisplayName, instanceId, instanceDisplayName)
        if not KrowiMFE_InjectOptions:TableExists("AutoJunk.args." .. expansion) then
			KrowiMFE_InjectOptions:AddTable("AutoJunk.args", expansion, {
				order = OrderPP(), type = "group",
				name = expansionDisplayName,
				args = {}
			});
		end
		if not KrowiMFE_InjectOptions:TableExists("AutoJunk.args." .. expansion .. ".args." .. instanceType) then
			KrowiMFE_InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args", instanceType, {
				order = OrderPP(), type = "group", inline = true,
				name = instanceTypeDisplayName,
				args = {}
			});
		end
		KrowiMFE_InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", tostring(instanceId), {
			order = OrderPP(), type = "toggle", width = AdjustedWidth(0.95),
			name = instanceDisplayName,
			get = function() return addon.Options.db.AutoJunk.Instances[instanceId]; end,
			set = function()
				addon.Options.db.AutoJunk.Instances[instanceId] = not addon.Options.db.AutoJunk.Instances[instanceId];
                addon.Data.AutoJunk.EnableForInstanceId();
            end
		});
	end

    function KrowiV_RegisterAutoJunkOptions(expansion, expansionDisplayName, instanceType, instanceTypeDisplayName, instanceId, instanceDisplayName, junkByDefault)
        InjectOptionsDefaults(expansion, instanceId, junkByDefault);
        InjectOptionsTable(expansion, expansionDisplayName, instanceType, instanceTypeDisplayName, instanceId, instanceDisplayName);
    end

    function KrowiAF_RegisterDeSelectAllEventOptions(expansion, instanceType, instanceIds)
		if KrowiMFE_InjectOptions:TableExists("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args.SelectAll") then
			return;
		end

		KrowiMFE_InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", "Blank1", {
			order = OrderPP(), type = "description", width = "full", name = ""
		});
		KrowiMFE_InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", "Blank2", {
			order = OrderPP(), type = "description", width = AdjustedWidth(0.95), name = ""
		});
		KrowiMFE_InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", "SelectAll", {
			order = OrderPP(), type = "execute", width = AdjustedWidth(0.95),
			name = addon.L["Select All"],
			func = function()
				for _, instanceId in next, instanceIds do
					addon.Options.db.AutoJunk.Instances[instanceId] = true;
				end
                addon.Data.AutoJunk.EnableForInstanceId();
			end
		});
		KrowiMFE_InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", "DeselectAll", {
			order = OrderPP(), type = "execute", width = AdjustedWidth(0.95),
			name = addon.L["Deselect All"],
			func = function()
				for _, instanceId in next, instanceIds do
					addon.Options.db.AutoJunk.Instances[instanceId] = nil;
				end
                addon.Data.AutoJunk.EnableForInstanceId();
			end
		});
	end
end