Fury.Utils = {}

--------------------------------------------------
-- Auto Attack Management
--------------------------------------------------

-- Intelligently enable auto attack only if needed
-- IMPORTANT: AttackTarget() is a TOGGLE, not an enable function!
-- Only call it when auto-attack is NOT already active
function Fury.Utils:EnableAutoAttack()
    -- Check if auto attack feature is enabled in config
    if not Fury_Configuration or not Fury_Configuration["AutoAttack"] then
        return false
    end
    
    -- Check if target exists and is attackable
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        return false
    end
    
    -- CRITICAL: Only call AttackTarget() if NOT already attacking
    -- AttackTarget() toggles auto-attack on/off, so calling it while attacking would DISABLE it!
    if not FuryAttack then
        AttackTarget()
        return true
    end
    
    return false
end

--------------------------------------------------
-- Buff/Debuff Detection
--------------------------------------------------

-- Get number of Sunder Armor stacks on target
function Fury.Utils:GetSunderStacks(unit)
    unit = unit or "target"
    local i = 1
    while true do
        local texture, count = UnitDebuff(unit, i)
        if not texture then
            break
        end
        if string.find(texture, "Ability_Warrior_Sunder") then
            return count or 1
        end
        i = i + 1
    end
    return 0  -- No Sunder found
end

-- Check if unit has a specific debuff
function Fury.Utils:HasDebuff(unit, texturename, amount)
    local id = 1
    while UnitDebuff(unit, id) do
        local debuffTexture, debuffAmount = UnitDebuff(unit, id)
        if string.find(debuffTexture, texturename) then
            if (amount or 1) <= debuffAmount then
                return true
            else
                return false
            end
        end
        id = id + 1
    end
    return nil
end

-- Check if unit has a buff
function Fury.Utils:HasBuff(unit, texturename)
    local id = 1
    while UnitBuff(unit, id) do
        local buffTexture = UnitBuff(unit, id)
        if string.find(buffTexture, texturename) then
            return true
        end
        id = id + 1
    end
    return nil
end

-- Check if unit has a buff by ID
function Fury.Utils:HasBuffId(unit, spellId)
    for i = 1, 40 do
        if select(11, UnitBuff(unit, i)) == spellid then
            return true
        end
    end
    return nil
end

-- Check if unit has debuff of specific type
function Fury.Utils:HasDebuffType(unit, type)
    local id = 1
    if not type then
        return nil
    end
    while UnitDebuff(unit, id) do
        local _, _, debuffType = UnitDebuff(unit, id)
        if type and debuffType == type then
            return true
        end
        id = id + 1
    end
    return nil
end

-- Check for multiple debuffs
function Fury.Utils:CheckDebuffs(unit, list)
    for _, v in pairs(list) do
        if self:HasDebuff(unit, v) then
            return true
        end
    end
    return nil
end

--------------------------------------------------
-- Specific Debuff Checks
--------------------------------------------------

-- Check for anti-stealth debuffs
function Fury.Utils:HasAntiStealthDebuff()
    return self:CheckDebuffs("target", {
        "Ability_Gouge",
        "Ability_Hunter_Quickshot",
        "Spell_Fire_Immolation",
        "Spell_Shadow_CurseOfSargeras",
        "Ability_Rogue_Garrote",
        "Ability_Rogue_Rupture",
        "Ability_Rogue_DualWeild",
        "Spell_Shadow_ShadowWordPain",
        "Spell_Fire_FlameBolt",
        "Spell_Fire_Incinerate",
        "Spell_Fire_Fireball02",
        "Spell_Shadow_AbominationExplosion",
        "Spell_Shadow_Requiem",
        "Spell_Nature_FaerieFire",
        "Spell_Nature_StarFall",
        "Ability_Druid_Disembowel",
        "Ability_Druid_SurpriseAttack",
        "Spell_Nature_InsectSwarm",
        "Spell_Holy_SearingLight",
        "INV_Spear_02",
        "Spell_Shadow_BlackPlague"
    })
end

-- Check for immobilizing debuffs
function Fury.Utils:HasImmobilizingDebuff()
    return self:CheckDebuffs("player", {
        "Spell_Frost_FrostNova",
        "spell_Nature_StrangleVines"
    })
end

-- Check for snare debuffs
function Fury.Utils:SnareDebuff(unit)
    return self:CheckDebuffs(unit, {
        "Ability_ShockWave",
        "Ability_Rogue_Trip",
        "Spell_Shadow_GrimWard",
        "Ability_PoisonSting",
        "Spell_Frost_FrostBolt02",
        "Spell_Frost_Glacier",
        "Spell_Shadow_DeathScream",
        "Spell_Frost_FrostShock"
    })
end

