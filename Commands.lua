Fury.Commands = {}

--------------------------------------------------
-- Command Handler
--------------------------------------------------
function Fury.Commands:Handle(msg)
    -- Safety check
    if not Fury or not Fury.DecisionTree then
        DEFAULT_CHAT_FRAME:AddMessage("ERROR: Fury addon not fully loaded!")
        return
    end
    
    local _, _, command, options = string.find(msg, "([%w%p]+)%s*(.*)$")
    if command then
        command = string.lower(command)
    end
    
    if not (UnitClass("player") == CLASS_WARRIOR_FURY) then
        Fury:Print("This addon is for Warriors only.")
        return
    end
    
    local commands = self:GetCommands()
    
    if command == nil or command == "" then
        -- Show help when no command is given
        self:DoHelp(commands, "")
    else
        local cmd = commands[command]
        if cmd ~= nil and cmd.fn ~= nil then
            cmd.fn(options)
        elseif command == "help" then
            self:DoHelp(commands, options)
        else
            self:DoHelp(commands, "")
        end
    end
end

--------------------------------------------------
-- Help Command
--------------------------------------------------
function Fury.Commands:DoHelp(commands, options)
    if options == nil or options == "" then
        local cmds = ""
        cmds = SLASH_FURY_HELP
        for k, _ in pairs(commands) do
            if cmds ~= "" and cmds ~= SLASH_FURY_HELP then
                cmds = cmds .. ", "
            end
            cmds = cmds .. k
            if string.len(cmds) > 80 then
                Fury:Print(cmds)
                cmds = ""
            end
        end
        Fury:Print(cmds)
    elseif commands[options] ~= nil then
        Fury:Print(commands[options].help)
    else
        Fury:Print(HELP_UNKNOWN)
    end
end

