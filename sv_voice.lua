local radios = {}
-- TODO CLEAR radio with playerDropped etc..

function pVoice:initialize()
    SetConvarReplicated("voice_use2dAudio", 1)
    SetConvarReplicated("voice_useSendingRangeOnly", 1)

    self:loadEvents()
    debugMessage("Initialized!")

    for i = 1, 500 do
        MumbleCreateChannel(i)
    end
end

function pVoice:addPlayerToRadio(channelId, muted)
    local serverId = source
    channelId = tostring(channelId)

    debugMessage(("addPlayerToRadio - %s - %s - %s"):format(serverId, channelId, muted))

    radios[channelId] = radios[channelId] or { players = {} }

    for pl, isMuted in pairs(radios[channelId].players) do
        TriggerClientEvent("pvoice:addPlayerToRadio", pl, serverId, isMuted)
    end

    TriggerClientEvent("pvoice:addPlayersToRadio", serverId, radios[channelId].players, channelId)
    radios[channelId].players[serverId] = muted or false
end

RegisterCommand("printChannel", function(src, args)
    if src ~= 0 then return end
    PrintTable(radios[tostring(args[1])])
end)

function pVoice:removePlayerFromRadio(channelId)
    local serverId = source
    channelId = tostring(channelId)

    debugMessage(("removePlayerFromRadio - %s - %s"):format(serverId, channelId))
    local channel = radios[channelId]
    if channel and channel.players then
        channel.players[serverId] = nil
        if not tableCount(channel.players, 1) then
            radios[channelId] = nil
        else
            for pl, muted in pairs(channel.players) do
                TriggerClientEvent("pvoice:removePlayerFromRadio", pl, serverId)
            end
        end
    end

    TriggerClientEvent("pvoice:removeRadio", serverId)
end

function pVoice:removePlayerFromAllRadio(updateClient)
    local serverId = source
    debugMessage(("removePlayerFromAllRadio - %s - %s"):format(serverId, updateClient))
    for id, channel in pairs(radios) do
        if channel.players and channel.players[serverId] ~= nil then
            channel.players[serverId] = nil

            if not tableCount(channel.players, 1) then
                radios[id] = nil
            else
                for pl, muted in pairs(channel.players) do
                    TriggerClientEvent("pvoice:removePlayerFromRadio", pl, serverId, muted)
                end
            end
        end
    end

    if updateClient then
        TriggerClientEvent("pvoice:removeRadio", serverId)
    end
end

function pVoice:toggleRadioMute(channelId, toggle)
    local serverId = source
    channelId = tostring(channelId)

    debugMessage(("toggleRadioMute - %s - %s"):format(serverId, toggle))

    local channel = radios[channelId]
    if channel and channel.players[serverId] ~= nil then
        channel.players[serverId] = false
        for pl, muted in pairs(channel.players) do
            if pl ~= serverId then
                TriggerClientEvent("pvoice:updatePlayerMuteRadio", pl, serverId, toggle)
            end
        end
    end
end

local function addEventListener(eventName, functionName, isNet)
    if isNet then
        RegisterNetEvent(eventName)
    end

    AddEventHandler(eventName, function(...) pVoice[functionName](pVoice, ...) end)
end

function pVoice:loadEvents()
    addEventListener("pvoice_s:removePlayerFromRadio", "removePlayerFromRadio", true)
    addEventListener("pvoice_s:addPlayerToRadio", "addPlayerToRadio", true)
    addEventListener("pvoice_s:removePlayerFromAllRadio", "removePlayerFromAllRadio", true)
    addEventListener("pvoice_s:toggleRadioMute", "toggleRadioMute", true)
end

pVoice:initialize()