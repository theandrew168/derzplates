-- References:
-- https://www.wowhead.com/guide/addon-writing-guide-a-basic-introduction-by-example-1949
-- https://old.reddit.com/r/worldofpvp/comments/tyim5i/small_lua_script_to_change_the_nameplate_color_of/
-- https://wowwiki-archive.fandom.com/wiki/Event_API
-- https://wowwiki-archive.fandom.com/wiki/Events_A-Z_(full_list)

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT")
frame:SetScript("OnEvent", function(self, event, frame)
	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		local unitFrame = namePlate.UnitFrame
		if unitFrame:IsForbidden() then return end

		isTanking, _, _, _, _ = UnitDetailedThreatSituation("player", unitFrame.unit)
		if isTanking then
			unitFrame.healthBar:SetStatusBarColor(1, 0, 1, 1)
		end
	end
end)
