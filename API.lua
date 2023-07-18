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