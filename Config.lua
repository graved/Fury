Fury.Config = {}

--------------------------------------------------
-- Default Configuration
--------------------------------------------------
local function GetDefaults()
    return {
        -- General Settings
        {"AutoAttack", true},
        {"BerserkHealth", 60},
        {"BloodrageHealth", 50},
        {"Debug", false},
        {"DemoDiff", 7},
        {"SunderDiff", 7},
        {"FlurryTriggerRage", 52},
        {"HamstringHealth", 40},
        {"InstantBuildTime", 2},
        {"MaximumRage", 60},
        {"NextAttackRage", 30},
        {"StanceChangeRage", 25},
        {"PrimaryStance", false},
        
        -- Abilities
        {ABILITY_BATTLE_SHOUT_FURY, true},
        {ABILITY_BERSERKER_RAGE_FURY, true},
        {ABILITY_BLOODRAGE_FURY, true},
        {ABILITY_BLOODTHIRST_FURY, true},
        {ABILITY_CHARGE_FURY, true},
        {ABILITY_CLEAVE_FURY, false},
        {ABILITY_DEMORALIZING_SHOUT_FURY, true},
        {ABILITY_DISARM_FURY, true},
        {ABILITY_EXECUTE_FURY, true},
        {ABILITY_HAMSTRING_FURY, true},
        {ABILITY_PIERCING_HOWL_FURY, true},
        {ABILITY_HEROIC_STRIKE_FURY, true},
        {ABILITY_INTERCEPT_FURY, true},
        {ABILITY_MORTAL_STRIKE_FURY, true},
        {ABILITY_SWEEPING_STRIKES_FURY, true},
        {ABILITY_OVERPOWER_FURY, true},
        {ABILITY_PUMMEL_FURY, true},
        {ABILITY_REND_FURY, true},
        {ABILITY_SLAM_FURY, true},
        {ABILITY_THUNDER_CLAP_FURY, true},
        {ABILITY_WHIRLWIND_FURY, true},
        {ABILITY_SUNDER_ARMOR_FURY, true},  -- High prio: Apply until 5 stacks!
        
        -- Racials
        {RACIAL_BERSERKING_FURY, true},
        {RACIAL_BLOOD_FURY, true},
        {RACIAL_STONEFORM_FURY, true},
    }
end

--------------------------------------------------
-- Update Configuration
--------------------------------------------------
function Fury.Config:Update(defaults)
    local configs = GetDefaults()
    
    for _, v in pairs(configs) do
        if defaults or Fury_Configuration[v[1]] == nil then
            Fury_Configuration[v[1]] = v[2]
        end
    end
end

--------------------------------------------------
-- Initialize Configuration
--------------------------------------------------
function Fury.Config:Initialize()
    self:Update(false)
end

--------------------------------------------------
-- Reset to Defaults
--------------------------------------------------
function Fury.Config:Reset()
    self:Update(true)
    Fury:Print("Configuration reset to defaults.")
end

--------------------------------------------------
-- Toggle Option
--------------------------------------------------
function Fury.Config:ToggleOption(option, text)
    if Fury_Configuration[option] == true then
        Fury_Configuration[option] = false
        Fury:Print(text .. " " .. TEXT_FURY_DISABLED .. ".")
    elseif Fury_Configuration[option] == false then
        Fury_Configuration[option] = true
        Fury:Print(text .. " " .. TEXT_FURY_ENABLED .. ".")
    else
        return false
    end
    return true
end

--------------------------------------------------
-- Set Option Range
--------------------------------------------------
function Fury.Config:SetOptionRange(option, text, value, vmin, vmax)
    if value ~= "" then
        if tonumber(value) < vmin then
            value = vmin
        elseif tonumber(value) > vmax then
            value = vmax
        end
        Fury_Configuration[option] = tonumber(value)
    else
        value = Fury_Configuration[option]
    end
    Fury:Print(text .. value .. ".")
end

--------------------------------------------------
-- Print Enabled Option
--------------------------------------------------
function Fury.Config:PrintEnabledOption(option, text)
    if Fury_Configuration[option] == true then
        Fury:Print(text .. " " .. TEXT_FURY_ENABLED .. ".")
    end
end

