---[[
--- EtherHammerX - Client Script.
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

    local api = { table = "CLIENT_API" };

    -- NOTE: Override the test-code with the production-code for reports.
    function api.report(type, reason, disconnect)
        local message = type;
        if reason then message = message .. ' (' .. reason .. ')' end
        local packet = Packet(MODULE_ID, { string = 'REPORT_COMMAND' }, { type = type, reason = reason });
        packet:encryptAndSendToServer(key);
        if disconnect then api.disconnect() end
    end

    -- Force the table to be read-only. Rogue or maliciously-injected modules won't be able to mutate the API table.
    api = readonly(api);

    Events.OnServerCommand.Add(function(packet_module, command, args)
        -- Ignore everything else.
        if packet_module ~= MODULE_ID then return end

        local packet = Packet(packet_module, command, args);
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
                for _, module in pairs(modules) do
                    if module.runOnce and module.code ~= nil then
                        module.code(api, module.options);
                        module.code = nil;
                    else
                        module.code(api, module.options);
                    end
                end

                -- (No need to do anything else if disconnected)
                if api.isDisconnected() then return end

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
