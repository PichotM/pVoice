pVoice = {}
pVoice.Config = {}
pVoice.Config.Phrases = {}

if IsDuplicityVersion() then
    pVoice.Config["use3dAudio"] = true
    pVoice.Config["useSendingRangeOnly"] = true
else
    pVoice.Config["switchModeDefaultKey"] = "f6"
    pVoice.Config.Phrases["switchVoiceMode"] = "Changer l'intensité de votre voix"
    pVoice.Config.Phrases["switchModeNotif"] = "Nouvelle intensité définie:"

    pVoice.Config.VoiceModes = {
        { name = "Chuchotement", distance = 4 },
        { name = "Normal", distance = 10 },
        { name = "Crier", distance = 20 },
    }
end

local debugMode = not IsDuplicityVersion()
local resourceName = GetCurrentResourceName()
function debugMessage(message)
    if not debugMode then return end
    print(("^2[%s] ^3%s^7"):format(resourceName, message))
end