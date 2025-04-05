---[[
--- This file is for EtherHammerX.
---
--- This module checks the client for the presence of EtherHack.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @param api EtherHammerXClientAPI Use this to gain access to EtherHammerX's API.
--- @param options table<string, any> Options sent to the module from the server's configuration.
---
--- @return boolean, string | nil results If true, the hack is detected. The 2nd argument passed is the name or
--- identifier of the hack detected.
return function(api, options)

    -- Some LuaMethods rom EtherLuaMethods.java that are injected.
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

    --- Grabs all the functions in the global table.
    ---
    --- @return string[]
    local getGlobalFunctions = function()
        local array = {};
        for name, value in pairs(_G) do
            -- Java API:
            --     'function <memory address>'
            -- Lua API:
            --     'closure <memory address>'
            if type(value) == 'function' and string.find(tostring(value), 'function ') == 1 then
                table.insert(array, name);
            end
        end
        table.sort(array, function(a, b) return a:upper() < b:upper() end);
        return array;
    end

    --- Checks if an array has a value stored.
    ---
    --- @param array string[] The array to check.
    --- @param value string The value to check.
    --- @return boolean True if one or more values are in the array.
    local hasValue = function(array, value)
        for _, next in ipairs(array) do if value == next then return true end end
        return false
    end

    --- Checks if one or more functions exists on the global scope. (_G)
    ---
    --- @param funcs string[] The names of the functions to test.
    --- @return boolean True if one or more global functions exists and is the type() == 'function'
    local checkIfGlobalFunctionsExists = function(global, funcs)
        for i = 1, #funcs do if hasValue(global, funcs[i]) then return true end end
        return false;
    end

    local global = getGlobalFunctions();
    if checkIfGlobalFunctionsExists(global, etherHackFunctions) then
        return true, 'EtherHack';
    end

    return false, nil;
end
