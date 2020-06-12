local voiceMode = 2
local notificationId
local radioMuted = false

local zoneRadius = 64

local phoneTargets = {}
local radioTargets = {}
local interiorTargets = {}

local radioChannel = -1
local currentGrid = 0

local registeredPlayers = {}

local voiceTarget = 1
local radioAnimationDict = "random@arrests"

local radioAnim = false
local localTalking = false

local defaultVolume = 0.2

-- Local
local math = math
local playerid
-- Script

function pVoice:initializeMumbleConfig()
    NetworkSetTalkerProximity(self.Config.VoiceModes[voiceMode].distance + .0)
    MumbleSetVoiceTarget(0)
    MumbleClearVoiceTarget(voiceTarget)
    MumbleSetVoiceTarget(voiceTarget)

    currentGrid = 0
    self:intervalGrid()

    ShowAboveRadarMessage("~g~[pVoice]~w~ Le vocal vient de se lancer.. Pensez à connecter votre radio si vous étiez déjà connecté.")
    debugMessage("Initialized!")
end


function pVoice:initialize()
    playerid = PlayerId()

    self:loadEvents()
    self:registerSwitchVoiceKey()

    RequestAndWaitDict(radioAnimationDict)
    self:initializeMumbleConfig()

    table.insert(self.Config.VoiceModes[voiceMode], { name = "Mégaphone", distance = 40, canUse = false })
    debugMessage("Initialized!")

    CreateThread(function()
        while true do
            Wait(0)

            pVoice:think()
        end
    end)

    CreateThread(function()
        while true do
            Wait(3000)

            pVoice:intervalGrid()
        end
    end)

    RegisterCommand("voicesync", function()
        pVoice:initializeMumbleConfig()
    end)
end

function pVoice:addPlayerToVoiceTarget(serverId)
    serverId = tonumber(serverId)
	if not serverId or serverId == -1 then return end

    if not registeredPlayers[serverId] then
        MumbleAddVoiceTargetPlayerByServerId(voiceTarget, serverId)
        registeredPlayers[serverId] = true
    end
end

function pVoice:getGridZone()
    local plPos = GetEntityCoords(PlayerPedId(), false)
	return 100 + math.ceil((plPos.x + plPos.y) / (zoneRadius * 2))
end

function pVoice:registerSwitchVoiceKey()
    RegisterKeyMapping("+switchVoiceMode", self.Config.Phrases["switchVoiceMode"], "keyboard", self.Config.switchModeDefaultKey)
    RegisterCommand("+switchVoiceMode", function() pVoice:switchVoiceMode() end, false)
    RegisterCommand("-switchVoiceMode", function() end, false)
end

function pVoice:switchVoiceMode(newModeIndex)
    local newMode
    if not newModeIndex then
        newModeIndex = voiceMode + 1
        newMode = self.Config.VoiceModes[newModeIndex]

        local ped = PlayerPedId()
        while not newMode or (newMode.canUse and not newMode.canUse(ped)) do
            newModeIndex = newModeIndex >= #self.Config.VoiceModes and 0 or newModeIndex + 1
            newMode = self.Config.VoiceModes[newModeIndex]
        end
    else
        newMode = self.Config.VoiceModes[newModeIndex]
    end

    voiceMode = newModeIndex
    NetworkSetTalkerProximity(newMode.distance + 0.0)
    SendNUIMessage({ type = "updateMode", mode = newModeIndex })

    if notificationId then RemoveNotification(notificationId) end
    notificationId = ShowAboveRadarMessage(self.Config.Phrases["switchModeNotif"] .. "\n~g~" .. newMode.name)
end

function pVoice:togglePhoneTarget(playerServerId, enabled)
    playerServerId = tonumber(playerServerId)

    debugMessage(("togglePhoneTarget - %s - %s"):format(playerServerId, enabled))
    if enabled then
        MumbleSetVolumeOverrideByServerId(playerServerId, 1.0)
        pVoice:addPlayerToVoiceTarget(playerServerId)

        phoneTargets[playerServerId] = true
    else
        MumbleSetVolumeOverrideByServerId(playerServerId, -1.0)
        phoneTargets[playerServerId] = nil

        self:setVoiceTargets()
    end
end

function pVoice:toggleRadioTarget(playerServerId, enabled, isMuted)
    playerServerId = tonumber(playerServerId)

    debugMessage(("toggleRadioTarget - %s - %s - %s"):format(playerServerId, enabled, isMuted))
    if enabled then
        if not isMuted then
            MumbleSetVolumeOverrideByServerId(playerServerId, defaultVolume)
        end

        pVoice:addPlayerToVoiceTarget(playerServerId)

        radioTargets[playerServerId] = true
    else
        MumbleSetVolumeOverrideByServerId(playerServerId, -1.0)
        radioTargets[playerServerId] = nil
    end
end

function pVoice:addPlayerToRadio(newMember, muted)
    debugMessage(("addPlayerToRadio - %s"):format(newMember))
    self:toggleRadioTarget(newMember, true, muted)
end

function pVoice:addPlayersToRadio(members, channel)
    debugMessage(("addPlayersToRadio - %s - %s"):format(channel, json.encode(members)))
    radioChannel = channel

    for k, muted in pairs(members) do
        print(k)
        self:toggleRadioTarget(k, true, muted)
    end
