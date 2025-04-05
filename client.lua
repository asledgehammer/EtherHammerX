---[[
--- EtherHammer - Client Script.
--- 
--- @author asledgehammer, JabDoesThings 2025
---]]

local Packet = require 'asledgehammer/network/Packet';

--- @type fun(table: table): table
local readonly = require 'asledgehammer/util/readonly';

-- (Only run if client-side of a multiplayer session)
if not isClient() or isServer() then return end

(function()
    --- Dynamically loaded and fed from `keys.lua`.
    ---
    --- @type fun(player: IsoPlayer): string
    local clientKey = { func = 'CLIENT_KEY_FUNCTION' };

    -- The packet-module identity.
    local MODULE_ID = { string = 'MODULE_ID' };

    --- @type {name: string, code: string, runOnce: boolean, options: table}[]
    local modules = { raw = 'MODULES' };

    -- This is the initial key to perform the handshake.
    local HANDSHAKE_KEY = { string = 'HANDSHAKE_KEY' };
    local key = HANDSHAKE_KEY;

    --- @type boolean
    --- If true, a ticket is submitted to the admins that the player is hacking.
    local SEND_TICKET_ON_KICK = { boolean = 'SUBMIT_TICKET_ON_KICK' };

    --- @type string
    --- The message to submit as a ticket when a hack is detected.
    ---
    --- Parameter(s):
    ---  - {HACK} - The name of the hack.
    ---
    local TICKET_MSG = 'Hello, I am using {HACK}, detected by EtherHammerX.';

    local disconnected = false;

    --- @type EtherHammerXClientAPI
    local api = {};

    function api.disconnect()
        disconnected = true;
        setGameSpeed(1);
        pauseSoundAndMusic();
        setShowPausedMessage(true);
        getCore():quit();
    end

    function api.getGlobalTables()
        local array = {};
        for name, value in pairs(_G) do
            if type(value) == 'table' then
                -- [global reference name, pseudo-class type name]
                table.insert(array, name);
            end
        end
        table.sort(array, function(a, b) return a:upper() < b:upper() end);
        return array;
    end

    function api.getGlobalClasses()
        local array = {};
        for name, value in pairs(_G) do
            if type(value) == 'table' and value.Type ~= nil then
                -- [global reference name, pseudo-class type name]
                table.insert(array, { globalName = name, typeName = value.Type });
            end
        end
        table.sort(array, function(a, b) return a.globalName < b.globalName end);
        return array;
    end

    function api.getGlobalFunctions()
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

    function api.arrayContains(array, value)
        for _, next in ipairs(array) do if value == next then return true end end
        return false
    end

    function api.anyExists(list, match)
        for i = 1, #match do if api.arrayContains(list, match[i]) then return true end end
        return false;
    end

    function api.printGlobalClasses(classes)
        classes = classes or api.getGlobalClasses();
        local s = 'Global Class(es) (' .. tostring(#classes) .. '):\n';
        for _, names in ipairs(classes) do
            s = s .. '\t' .. tostring(names.globalName) .. ' (class.Type = ' .. tostring(names.typeName) .. ')\n';
        end
        print(s);
    end

    function api.printGlobalTables(tables)
        tables = tables or api.getGlobalTables();
        local s = 'Global Table(s) (' .. tostring(#tables) .. '):\n';
        for _, name in ipairs(tables) do
            s = s .. '\t' .. tostring(name) .. '\n';
        end
        print(s);
    end

    function api.printGlobalFunctions(funcs)
        funcs = funcs or api.getGlobalFunctions();
        local s = 'Global function(s) (' .. tostring(#funcs) .. '):\n';
        for _, funcName in ipairs(funcs) do
            s = s .. '\t' .. tostring(funcName) .. '\n';
        end
        print(s);
    end

    function api.ticketExists(author, message, callback)
        local __f = function() end
        --- Add and Remove the ticket checker after checking for a pre-existing hack message.
        --- @param tickets ArrayList<DBTicket>
        __f = function(tickets)
            -- Execute only once.
            Events.ViewTickets.Remove(__f);
            local length = tickets:size() - 1;
            for i = 0, length do
                --- @type DBTicket
                local ticket = tickets:get(i);
                if ticket:getAuthor() == author and message == ticket:getMessage() then
                    callback(true);
                    return;
                end
            end
            callback(false);
        end
        Events.ViewTickets.Add(__f);
        getTickets(author);
    end

    function api.submitTicket(message, callback)
        local player = getPlayer();
        local username = player:getUsername();
        api.ticketExists(username, message, function(exists)
            if not exists then
                addTicket(username, message, -1);
            end
            callback();
        end);
    end

    function api.isDisconnected()
        return disconnected;
    end

    function api.report(type, reason, disconnect)
        local message = type;
        if reason then message = message .. ' (' .. reason .. ')' end

        local packet = Packet(MODULE_ID, { string = 'REPORT_COMMAND' }, { type = type, reason = reason });
        packet:encryptAndSendToServer(key);

        if disconnect then api.disconnect() end
    end

    -- Force the table to be read-only. Rogue or maliciously-injected modules won't be able to mutate the API table.
    api = readonly(api);

    local function runModules()
        for _, m in pairs(modules) do
            if m.runOnce and m.code ~= nil then
                m.code(api, m.options);
                m.code = nil;
            else
                m.code(api, m.options);
            end
        end
    end

    Events.OnServerCommand.Add(function(module, command, args)
        -- Ignore everything else.
        if module ~= MODULE_ID then return end

        local packet = Packet(module, command, args);
        packet:decrypt(key, function()
            -- Make sure that the packet is proper. Anything other can be considered tampering.
            if not packet.valid then
                print('[EtherHammerX] :: Bad or malformed packet. Disconnecting from server..');
                disconnect();
                return;
            end

            if packet.command == { string = 'HEARTBEAT_REQUEST_COMMAND' } then

                -- Generate the expected client-key fragment.
                local serverFragment = packet.data.message;
                local clientFragment = clientKey(getPlayer());

                -- Send back the next packet as encrypted with the new key.
                key = serverFragment .. clientFragment;

                -- (Update modules that run more than once)
                runModules();

                -- (No need to do anything else if disconnected)
                if disconnected then return end

                packet = Packet(MODULE_ID, { string = 'HEARTBEAT_RESPONSE_COMMAND' }, {
                    key = key,
                    message = clientFragment
                });
                packet:encryptAndSendToServer(key);
            end
        end);
    end);

    -- Initialize formal request for first handshake.
    local packet = Packet(MODULE_ID, { string = 'HANDSHAKE_REQUEST_COMMAND' });
    packet:encryptAndSendToServer({ string = 'HANDSHAKE_KEY' });
end)();