--------------------------------------------------
-- Command Definitions
--------------------------------------------------
function Fury.Commands:GetCommands()
    return {
        ["ability"] = {
            help = HELP_ABILITY,
            fn = function(options)
                if options == ABILITY_HEROIC_STRIKE_FURY and not Fury_Configuration[ABILITY_HEROIC_STRIKE_FURY] then
                    Fury_Configuration[ABILITY_HEROIC_STRIKE_FURY] = true
                    Fury:Print(ABILITY_HEROIC_STRIKE_FURY .. " " .. TEXT_FURY_ENABLED .. ".")
                    if Fury_Configuration[ABILITY_CLEAVE_FURY] then
                        Fury_Configuration[ABILITY_CLEAVE_FURY] = false
                        Fury:Print(ABILITY_CLEAVE_FURY .. " " .. TEXT_FURY_DISABLED .. ".")
                    end
                elseif options == ABILITY_CLEAVE_FURY and not Fury_Configuration[ABILITY_CLEAVE_FURY] then
                    Fury_Configuration[ABILITY_CLEAVE_FURY] = true
                    Fury:Print(ABILITY_CLEAVE_FURY .. " " .. TEXT_FURY_ENABLED .. ".")
                    if Fury_Configuration[ABILITY_HEROIC_STRIKE_FURY] then
                        Fury_Configuration[ABILITY_HEROIC_STRIKE_FURY] = false
                        Fury:Print(ABILITY_HEROIC_STRIKE_FURY .. " " .. TEXT_FURY_DISABLED .. ".")
                    end
                elseif Fury_Configuration[options] then
                    Fury_Configuration[options] = false
                    Fury:Print(options .. " " .. TEXT_FURY_DISABLED .. ".")
                elseif Fury_Configuration[options] == false then
                    Fury_Configuration[options] = true
                    Fury:Print(options .. " " .. TEXT_FURY_ENABLED .. ".")
                else
                    Fury:Print(options .. " " .. TEXT_FURY_NOT_FOUND .. ".")
                end
            end
        },

        ["charge"] = {
            help = HELP_CHARGE,
            fn = function(options)
                if Fury and Fury.Actions and Fury.Actions.Charge then
                    Fury.Actions:Charge()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("ERROR: Charge action not available!")
                end
            end
        },
        
        ["attack"] = {
            help = HELP_ATTACK,
            fn = function(options)
                Fury.Config:ToggleOption("AutoAttack", SLASH_FURY_AUTOATTACK)
            end
        },
        
        ["attackrage"] = {
            help = HELP_ATTACKRAGE,
            fn = function(options)
                Fury.Config:SetOptionRange("NextAttackRage", SLASH_FURY_ATTACKRAGE, options, 0, 100)
            end
        },
        
        ["berserk"] = {
            help = HELP_BERSERK,
            fn = function(options)
                Fury.Config:SetOptionRange("BerserkHealth", SLASH_FURY_TROLL, options, 1, 100)
            end
        },
        
        ["bloodrage"] = {
            help = HELP_BLOODRAGE,
            fn = function(options)
                Fury.Config:SetOptionRange("BloodrageHealth", SLASH_FURY_BLOODRAGE, options, 1, 100)
            end
        },
        
        ["dance"] = {
            help = HELP_DANCE,
            fn = function(options)
                Fury.Config:SetOptionRange("StanceChangeRage", SLASH_FURY_DANCE, options, 0, 100)
            end
        },  
        
        ["debug"] = {
            help = HELP_DEBUG,
            fn = function(options)
                Fury.Config:ToggleOption("Debug", SLASH_FURY_DEBUG)
            end
        },
        
        ["default"] = {
            help = HELP_DEFAULT,
            fn = function(options)
                Fury.Config:Reset()
                -- Rescan talents and spec after reset
                Fury.Talents:Scan()
            end
        },
        
        ["demodiff"] = {
            help = HELP_DEMODIFF,
            fn = function(options)
                Fury.Config:SetOptionRange("DemoDiff", SLASH_FURY_DEMODIFF, options, -3, 60)
            end
        },
        
        ["sunderdiff"] = {
            help = HELP_SUNDERDIFF,
            fn = function(options)
                Fury.Config:SetOptionRange("SunderDiff", SLASH_FURY_SUNDERDIFF, options, -3, 60)
            end
        },
        
        ["distance"] = {
            help = HELP_DISTANCE,
            fn = function(options)
                if UnitCanAttack("player", "target") then
                    Fury:Print(TEXT_FURY_DISTANCE .. " " .. Fury.Utils:Distance() .. " " .. TEXT_FURY_YARDS)
                else
                    Fury:Print(TEXT_FURY_NO_ATTACKABLE_TARGET)
                end
            end
        },
        
        ["flurrytrigger"] = {
            help = HELP_FLURRYTRIGGER,
            fn = function(options)
                Fury.Config:SetOptionRange("FlurryTriggerRage", SLASH_FURY_FLURRYTRIGGER, options, 0, 100)
            end
        },
        
        ["hamstring"] = {
            help = HELP_HAMSTRING,
            fn = function(options)
                Fury.Config:SetOptionRange("HamstringHealth", SLASH_FURY_HAMSTRING, options, 1, 100)
            end
        },
        
        ["help"] = {
            help = HELP_HELP,
            fn = nil
        },
        
        ["logfile"] = {
            help = "logfile [on|off|clear] - Log rotation to SavedVariables file",
            fn = function(options)
                if options == "on" then
                    FuryLogToFile = true
                    Fury:Print("File logging ENABLED. Logs saved to WTF folder.")
                    Fury:Print("Location: WTF\\Account\\<ACCOUNT>\\<SERVER>\\<CHAR>\\SavedVariables\\Fury.lua")
                elseif options == "off" then
                    FuryLogToFile = false
                    Fury:Print("File logging DISABLED. Log count: " .. table.getn(Fury_DebugLog))
                elseif options == "clear" then
                    local count = table.getn(Fury_DebugLog)
                    Fury_DebugLog = {}
                    Fury:Print("Log cleared. " .. count .. " entries removed.")
                else
                    local status = FuryLogToFile and "ON" or "OFF"
                    Fury:Print("File logging: " .. status .. " (" .. table.getn(Fury_DebugLog) .. " entries)")
                end
            end
        },
        
        ["rage"] = {
            help = HELP_RAGE,
            fn = function(options)
                Fury.Config:SetOptionRange("MaximumRage", SLASH_FURY_RAGE, options, 0, 100)
            end
        },
        
        ["shoot"] = {
            help = HELP_SHOOT,
            fn = function(options)
                Fury.Actions:Shoot()
            end
        },
        
        ["stance"] = {
            help = HELP_STANCE,
            fn = function(options)
                if options == ABILITY_BATTLE_STANCE_FURY or options == "1" then
                    Fury_Configuration["PrimaryStance"] = 1
                    Fury:Print(SLASH_FURY_STANCE .. ABILITY_BATTLE_STANCE_FURY .. ".")
                elseif options == ABILITY_DEFENSIVE_STANCE_FURY or options == "2" then
                    Fury_Configuration["PrimaryStance"] = 2
                    Fury:Print(SLASH_FURY_STANCE .. ABILITY_DEFENSIVE_STANCE_FURY .. ".")
                elseif options == ABILITY_BERSERKER_STANCE_FURY or options == "3" then
                    Fury_Configuration["PrimaryStance"] = 3
                    Fury:Print(SLASH_FURY_STANCE .. ABILITY_BERSERKER_STANCE_FURY .. ".")
                elseif options == "default" then
                    Fury_Configuration["PrimaryStance"] = false
                    Fury:Print(SLASH_FURY_STANCE .. TEXT_FURY_DEFAULT .. ".")
                else
                    Fury_Configuration["PrimaryStance"] = 0
                    Fury:Print(SLASH_FURY_NOSTANCE .. TEXT_FURY_DISABLED .. ".")
                end
            end
        },
        
        ["talents"] = {
            help = HELP_TALENTS,
            fn = function(options)
                Fury:Print(CHAT_TALENTS_RESCAN_FURY)
                Fury.Utils:InitDistance()
                Fury.Talents:Scan()
            end
        },
        
        ["threat"] = {
            help = HELP_THREAT,
            fn = function(options)
                if Fury_Configuration[ABILITY_HEROIC_STRIKE_FURY] then
                    Fury_Configuration[ABILITY_HEROIC_STRIKE_FURY] = false
                    Fury_Configuration[ABILITY_CLEAVE_FURY] = true
                    Fury:Print(SLASH_FURY_LOWTHREAT)
                else
                    Fury_Configuration[ABILITY_CLEAVE_FURY] = false
                    Fury_Configuration[ABILITY_HEROIC_STRIKE_FURY] = true
                    Fury:Print(SLASH_FURY_HIGHTHREAT)
                end
            end
        },
        
        ["unit"] = {
            help = HELP_UNIT,
            fn = function(options)
                local target
                if options ~= nil and options ~= "" then
                    target = options
                elseif UnitName("target") ~= nil then
                    target = "target"
                else
                    target = "player"
                end
                Fury:Print(TEXT_FURY_NAME .. (UnitName(target) or "") .. 
                          TEXT_FURY_CLASS .. (UnitClass(target) or "") .. 
                          TEXT_FURY_CLASSIFICATION .. (UnitClassification(target) or ""))
                if UnitRace(target) then
                    Fury:Print(TEXT_FURY_RACE .. (UnitRace(target) or ""))
                else
                    Fury:Print(TEXT_FURY_TYPE .. (UnitCreatureType(target) or ""))
                end
                Fury.Utils:PrintEffects(target)
            end
        },
        
        ["where"] = {
            help = HELP_WHERE,
            fn = function(options)
                Fury:Print(TEXT_FURY_MAP_ZONETEXT .. (GetMinimapZoneText() or ""))
                Fury:Print(TEXT_FURY_REAL_ZONETEXT .. (GetRealZoneText() or ""))
                Fury:Print(TEXT_FURY_SUB_ZONETEXT .. (GetSubZoneText() or ""))
                Fury:Print(TEXT_FURY_PVP_INFO .. (GetZonePVPInfo() or ""))
                Fury:Print(TEXT_FURY_ZONETEXT .. (GetZoneText() or ""))
            end
        },
        
        ["single"] = {
            help = "single - Fuehrt Single Target Rotation aus",
            fn = function(options)
                if Fury and Fury.DecisionTree and Fury.DecisionTree.ExecuteSingle then
                    Fury.DecisionTree:ExecuteSingle()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("ERROR: Single Target Rotation not available!")
                end
            end
        },
        
        ["multi"] = {
            help = "multi - Fuehrt Multi Target Rotation (AoE) aus",
            fn = function(options)
                if Fury and Fury.DecisionTree and Fury.DecisionTree.ExecuteMulti then
                    Fury.DecisionTree:ExecuteMulti()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("ERROR: Multi Target Rotation not available!")
                end
            end
        },
    }
end

-- Legacy function wrapper
function Fury_SlashCommand(msg)
    Fury.Commands:Handle(msg)
end
