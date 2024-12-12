-- References:
-- https://www.wowhead.com/guide/addon-writing-guide-a-basic-introduction-by-example-1949
-- https://old.reddit.com/r/worldofpvp/comments/tyim5i/small_lua_script_to_change_the_nameplate_color_of/
-- https://wowwiki-archive.fandom.com/wiki/Event_API
-- https://wowwiki-archive.fandom.com/wiki/Events_A-Z_(full_list)

-- Create the addon "frame" object for handling events.
local frame = CreateFrame("Frame")

-- Run the script whenever the player enters combat.
frame:RegisterEvent("PLAYER_ENTER_COMBAT")

-- Run the script whenever a combat log event occurs.
frame:RegisterEvent("COMBAT_LOG_EVENT")

-- When combat happens, run the main addon loop.
frame:SetScript("OnEvent", function(self, event, frame)
	-- Iterate over all currently-visible name plates.
	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		local unitFrame = namePlate.UnitFrame

		-- Check if the player is currently tanking the name plate's unit.
		isTanking, _, _, _, _ = UnitDetailedThreatSituation("player", unitFrame.unit)
		if isTanking then
			-- If they ARE tanking this unit, set the plate's color to magenta.
			unitFrame.healthBar:SetStatusBarColor(1, 0, 1, 1)
		end
	end
end)
