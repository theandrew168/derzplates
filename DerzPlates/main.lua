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

-- Write a custom implementation of the CompactUnitFrame_UpdateHealthColorOverride function.
-- This gets called immediately when CompactUnitFrame_UpdateHealthColor gets called to alter
-- the nameplate's color. If our override function returns false, then the default coloring
-- code with run. If it returns true, our logic will run instead.
--
-- Reference:
-- https://github.com/Gethe/wow-ui-source/blob/e696432cf6c1dcf18036590b64b11c975d8f9fb9/Interface/AddOns/Blizzard_UnitFrame/Classic/CompactUnitFrame.lua#L394-L396
local function UpdateHealthColorOverride(self)
	-- Prefer displayedUnit but fallback to unit if necessary.
	local unit = self.displayedUnit or self.unit

	-- Don't change the nameplate color for players.
	if UnitIsPlayer(unit) then
		return false
	end

	-- Don't change the nameplate color to units you cannot attack.
	if not UnitCanAttack("player", unit) then
		return false
	end

	-- Check if the player is currently tanking the name plate's unit.
	local status = UnitThreatSituation("player", unit)
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

-- Override the NamePlateDriver.AcquireUnitFrame function to set the frame's UpdateHealthColorOverride.
--
-- Reference:
-- https://github.com/Gethe/wow-ui-source/blob/e696432cf6c1dcf18036590b64b11c975d8f9fb9/Interface/AddOns/Blizzard_NamePlates/Vanilla/Blizzard_NamePlates.lua#L89
hooksecurefunc(NamePlateDriverFrame, "AcquireUnitFrame", function(_, base)
	-- Operating on forbidden frames will throw errors, so we need to ignore them.
	if base:IsForbidden() then
		return
	end

	-- Called by CompactUnitFrame_UpdateHealthColor(), return true when color is
	-- overridden or false when you want the default color applied.
	base.UnitFrame.UpdateHealthColorOverride = UpdateHealthColorOverride
end)

-- By default, the Classic WoW UI code skips registering the UNIT_THREAT_LIST_UPDATE
-- unit event. However, since we want to react to that event (to check threat status),
-- we need to re-enable it.
--
-- Reference:
-- https://github.com/Gethe/wow-ui-source/blob/e696432cf6c1dcf18036590b64b11c975d8f9fb9/Interface/AddOns/Blizzard_UnitFrame/Classic/CompactUnitFrame.lua#L233
hooksecurefunc("CompactUnitFrame_UpdateUnitEvents", function(self)
	-- Operating on forbidden frames will throw errors, so we need to ignore them.
	if self:IsForbidden() then
		return
	end

	-- Re-enable UNIT_THREAT_LIST_UPDATE
	self:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", self.unit, self.unit ~= self.displayedUnit and self.displayedUnit or nil)
end)

-- Whenever a UNIT_THREAT_LIST_UPDATE event occurs for the nameplate's unit,
-- rerun the frame's CompactUnitFrame_UpdateHealthColor function (which will,
-- in turn, call our custom override function).
--
-- Reference:
-- https://github.com/Gethe/wow-ui-source/blob/e696432cf6c1dcf18036590b64b11c975d8f9fb9/Interface/AddOns/Blizzard_UnitFrame/Classic/CompactUnitFrame.lua#L59
hooksecurefunc("CompactUnitFrame_OnEvent", function(self, event, ...)
	-- Operating on forbidden frames will throw errors, so we need to ignore them.
	if self:IsForbidden() then
		return
	end

	-- For the event(s) we care about, the nameplate's unit is the first event arg.
	local unit, _, _, _ = ...

	-- If the event is threat-related and the affected unit frame is "self", call
	-- CompactUnitFrame_UpdateHealthColor to re-update the frame's health color.
	if event == "UNIT_THREAT_LIST_UPDATE" and (unit == self.unit or unit == self.displayedUnit) then
		-- Update color when threat list updates (calls .UpdateHealthColorOverride())
		CompactUnitFrame_UpdateHealthColor(self)
	end
end)