--------------------------------------------------
-- Distance Management
--------------------------------------------------

-- Global distance check action bar slots
yard30 = nil
yard25 = nil
yard10 = nil
yard08 = nil
yard05 = nil

-- Initialize distance checking
function Fury.Utils:InitDistance()
    local found = 0
    yard30 = nil
    yard25 = nil
    yard10 = nil
    yard08 = nil
    yard05 = nil
    
    for i = 1, 120 do
        local t = GetActionTexture(i)
        if t then
            if not yard30 then
                if string.find(t, "Ability_Marksmanship") or string.find(t, "Ability_Throw") then
                    yard30 = i
                    Fury:Debug("30 yard: " .. t)
                    found = found + 1
                end
            end
            if not yard25 then
                if string.find(t, "Ability_Warrior_Charge") or string.find(t, "Ability_Rogue_Sprint") then
                    yard25 = i
                    Fury:Debug("25 yard: " .. t)
                    found = found + 1
                end
            end
            if not yard10 then
                if string.find(t, "Ability_GolemThunderClap") or string.find(t, "Spell_Nature_ThunderClap") then
                    yard10 = i
                    Fury:Debug("10 yard: " .. t)
                    found = found + 1
                end
            end
            if not yard08 then
                if string.find(t, "Ability_Marksmanship") or string.find(t, "Ability_Throw") then
                    yard08 = i
                    Fury:Debug("8 yard: " .. t)
                    found = found + 1
                end
            end
            if not yard05 then
                if string.find(t, "Ability_Warrior_Sunder") or 
                   string.find(t, "Ability_Warrior_DecisiveStrike") or
                   string.find(t, "Ability_Warrior_Disarm") or
                   string.find(t, "INV_Gauntlets_04") or
                   string.find(t, "Ability_MeleeDamage") or
                   string.find(t, "Ability_Warrior_PunishingBlow") or
                   string.find(t, "Ability_Warrior_Revenge") or
                   string.find(t, "Ability_Gouge") or
                   string.find(t, "INV_Sword_48") or
                   string.find(t, "ability_warrior_savageblow") or
                   string.find(t, "INV_Shield_05") or
                   string.find(t, "Ability_ShockWave") or
                   string.find(t, "Spell_Nature_Bloodlust") then
                    yard05 = i
                    Fury:Debug("5 yard: " .. t)
                    found = found + 1
                end
            end
            if found == 5 then
                Fury:Debug("Found all distance check spells (" .. i .. ")")
                return
            end
        end
    end
    
    -- Print warnings for missing distance check spells
    if not yard30 or not yard08 then
        Fury:Print(CHAT_MISSING_SPELL_SHOOT_THROW_FURY)
    end
    if not yard25 then
        Fury:Print(CHAT_MISSING_SPELL_INTERCEPT_CHARGE_FURY)
    end
    if not yard10 then
        Fury:Print(CHAT_MISSING_SPELL_THUNDERCLAP_FURY)
    end
    if not yard05 then
        Fury:Print(CHAT_MISSING_SPELL_PUMMEL_FURY)
    end
end

-- Get distance to target
function Fury.Utils:Distance()
    -- Check if target exists first
    if not UnitExists("target") then
        return 100
    end
    
    -- Calculate distance using range check spells
    -- Works for any target (hostile, friendly, neutral)
    if yard05 and IsActionInRange(yard05) == 1 then
        return 5
    elseif yard10 and IsActionInRange(yard10) == 1 then
        if yard08 and IsActionInRange(yard08) == 0 then
            return 7
        end
        return 10
    elseif yard25 and IsActionInRange(yard25) == 1 then
        return 25
    elseif yard30 and IsActionInRange(yard30) == 1 then
        return 30
    end
    return 100
end

--------------------------------------------------
-- Spell Management
--------------------------------------------------

-- Get spell ID from name
function Fury.Utils:SpellId(spellname)
    local id = 1
    for i = 1, GetNumSpellTabs() do
        local _, _, _, numSpells = GetSpellTabInfo(i)
        for j = 1, numSpells do
            local spellName = GetSpellName(id, BOOKTYPE_SPELL)
            if spellName == spellname then
                return id
            end
            id = id + 1
        end
    end
    return nil
end

-- Check remaining cooldown on spell
function Fury.Utils:IsSpellReadyIn(spellname)
    local id = self:SpellId(spellname)
    if id then
        local start, duration = GetSpellCooldown(id, 0)
        if start == 0 and duration == 0 and FuryLastSpellCast + 1 <= GetTime() then
            return 0
        end
        local remaining = duration - (GetTime() - start)
        if remaining >= 0 then
            return remaining
        end
    end
    return 86400
end

