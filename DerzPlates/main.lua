-- References:
-- https://www.wowhead.com/guide/addon-writing-guide-a-basic-introduction-by-example-1949
-- https://old.reddit.com/r/worldofpvp/comments/tyim5i/small_lua_script_to_change_the_nameplate_color_of/
-- https://wowwiki-archive.fandom.com/wiki/Event_API
-- https://wowwiki-archive.fandom.com/wiki/Events_A-Z_(full_list)
-- https://cdn.wowinterface.com/forums/showthread.php?t=36061
-- https://www.wowinterface.com/forums/showthread.php?t=34248
-- https://wowpedia.fandom.com/wiki/API_UnitReaction
-- https://wowpedia.fandom.com/wiki/API_UnitThreatSituation
-- https://wowpedia.fandom.com/wiki/API_UnitDetailedThreatSituation
-- https://wowpedia.fandom.com/wiki/Secure_Execution_and_Tainting
-- https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_NamePlates/Vanilla/Blizzard_NamePlates.lua
-- https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_UnitFrame/Classic/CompactUnitFrame.lua
-- https://www.wowinterface.com/forums/showthread.php?p=344701

local statusText = {
	[0] = "(0) low on threat",
	[1] = "(1) high threat",
	[2] = "(2) primary target but not on high threat",
	[3] = "(3) primary target and high threat",
}

-- -- Create the addon "frame" object for handling events.
-- local frame = CreateFrame("Frame")

-- -- Run the script whenever a new name plate becomes visible.
-- frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

-- -- Run the script whenever the player enters combat.
-- frame:RegisterEvent("PLAYER_REGEN_DISABLED")

-- -- Run the script whenever a combat log event occurs.
-- frame:RegisterEvent("COMBAT_LOG_EVENT")

-- -- When combat happens, run the main addon loop.
-- frame:SetScript("OnEvent", function(self, event, frame)
-- 	NamePlateDriverFrame.UpdateAllHealthColor()
-- 	print("frame", NamePlateDriverFrame)
-- 	print("dot", NamePlateDriverFrame.UpdateAllHealthColor)
-- 	-- print("colon", NamePlateDriverFrame:UpdateAllHealthColor)
-- 	-- print("method", NamePlateDriverFrame:UpdateAllHealthColor)
-- 	-- Iterate over all currently-visible name plates.
-- 	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
-- 		local unitFrame = namePlate.UnitFrame

-- 		-- Check if the name plate's unit is neutral (needed for default colors).
-- 		local reaction = UnitReaction(unitFrame.unit, "player")
-- 		local isNeutral = reaction == 4

-- 		-- Check if the player is currently tanking the name plate's unit.
-- 		local status = UnitThreatSituation("player", unitFrame.unit)

-- 		local name, _ = UnitName(unitFrame.unit)
-- 		if status ~= nil then
-- 			print(name, "is", statusText[status])
-- 		end

-- 		if status == 2 or status == 3 then
-- 			-- If they ARE tanking this unit, set the plate's color to magenta.
-- 			unitFrame.healthBar:SetStatusBarColor(1, 0, 1, 1)
-- 		elseif isNeutral then
-- 			-- Otherwise, if the unit is neutral, set the plate's color to yellow.
-- 			unitFrame.healthBar:SetStatusBarColor(1, 1, 0, 1)
-- 		else
-- 			-- Lastly, default the plate's color to red.
-- 			unitFrame.healthBar:SetStatusBarColor(1, 0, 0, 1)
-- 		end
-- 	end
-- end)