end

function pVoice:removePlayerFromRadio(playerServerId, muted)
    playerServerId = tonumber(playerServerId)

    debugMessage(("removePlayerFromRadio - %s - %s"):format(playerServerId, muted))
    self:toggleRadioTarget(playerServerId, false, muted)
    self:setVoiceTargets()
end

function pVoice:removeRadio()
    debugMessage("removeRadio")
    
    for serverId, _ in pairs(radioTargets) do
        MumbleSetVolumeOverrideByServerId(tonumber(serverId), -1.0)
    end

    radioTargets = {}
    radioChannel = -1

    self:setVoiceTargets()
end

function pVoice:toggleRadioMute(mute)
    radioMuted = mute
    self:setVoiceTargets()
    TriggerServerEvent("pvoice_s:toggleRadioMute", radioChannel, radioMuted)
end

function pVoice:updatePlayersInInstance(players, resetAll)
    if resetAll then
        interiorTargets = {}
        NetworkSetVoiceChannel(currentGrid)
    else
        MumbleClearVoiceTargetChannels(voiceTarget)
        interiorTargets = players
    end

    self:setVoiceTargets()
end

function pVoice:updatePlayerMuteRadio(serverId, muted)
    serverId = tonumber(serverId)

    debugMessage(("updatePlayerMuteRadio - %s - %s - %s"):format(serverId, muted, radioChannel))
    if radioChannel == -1 then return end

    if muted then
        MumbleSetVolumeOverrideByServerId(serverId, -1.0)
    else
        MumbleSetVolumeOverrideByServerId(serverId, defaultVolume)
    end
end

local function addEventListener(eventName, functionName, isNet)
    if isNet then
        RegisterNetEvent(eventName)
    end

    AddEventHandler(eventName, function(...) pVoice[functionName](pVoice, ...) end)
end

function pVoice:loadEvents()
    addEventListener("pvoice:addPlayerToRadio", "addPlayerToRadio", true)
    addEventListener("pvoice:addPlayersToRadio", "addPlayersToRadio", true)
    addEventListener("pvoice:removePlayerFromRadio", "removePlayerFromRadio", true)
    addEventListener("pvoice:removeRadio", "removeRadio", true)
    addEventListener("pvoice:updatePlayerMuteRadio", "updatePlayerMuteRadio", true)

    addEventListener("pvoice:togglePhoneTarget", "togglePhoneTarget")
    addEventListener("pvoice:toggleRadioMute", "toggleRadioMute")
    addEventListener("pvoice:updatePlayersInInstance", "updatePlayersInInstance")
    addEventListener("pvoice:switchVoiceMode", "switchVoiceMode")
end

function pVoice:think()
    if radioChannel ~= -1 and not radioAnim and not radioMuted and IsControlJustPressed(0, 249) and GM.State.RadioID[1] and GM.State.RadioID[1] == "Radio" then
        radioAnim = true
        TaskPlayAnim(PlayerPedId(), radioAnimationDict, "generic_radio_chatter", 8.0, 0.0, -1, 49, 0, false, false, false)
    end

    if radioAnim and not IsControlPressed(0, 249) then
        radioAnim = false
        StopAnimTask(PlayerPedId(), radioAnimationDict, "generic_radio_chatter", -4.0)
    end

    if not localTalking and NetworkIsPlayerTalking(playerid) then
        localTalking = true
        SendNUIMessage({ type = "startSpeaking" })
    elseif localTalking and not NetworkIsPlayerTalking(playerid) then
        localTalking = false
        SendNUIMessage({ type = "stopSpeaking" })
    end
end

function pVoice:setVoiceTargets()
    registeredPlayers = {}

    MumbleClearVoiceTarget(voiceTarget)
    MumbleAddVoiceTargetChannel(voiceTarget, currentGrid)
    MumbleAddVoiceTargetChannel(voiceTarget, currentGrid - 1)
    MumbleAddVoiceTargetChannel(voiceTarget, currentGrid + 1)

    for serverId, _ in pairs(phoneTargets) do
        pVoice:addPlayerToVoiceTarget(serverId)
    end

    if not radioMuted then
        for serverId, _ in pairs(radioTargets) do
            pVoice:addPlayerToVoiceTarget(serverId)
        end
    end

    for _, serverId in pairs(interiorTargets) do
        pVoice:addPlayerToVoiceTarget(serverId)
    end
end

function pVoice:intervalGrid()
    local newGrid = self:getGridZone()
    if newGrid ~= currentGrid then
        currentGrid = newGrid
        NetworkSetVoiceChannel(currentGrid)
        MumbleClearVoiceTargetChannels(3)
        MumbleAddVoiceTargetChannel(3, currentGrid)
    end
end

local currentTalker
function TogglePhoneListener(serverId, intType, channeId)
	if intType then
		MumbleAddVoiceTargetPlayerByServerId(3, serverId)
		currentTalker = serverId
	else
		serverId = serverId or currentTalker
		MumbleClearVoiceTargetPlayers(3)
	end
end
exports('TogglePhoneListener', TogglePhoneListener)

CreateThread(function()
    NetworkSetTalkerProximity(0.01)
    Wait(5000)
    pVoice:initialize()
end)