-- Check if spell is ready
function Fury.Utils:IsSpellReady(spellname)
    return self:IsSpellReadyIn(spellname) == 0
end

--------------------------------------------------
-- Stance Management
--------------------------------------------------

-- Get active stance
function Fury.Utils:GetActiveStance()
    for i = 1, 3 do
        local _, _, active = GetShapeshiftFormInfo(i)
        if active then
            return i
        end
    end
    return nil
end

-- Change stance
function Fury.Utils:DoShapeShift(stance)
    local stances = {ABILITY_BATTLE_STANCE_FURY, ABILITY_DEFENSIVE_STANCE_FURY, ABILITY_BERSERKER_STANCE_FURY}
    CastShapeshiftForm(stance)
    FuryLastStanceCast = GetTime()
    Fury:Debug("Changed to " .. stances[stance])
end

--------------------------------------------------
-- Equipment Checks
--------------------------------------------------

-- Check if player has a weapon equipped
function Fury.Utils:HasWeapon()
    if self:HasDebuff("player", "Ability_Warrior_Disarm") then
        return nil
    end
    local item = GetInventoryItemLink("player", 16)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local itemName, itemLink = GetItemInfo(itemCode)
        if itemLink ~= "item:7005:0:0:0" and 
           itemLink ~= "item:2901:0:0:0" and 
           not GetInventoryItemBroken("player", 16) then
            return true
        end
    end
    return nil
end

-- Check if player has a shield equipped
function Fury.Utils:HasShield()
    if self:HasDebuff("player", "Ability_Warrior_Disarm") then
        return nil
    end
    local item = GetInventoryItemLink("player", 17)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local _, _, _, _, _, itemType = GetItemInfo(itemCode)
        if itemType == ITEM_TYPE_SHIELDS_FURY and not GetInventoryItemBroken("player", 17) then
            return true
        end
    end
    return nil
end

-- Check equipped ranged weapon type
function Fury.Utils:Ranged()
    local item = GetInventoryItemLink("player", 18)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local _, _, _, _, _, itemType = GetItemInfo(itemCode)
        return itemType
    end
    return nil
end

-- Check if trinket is equipped and ready
function Fury.Utils:IsTrinketEquipped(name)
    for slot = 13, 14 do
        local item = GetInventoryItemLink("player", slot)
        if item then
            local _, _, itemCode = strfind(item, "(%d+):")
            local itemName = GetItemInfo(itemCode)
            if itemName == name and GetInventoryItemCooldown("player", slot) == 0 then
                return slot
            end
        end
    end
    return nil
end

-- Check if item is equipped and ready
function Fury.Utils:IsEquippedAndReady(slot, name)
    local item = GetInventoryItemLink("player", slot)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local itemName = GetItemInfo(itemCode)
        if itemName == name and GetInventoryItemCooldown("player", slot) == 0 then
            return true
        end
    end
    return nil
end

-- Check item cooldown
function Fury.Utils:CheckCooldown(slot)
    local start, duration = GetInventoryItemCooldown("player", slot)
    if duration > 30 then
        local item = GetInventoryItemLink("player", slot)
        if item then
            local _, _, itemCode = strfind(item, "(%d+):")
            local itemName = GetItemInfo(itemCode)
            return itemName
        end
    end
    return nil
end

--------------------------------------------------
-- Item Management
--------------------------------------------------

-- Check if item exists in bags
function Fury.Utils:ItemExists(itemName)
    for bag = 4, 0, -1 do
        for slot = 1, GetContainerNumSlots(bag) do
            local _, itemCount = GetContainerItemInfo(bag, slot)
            if itemCount then
                local itemLink = GetContainerItemLink(bag, slot)
                local _, _, itemParse = strfind(itemLink, "(%d+):")
                local queryName = GetItemInfo(itemParse)
                if queryName and queryName ~= "" then
                    if queryName == itemName then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Check if item is ready to use
function Fury.Utils:IsItemReady(item)
    if self:ItemExists(item) == false then
        return false
    end
    local _, duration = GetItemCooldown(item)
    if duration == 0 then
        return true
    end
    return false
end

-- Use item on player
function Fury.Utils:UseContainerItemByNameOnPlayer(name)
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local item = GetContainerItemLink(bag, slot)
            if item then
                local _, _, itemCode = strfind(item, "(%d+):")
                local itemName = GetItemInfo(itemCode)
                if itemName == name then
                    UseContainerItem(bag, slot)
                    if SpellIsTargeting() then
                        SpellTargetUnit("player")
                    end
                end
            end
        end
    end
end