-- https://github.com/Gethe/wow-ui-source/blob/e696432cf6c1dcf18036590b64b11c975d8f9fb9/Interface/AddOns/Blizzard_UnitFrame/Classic/CompactUnitFrame.lua#L394-L396
local function CUF_UpdateHealthColorOverride(self)
	-- Prefer displayedUnit but fallback to unit if necessary.
	local unit = self.displayedUnit or self.unit

	-- Don't change the nameplate color for players.
	if UnitIsPlayer(unit) then
		return false
	end

	-- Don't change the nameplate color to units you cannot attack.
	if not UnitCanAttack(unit) then
		return false
	end

	-- Check if the player is currently tanking the name plate's unit.
	local status = UnitThreatSituation("player", unit)

	-- DEBUG
	local name, _ = UnitName(unit)
	if status ~= nil then
		print("UpdateHealthColorOverride:", name, "is", statusText[status])
	end

	if status == 2 or status == 3 then
		-- If they ARE tanking this unit, set the plate's color to magenta.
		self.healthBar:SetStatusBarColor(1, 0, 1)
		-- Overwrite saved color so CompactUnitFrame_UpdateHealthColor() can restore the default later.
		self.healthBar.r, self.healthBar.g, self.healthBar.b = 1, 0, 1
		-- Signal CompactUnitFrame_UpdateHealthColor() that we set the color ourselves and return immediately.
		return true
	end

	-- If we got here, we want CompactUnitFrame_UpdateHealthColor() to set its default color.
	return false
end

print("Loading DerzPlates")

print("Hooking AcquireUnitFrame...")
-- Override the NamePlateDriver.AcquireUnitFrame function to set the frame's UpdateHealthColorOverride.
-- https://github.com/Gethe/wow-ui-source/blob/e696432cf6c1dcf18036590b64b11c975d8f9fb9/Interface/AddOns/Blizzard_NamePlates/Vanilla/Blizzard_NamePlates.lua#L89
hooksecurefunc(NamePlateDriverFrame, "AcquireUnitFrame", function(_, base)
	-- Operating on forbidden frames will throw errors, so we need to ignore them.
	if base:IsForbidden() then
		return
	end

	-- DEBUG
	print("AcquireUnitFrame")
 
	-- Called by CompactUnitFrame_UpdateHealthColor(), return true when color is
	-- overridden or false when you want the default color applied.
	base.UnitFrame.UpdateHealthColorOverride = CUF_UpdateHealthColorOverride
end)
print("Hooked AcquireUnitFrame")

print("Hooking UpdateUnitEvents...")
-- By default, the Classic WoW UI code skips registering the UNIT_THREAT_LIST_UPDATE
-- unit event. However, since we want to react to that event (to check threat status),
-- we need to re-enable it.
-- https://github.com/Gethe/wow-ui-source/blob/e696432cf6c1dcf18036590b64b11c975d8f9fb9/Interface/AddOns/Blizzard_UnitFrame/Classic/CompactUnitFrame.lua#L233
hooksecurefunc("CompactUnitFrame_UpdateUnitEvents", function(self)
	-- Operating on forbidden frames will throw errors, so we need to ignore them.
	if base:IsForbidden() then
		return
	end

	-- DEBUG
	print("UpdateUnitEvents")
 
	-- Re-enable UNIT_THREAT_LIST_UPDATE
	self:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", self.unit, self.unit ~= self.displayedUnit and self.displayedUnit or nil)
end)
print("Hooked UpdateUnitEvents")

print("Hooking OnEvent...")
-- Whenever a UNIT_THREAT_LIST_UPDATE event occurs,
-- https://github.com/Gethe/wow-ui-source/blob/e696432cf6c1dcf18036590b64b11c975d8f9fb9/Interface/AddOns/Blizzard_UnitFrame/Classic/CompactUnitFrame.lua#L59
hooksecurefunc("CompactUnitFrame_OnEvent", function(self, event, ...)
	-- Operating on forbidden frames will throw errors, so we need to ignore them.
	if base:IsForbidden() then
		return
	end

	-- DEBUG
	if event == "UNIT_THREAT_LIST_UPDATE"  then
		print("UNIT_THREAT_LIST_UPDATE", event, ...)
	end
 
	-- TODO: What is "..."? It must be the unit receiving the event.
	if event == "UNIT_THREAT_LIST_UPDATE" and ((...) == self.unit or (...) == self.displayedUnit) then
		-- Update color when threat list updates (calls .UpdateHealthColorOverride())
		CompactUnitFrame_UpdateHealthColor(self)
	end
end)
print("Hooked OnEvent")

print("Loaded DerzPlates")
