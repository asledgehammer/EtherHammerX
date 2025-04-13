---[[
--- This file is for EtherHammerX.
---
--- This module checks the client for the presence of EtherHack.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

-- Some LuaMethods from EtherLuaMethods.java that are injected.
local etherHackFunctions = {
    'getAntiCheat8Status',
    'getAntiCheat12Status',
    'getExtraTexture',
    'hackAdminAccess',
    'isDisableFakeInfectionLevel',
    'isDisableInfectionLevel',
    'isDisableWetness',
    'isEnableUnlimitedCarry',
    'isOptimalWeight',
    'isOptimalCalories',
    'isPlayerInSafeTeleported',
    'learnAllRecipes',
    'requireExtra',
    'safePlayerTeleport',
    'toggleEnableUnlimitedCarry',
    'toggleOptimalWeight',
    'toggleOptimalCalories',
    'toggleDisableFakeInfectionLevel',
    'toggleDisableInfectionLevel',
    'toggleDisableWetness',
    -- 'instanceof' -- [DEBUG]
};

-- Some Lua Objects from EtherHack.
local etherHackAPIClasses = {
    'EtherMain',
    'EtherAdminMenu',
    'EtherDebugMenu',
    'EtherEditWorldObjects',
    'EtherCharacterPanel',
    'EtherExploitPanel',
    'EtherInfoPanel',
    'EtherItemCreator',
    'EtherMapPanel',
    'EtherPlayerEditor',
    'EtherSettingsPanel',
    'EtherVisualsPanel',
    -- 'ISUIElement' -- [DEBUG]
};

--- @type EtherHammerXClientModule
local module = function(api, options)
    local function classExists()
        local classes = api.getGlobalClasses();
        for _, class in ipairs(classes) do
            for _, className in ipairs(etherHackAPIClasses) do
                if class.globalName == className or class.typeName == className then
                    return true;
                end
            end
        end
        return false;
    end

    local funcs = api.getGlobalFunctions();
    if api.anyExists(funcs, etherHackFunctions) then
        if options.submit_ticket_on_kick then
            api.submitTicket('Hello, I am using EtherHack, detected by EtherHammerX. (Code Injection)', function()
                api.report('EtherHack', 'Injected function', 'kick');
            end);
        else
            api.report('EtherHack', 'Injected function', 'kick');
        end
    elseif classExists() then
        if options.submit_ticket_on_kick then
            api.submitTicket('Hello, I am using EtherHack, detected by EtherHammerX. (Code Injection)', function()
                api.report('EtherHack', 'Injected class', 'kick');
            end);
        else
            api.report('EtherHack', 'Injected class', 'kick');
        end
    end
end

return module;
