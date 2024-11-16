local ModLoader = require 'asledgehammer/modloader/ModLoader';
local ZedCrypt = require 'asledgehammer/encryption/ZedCrypt';

if not isServer() then return end

(function()
    local onServerStart = function()
        ModLoader.requestServerFile('etherhammer', 'EtherHammer_Client.lua', true, function(module, path, result, data)
            if result == ModLoader.RESULT_FILE_NOT_FOUND then
                print('[ModLoader] :: File not found: module=' .. module .. ', path=' .. path);
                return;
            end
            print('[ModLoader] :: File cached: module=' .. module .. ', path=' .. path);
            return ZedCrypt.encrypt(data, 'EtherHammer');
        end);
        ModLoader.requestServerFile('etherhammer', 'EtherHammer_Server.lua', true, function(module, path, result, data)
            if result == ModLoader.RESULT_FILE_NOT_FOUND then
                print('[ModLoader] :: File not found: module=' .. module .. ', path=' .. path);
                return;
            end
            pcall(function()
                loadstring(data)();
            end);
            print('[ModLoader] :: File loaded: module=' .. module .. ', path=' .. path);
        end);
    end

    Events.OnServerStarted.Add(onServerStart);
end)();
