Fury.SwingTimer = {}

--------------------------------------------------------------------------------
-- Local Variables
--------------------------------------------------------------------------------
local weapon = nil
local offhand = nil
local combat = false
local player_guid = nil
local player_class = nil
local flurry_mult = 0
local flurry_fresh = nil
local flurry_count = -1
local wf_swings = 0

-- Timer variables (exposed globally for DecisionTree access)
FurySwingTimer = 0
FurySwingTimerMax = 1
FurySwingTimerOff = 0
FurySwingTimerOffMax = 1

local flurry = {
	WARRIOR = {10, 15, 20, 25, 30},
	SHAMAN  = { 8, 11, 14, 17, 20},
}

local combatStrings = {
	SPELLLOGSELFOTHER,			-- Your %s hits %s for %d.
	SPELLLOGCRITSELFOTHER,		-- Your %s crits %s for %d.
	SPELLDODGEDSELFOTHER,		-- Your %s was dodged by %s.
	SPELLPARRIEDSELFOTHER,		-- Your %s is parried by %s.
	SPELLMISSSELFOTHER,			-- Your %s missed %s.
	SPELLBLOCKEDSELFOTHER,		-- Your %s was blocked by %s.
	SPELLDEFLECTEDSELFOTHER,	-- Your %s was deflected by %s.
	SPELLEVADEDSELFOTHER,		-- Your %s was evaded by %s.
	SPELLIMMUNESELFOTHER,		-- Your %s failed. %s is immune.
	SPELLLOGABSORBSELFOTHER,	-- Your %s is absorbed by %s.
	SPELLREFLECTSELFOTHER,		-- Your %s is reflected back by %s.
	SPELLRESISTSELFOTHER		-- Your %s was resisted by %s.
}
for index in combatStrings do
	for _, pattern in {"%%s", "%%d"} do
		combatStrings[index] = string.gsub(combatStrings[index], pattern, "(.*)")
	end
end

local loc = {}
loc["enUS"] = {
	hit = "You hit",
	crit = "You crit",
	glancing = "glancing",
	block = "blocked",
	Warrior = "Warrior",
	combatSpells = {
		HS = "Heroic Strike",
		Cleave = "Cleave",
		RS = "Raptor Strike",
		Maul = "Maul",
	}
}
loc["deDE"] = {
	hit = "Ihr trefft",
	crit = "Ihr trefft",
	glancing = "gestreift",
	block = "geblockt",
	Warrior = "Krieger",
	combatSpells = {
		HS = "Heldenhafter Stoß",
		Cleave = "Spalten",
		RS = "Raptorschlag",
		Maul = "Zermalmen",
	}
}
local L = loc[GetLocale()]
if (L == nil) then 
	L = loc['enUS']
end

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

local function GetWeaponSpeed(off)
	local speedMH, speedOH = UnitAttackSpeed("player")
	if off then
		return speedOH
	else
		return speedMH
	end
end

local function isDualWield()
	return (GetWeaponSpeed(true) ~= nil)
end

local function UpdateWeapon()
	weapon = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"))
	if (isDualWield()) then
		offhand = GetInventoryItemLink("player", GetInventorySlotInfo("SecondaryHandSlot"))
	end
end

local function ResetTimer(off)
	if not off then
		FurySwingTimerMax = GetWeaponSpeed(off)
		FurySwingTimer = GetWeaponSpeed(off)
	else
		FurySwingTimerOffMax = GetWeaponSpeed(off)
		FurySwingTimerOff = GetWeaponSpeed(off)
	end
end

-- flurry check
local function CheckFlurry()
	local c = 0
	while GetPlayerBuff(c,"HELPFUL") ~= -1 do
		local id = GetPlayerBuffID(c)
		if SpellInfo(id) == "Flurry" then
			return GetPlayerBuffApplications(c)
		end
		c = c + 1
	end
	return -1
end

local function GetFlurry(class)
	-- default multiplier
	flurry_mult = 1.3

	for page = 1, 3 do
		for talent = 1, 100 do
			local name, _, _, _, count = GetTalentInfo(page, talent)
			if not name then break end
			if name == "Flurry" then
				if count == 0 then
					flurry_mult = 1
				else
					flurry_mult = 1 + (flurry[class][count] or 0) / 100
				end
				return
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

