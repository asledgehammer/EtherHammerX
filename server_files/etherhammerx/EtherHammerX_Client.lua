--[[
-- EtherHammer - Client Script.
--
-- @author asledgehammer, JabDoesThings, 2024
--]]

local Packet = require 'asledgehammer/network/Packet';

-- (Only run if client-side of a multiplayer session)
if not isClient() or isServer() then return end

(function()
    -- The packet-module identity.
    local MODULE_ID = 'EtherHammer';

    --- @type boolean
    --- If true, a ticket is submitted to the admins that the player is hacking.
    local SEND_TICKET_ON_KICK = true;

    --- @type string
    --- The message to submit as a ticket when a hack is detected.
    ---
    --- Parameter(s):
    ---  - {HACK} - The name of the hack.
    ---
    local TICKET_MSG = 'Hello, I am using {HACK}, detected by EtherHammer.';

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

    --- Only perform the actual kick here. We want to check and see if a ticket exists first with
    --- our message. (This prevents ticket spamming the server)
    local disconnectFromServer = function()
        setGameSpeed(1);
        pauseSoundAndMusic();
        setShowPausedMessage(true);
        getCore():quit();
    end

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

    --- Submits a hack ticket & kicks the player from the server.
    ---
    --- @param hackName string
    ---
    --- @return void
    local submitTicketAndKick = function(hackName)
        local player = getPlayer();
        local username = player:getUsername();
        local ticketMessage = string.gsub(TICKET_MSG, '{HACK}', hackName);

        --- Add and Remove the ticket checker after checking for a pre-existing hack message.
        --- @param tickets ArrayList<DBTicket>
        local __f = function(tickets) end
        __f = function(tickets)
            -- Execute only once.
            Events.ViewTickets.Remove(__f);

            local length = tickets:size() - 1;
            for i = 0, length, 1 do
                --- @type DBTicket
                local ticket = tickets:get(i);
                local author, message = ticket:getAuthor(), ticket:getMessage();
                if author == username and message == ticketMessage then
                    disconnectFromServer();
                    return
                end
            end
            addTicket(username, ticketMessage, -1);
            disconnectFromServer();
        end
        Events.ViewTickets.Add(__f);

        getTickets(username);
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

    --- Tests the global functions of the player for EtherHack.
    ---
    --- @param global string[] The global array of functions to test.
    --- @return boolean True if the player has any functions that are injected into their client
    --- from the EtherHack client mod.
    local detectEtherHack = function(global)
        if checkIfGlobalFunctionsExists(global, etherHackFunctions) then
            submitTicketAndKick('EtherHack');
            return true;
        end
        return false;
    end

    local function run()
        -- This is the initial key to perform the handshake.
        local DEFAULT_KEY = MODULE_ID .. '_' .. getOnlineUsername();
        local key = DEFAULT_KEY;

        local function onReceivePacket(id, data)
            local username = getOnlineUsername();
            if id == 'join_request' or 'heartbeat_request' then

                --------------------------------------
                -- Perform the anti-cheat checks here.
                if detectEtherHack(getGlobalFunctions()) then
                    local packet = Packet(MODULE_ID, 'hack_detected', {});
                    packet:encrypt(key, function()
                        packet:sendToServer();
                        if SEND_TICKET_ON_KICK then
                            submitTicketAndKick('EtherHack');
                        else
                            disconnectFromServer();
                        end
                    end);
                    return
                end
                --------------------------------------

                -- The key-fragment from the server.
                local fragment1 = data.message;

                -- The key-fragment for the client.
                local fragment2 = getTimeInMillis();

                local idResponse;
                local dataResponse = { message = fragment2 };

                if id == 'join_request' then
                    idResponse = 'join_response';
                elseif id == 'heartbeat_request' then
                    idResponse = 'heartbeat_response';
                    -- Provide the current key for server-side verification.
                    dataResponse.key = key;
                end

                local packet = Packet(MODULE_ID, idResponse, dataResponse);
                packet:encrypt(key, function()
                    packet:sendToServer();
                    key = MODULE_ID .. '_' .. username .. fragment1 .. fragment2;
                end);
            end
        end

        Events.OnServerCommand.Add(function(module, command, args)
            if module ~= MODULE_ID then return end
            local packet = Packet(module, command, args);
            packet:decrypt(key, function()
                onReceivePacket(packet.command, packet.data);
            end);
        end);

        -- listener:listen(MODULE_ID, DEFAULT_KEY, onReceivePacket);

        local packet = Packet(MODULE_ID, 'handshake_request');
        packet:encrypt(key, function()
            packet:sendToServer();
        end);
    end

    -- Run the anti-cheat immediately since the game has already started.
    run();
end)();
