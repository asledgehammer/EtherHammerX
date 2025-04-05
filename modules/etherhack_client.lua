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
};

--- @type EtherHammerXClientModule
local module = function(api, options)
    local classes = api.getGlobalClasses();
    local funcs = api.getGlobalFunctions();
    if api.anyExists(funcs, etherHackFunctions) or api.anyExists(classes, etherHackAPIClasses) then
        api.report('EtherHack', 'Injected function', false);
        if options.SUBMIT_TICKET_ON_KICK then
            api.submitTicket('Hello, I am using EtherHack, detected by EtherHammerX.', function()
                api.disconnect();
            end);
        else
            api.disconnect();
        end
    end
end

return module;
