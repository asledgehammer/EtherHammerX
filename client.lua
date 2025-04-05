--[[
-- EtherHammer - Client Script.
--
-- Injected variables:
--  - MODULES - The EHX modules running in the server.
--  - MODULE_ID - The ID of the module given from the workshop item.
--  - HEARTBEAT_REQUEST_COMMAND - The name of the command 'heartbeat_request'.
--  - HEARTBEAT_RESPONSE_COMMAND - The name of the command 'heartbeat_response'.
--  - HANDSHAKE_REQUEST_COMMAND - The name of the command 'handshake_request'.
--
-- @author asledgehammer, JabDoesThings, 2025
--]]

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
    local TICKET_MSG = 'Hello, I am using {HACK}, detected by EtherHammer.';

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
        if SEND_TICKET_ON_KICK then
            message = string.gsub(TICKET_MSG, '{HACK}', message);
            api.submitTicket(message, function()
                if disconnect then api.disconnect() end
            end)
        else
            if disconnect then api.disconnect() end
        end
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
                -- (Update modules that run more than once)
                runModules();

                -- (No need to do anything else if disconnected)
                if disconnected then return end
                
                -- Generate the expected client-key fragment.
                local serverFragment = packet.data.message;
                local clientFragment = clientKey(getPlayer());
                
                -- Send back the next packet as encrypted with the new key.
                key = serverFragment .. clientFragment;
                
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