-- Calculate Hamstring cost based on gear
function Fury.Utils:HamstringCost()
    local i = 0
    local item = GetInventoryItemLink("player", 10)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local itemName = GetItemInfo(itemCode)
        if itemName == ITEM_GAUNTLETS1_FURY or
           itemName == ITEM_GAUNTLETS2_FURY or
           itemName == ITEM_GAUNTLETS3_FURY or
           itemName == ITEM_GAUNTLETS4_FURY then
            i = i + 3
        end
    end
    item = GetInventoryItemLink("player", 2)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local itemName = GetItemInfo(itemCode)
        if itemName == ITEM_NECK_RAGE_OF_MUGAMBA_FURY then
            i = i + 2
        end
    end
    return 10 - i
end

--------------------------------------------------
-- Spec Detection
--------------------------------------------------
function Fury.Utils:DetectSpec()
    -- In WoW 1.12.1, we check if offhand slot is empty
    -- Slot 16 = Main Hand, Slot 17 = Off Hand
    local hasMainHand = GetInventoryItemLink("player", 16)
    local hasOffHand = GetInventoryItemLink("player", 17)
    
    if not hasMainHand then
        FuryWeaponType = "NONE"
        FurySpec = nil
        Fury:Debug("Detected: No weapon equipped")
        return
    end
    
    -- Check if offhand is a shield (use HasShield helper)
    if self:HasShield() then
        FuryWeaponType = "1H+SHIELD"
        FurySpec = "PROT"
        Fury:Debug("Detected Spec: PROTECTION (Shield)")
        -- Set Primary Stance to Defensive
        if not Fury_Configuration["PrimaryStance"] or Fury_Configuration["PrimaryStance"] == false then
            Fury_Configuration["PrimaryStance"] = 2
            Fury:Debug("Primary Stance set to: Defensive (2)")
        end
        return
    end
    
    -- Determine if 2H or DW based on offhand slot
    if hasOffHand then
        -- Has something in offhand (and it's not a shield) = Dual Wield
        FuryWeaponType = "DW"
        FurySpec = "DW_FURY"
        Fury:Debug("Detected Spec: DW FURY (2 weapons)")
        -- Set Primary Stance to Berserker for DW Fury
        if not Fury_Configuration["PrimaryStance"] or Fury_Configuration["PrimaryStance"] == false then
            Fury_Configuration["PrimaryStance"] = 3
            Fury:Debug("Primary Stance set to: Berserker (3)")
        end
    else
        -- No offhand = 2H weapon (or 1H without offhand, but warriors always use 2H if no OH)
        FuryWeaponType = "2H"
        
        -- Check for Mortal Strike (Arms) vs Bloodthirst (Fury)
        if FuryMortalStrike then
            FurySpec = "ARMS"
            Fury:Debug("Detected Spec: ARMS (2H + Mortal Strike)")
            -- Arms can stay in Battle or Berserker - let user choose
            if not Fury_Configuration["PrimaryStance"] or Fury_Configuration["PrimaryStance"] == false then
                Fury_Configuration["PrimaryStance"] = 1
                Fury:Debug("Primary Stance set to: Battle (1)")
            end
        else
            FurySpec = "2H_FURY"
            Fury:Debug("Detected Spec: 2H FURY (no offhand)")
            -- Set Primary Stance to Berserker for 2H Fury
            if not Fury_Configuration["PrimaryStance"] or Fury_Configuration["PrimaryStance"] == false then
                Fury_Configuration["PrimaryStance"] = 3
                Fury:Debug("Primary Stance set to: Berserker (3)")
            end
        end
    end
end

function Fury.Utils:IsArms()
    return FurySpec == "ARMS"
end

function Fury.Utils:Is2HFury()
    return FurySpec == "2H_FURY"
end

function Fury.Utils:IsDWFury()
    return FurySpec == "DW_FURY"
end

function Fury.Utils:Uses2H()
    return FuryWeaponType == "2H"
end

function Fury.Utils:UsesDW()
    return FuryWeaponType == "DW"
end

--------------------------------------------------
-- Debug Helpers
--------------------------------------------------

-- Print unit effects
function Fury.Utils:PrintEffects(unit)
    local id = 1
    if UnitBuff(unit, id) then
        Fury:Print(SLASH_BUFFS_FURY)
        while (UnitBuff(unit, id)) do
            Fury:Print(UnitBuff(unit, id))
            id = id + 1
        end
        id = 1
    end
    if self:HasDebuffType(unit) then
        Fury:Print(TEXT_FURY_HAVE_DEBUFF)
    end
    if UnitDebuff(unit, id) then
        Fury:Print(CHAT_DEBUFFS_FURY)
        while UnitDebuff(unit, id) do
            Fury:Print(UnitDebuff(unit, id))
            id = id + 1
        end
    end
end

-- Legacy function wrappers
function Fury_Distance()
    return Fury.Utils:Distance()
end
