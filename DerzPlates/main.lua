-- References:
-- https://www.wowhead.com/guide/addon-writing-guide-a-basic-introduction-by-example-1949
-- https://old.reddit.com/r/worldofpvp/comments/tyim5i/small_lua_script_to_change_the_nameplate_color_of/
-- https://wowwiki-archive.fandom.com/wiki/Event_API
-- https://wowwiki-archive.fandom.com/wiki/Events_A-Z_(full_list)
-- https://cdn.wowinterface.com/forums/showthread.php?t=36061
-- https://www.wowinterface.com/forums/showthread.php?t=34248
-- https://wowpedia.fandom.com/wiki/API_UnitThreatSituation
-- https://wowpedia.fandom.com/wiki/API_UnitDetailedThreatSituation
-- https://github.com/Gethe/wow-ui-source/blob/10.2.0/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlates.lua
-- https://wowpedia.fandom.com/wiki/Secure_Execution_and_Tainting
-- https://github.com/Pondidum/WowInterfakes/blob/master/wow-ui-source/FrameXML/CompactUnitFrame.lua

local statusText = {
	[0] = "(0) low on threat",
	[1] = "(1) high threat",
	[2] = "(2) primary target but not on high threat",
	[3] = "(3) primary target and high threat",
}

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
	-- Check if the player is currently tanking the name plate's unit.
	local status = UnitThreatSituation("player", frame.unit)

	local name, _ = UnitName(frame.unit)
	if status ~= nil then
		print(name, "is", statusText[status])
	end

	if status == 2 or status == 3 then
		-- If they ARE tanking this unit, set the plate's color to magenta.
		frame.healthBar:SetStatusBarColor(1, 0, 1, 1)
	else
		print("not tanking, leaving default:", name)
	end
end)

-- Create the addon "frame" object for handling events.
local frame = CreateFrame("Frame")

-- Run the script whenever a new name plate becomes visible.
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

-- Run the script whenever the player enters combat.
frame:RegisterEvent("PLAYER_REGEN_DISABLED")

-- Run the script whenever a combat log event occurs.
frame:RegisterEvent("COMBAT_LOG_EVENT")

-- When combat happens, run the main addon loop.
frame:SetScript("OnEvent", function(self, event, frame)
	-- Iterate over all currently-visible name plates.
	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		local unitFrame = namePlate.UnitFrame

		-- Check if the player is currently tanking the name plate's unit.
		local status = UnitThreatSituation("player", unitFrame.unit)

		local name, _ = UnitName(unitFrame.unit)
		if status ~= nil then
			print(name, "is", statusText[status])
		end

		if status == 2 or status == 3 then
			-- If they ARE tanking this unit, set the plate's color to magenta.
			unitFrame.healthBar:SetStatusBarColor(1, 0, 1, 1)
		end
	end
end)