function Fury.SwingTimer:OnEvent(event)
	if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
		_,player_guid = UnitExists("player")
		_,player_class = UnitClass("player")
		if UnitAffectingCombat('player') then 
			combat = true 
		else 
			combat = false 
		end

		GetFlurry(player_class)
		CheckFlurry()
		
	elseif event == "PLAYER_REGEN_DISABLED" then
		combat = true
		wf_swings = 0
		CheckFlurry()
		
	elseif event == "CHARACTER_POINTS_CHANGED" then
		GetFlurry(player_class)
		
	elseif event == "UNIT_CASTEVENT" and arg1 == player_guid then
		local spell = SpellInfo(arg4)

		-- wf proc happens first, then the normal hit, then the 1-2 wf hits
		if (arg4 == 51368 or arg4 == 16361) then
			wf_swings = wf_swings + ((arg4 == 51368) and 1 or 2)
			return
		end

		if spell == "Flurry" then
			-- track a completely fresh flurry for timing
			flurry_fresh = flurry_count < 1
			flurry_count = 3
			return
		end

		if arg4 == 6603 then -- autoattack
			if arg3 == "MAINHAND" then
				ResetTimer(false)

				if flurry_fresh then -- fresh flurry, decrease the swing cooldown of the next swing
					FurySwingTimer = FurySwingTimer / flurry_mult
					FurySwingTimerMax = FurySwingTimerMax / flurry_mult
					flurry_fresh = false
				end
				if flurry_count == 0 then -- used up last flurry
					FurySwingTimer = FurySwingTimer * flurry_mult
					FurySwingTimerMax = FurySwingTimerMax * flurry_mult
				end
			elseif arg3 == "OFFHAND" then
				ResetTimer(true)

				if flurry_fresh then -- fresh flurry, decrease the swing cooldown of the next swing
					FurySwingTimerOff = FurySwingTimerOff / flurry_mult
					FurySwingTimerOffMax = FurySwingTimerOffMax / flurry_mult
					flurry_fresh = false
				end
				if flurry_count == 0 then -- used up last flurry
					FurySwingTimerOff = FurySwingTimerOff * flurry_mult
					FurySwingTimerOffMax = FurySwingTimerOffMax * flurry_mult
				end
			end
			
			if wf_swings > 0 then
				wf_swings = wf_swings - 1
			else
				flurry_count = flurry_count - 1 -- normal swing occured, reduce flurry counter
			end
			return
			
		end

		-- check for attacks that take the place of autoattack
		for _,v in L['combatSpells'] do
			if spell == v and arg3 == "CAST" then
				ResetTimer(false)
				if flurry_fresh then
					FurySwingTimer = FurySwingTimer / flurry_mult
					FurySwingTimerMax = FurySwingTimerMax / flurry_mult
				end
				if flurry_count == 0 then -- used up last flurry
					FurySwingTimer = FurySwingTimer * flurry_mult
					FurySwingTimerMax = FurySwingTimerMax * flurry_mult
				end
				flurry_count = flurry_count - 1 -- swing occured, reduce flurry counter
				return
			end
		end

	elseif event == "UNIT_INVENTORY_CHANGED" then
		if (arg1 == "player") then
			local oldWep = weapon
			local oldOff = offhand

			UpdateWeapon()
			if (combat and oldWep ~= weapon) then
				ResetTimer(false)
			end

			if offhand then
				local _,_,itemId = string.find(offhand,"item:(%d+)")
				local _name,_link,_,_lvl,wep_type,_subtype,_ = GetItemInfo(itemId)
				if (combat and isDualWield() and ((oldOff ~= offhand) and (wep_type and wep_type == "Weapon"))) then
					ResetTimer(true)
				end
			end
		end

	elseif (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES") or 
	       (event == "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE") or 
	       (event == "CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES") or 
	       (event == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE") then
		if (string.find(arg1, ".* attacks. You parry.")) or (string.find(arg1, ".* was parried.")) then
			-- Only the upcoming swing gets parry haste benefit
			if (isDualWield()) then
				if FurySwingTimerOff < FurySwingTimer then
					local minimum = GetWeaponSpeed(true) * 0.20
					local reduct = GetWeaponSpeed(true) * 0.40
					FurySwingTimerOff = FurySwingTimerOff - reduct
					if FurySwingTimerOff < minimum then
						FurySwingTimer = minimum
					end
					return -- offhand gets the parry haste benefit, return
				end
			end	

			local minimum = GetWeaponSpeed(false) * 0.20
			if (FurySwingTimer > minimum) then
				local reduct = GetWeaponSpeed(false) * 0.40
				local newTimer = FurySwingTimer - reduct
				if (newTimer < minimum) then
					FurySwingTimer = minimum
				else
					FurySwingTimer = newTimer
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- OnUpdate Handler
--------------------------------------------------------------------------------

function Fury.SwingTimer:OnUpdate(delta)
	if (FurySwingTimer > 0) then
		FurySwingTimer = FurySwingTimer - delta
		if (FurySwingTimer < 0) then
			FurySwingTimer = 0
		end
	end
	if (FurySwingTimerOff > 0) then
		FurySwingTimerOff = FurySwingTimerOff - delta
		if (FurySwingTimerOff < 0) then
			FurySwingTimerOff = 0
		end
	end
end

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

function Fury.SwingTimer:Initialize()
	UpdateWeapon()
	if not FurySwingTimerMax then FurySwingTimerMax = GetWeaponSpeed(false) end
	if not FurySwingTimerOffMax and isDualWield() then FurySwingTimerOffMax = GetWeaponSpeed(true) end
	
	_,player_guid = UnitExists("player")
	_,player_class = UnitClass("player")
	GetFlurry(player_class)
	
	Fury:Debug("SwingTimer initialized")
end

--------------------------------------------------------------------------------
-- Utility Functions (for DecisionTree)
--------------------------------------------------------------------------------

-- Get remaining time on main hand swing
function Fury.SwingTimer:GetTimeToSwing()
	return FurySwingTimer
end

-- Get percentage of swing timer remaining (0-1)
function Fury.SwingTimer:GetSwingPercent()
	if FurySwingTimerMax > 0 then
		return FurySwingTimer / FurySwingTimerMax
	end
	return 0
end
