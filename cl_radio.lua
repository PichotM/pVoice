GM = { State = { RadioState = 0, RadioID = {}, RadioFrequence = 0 } }
local itemBounds = { ["Radio"] = {20, 130}, ["Oreillette"] = {30, 120} }
local mainFrequence

local function CanUseRadio()
	local itemName, itemNum = table.unpack(GM.State.RadioID)
	return itemName and itemNum
end

local notificationID
local function ToggleRadio()
	if not CanUseRadio() then TriggerEvent("pichot:toggleNUI", { radio = false }) return end

	local newMode = GM.State.RadioState == 0 and 1 or 0
	updateVar("RadioState", newMode)

	-- TODO NEW MODE
	TriggerEvent("pichot:toggleNUI", { radio = true, mode = newMode, freq = GM.State.RadioFrequence }, true, true)

	if notificationID then RemoveNotification(notificationID) end
	notificationID = ShowAboveRadarMessage("~b~Radio:\n~w~Vous avez " .. (newMode == 0 and "~r~éteint" or "~g~allumé") .. "~w~ votre radio.")
	PlayAudio("RADIO_BIP")

	if newMode == 0 then
		TriggerServerEvent("pvoice_s:removePlayerFromAllRadio", true)
	else
		TriggerServerEvent("pvoice_s:addPlayerToRadio", round(GM.State.RadioFrequence, 2), GM.State.RadioState == 2)
	end
end

-- RADIO STUFF
local function ClientRadioHandler(tbl)
	if not CanUseRadio() then TriggerEvent("pichot:toggleNUI", { radio = false }, false, false) return end

	local id = tbl.id or 0
	if id == 1 then -- Afficher radio
		ToggleRadio()
	elseif id == 2 then -- Mode muet
		local newState = GM.State.RadioState == 2 and 1 or 2

		updateVar("RadioState", newState)
		TriggerEvent("pichot:toggleNUI", { radio = not tbl.keep, mode = newState, freq = GM.State.RadioFrequence }, not tbl.keep, not tbl.keep)

		if notificationID then RemoveNotification(notificationID) end
		notificationID = ShowAboveRadarMessage("Vous avez " .. (newState == 2 and "~g~activé" or "~r~désactivé") .. "~w~ le mode muet de votre radio.")

		pVoice:toggleRadioMute(newState == 2)
	elseif id == 3 then -- Changer de fréquence
		local frequence = round(tbl.freq, 2)
		if frequence and frequence ~= GM.State.RadioFrequence then
			local min, max = table.unpack(itemBounds[GM.State.RadioID[1]])
			if frequence < min or frequence > max then
				ShowAboveRadarMessage("~r~Radio\n~w~Votre appareil ne peut atteindre cette fréquence.")
				frequence = frequence < min and min or max
			else
				updateVar("RadioFrequence", frequence)
				exports.gtalife:updateItem(GM.State.RadioID[1], GM.State.RadioID[2], { freq = frequence })
				if notificationID then RemoveNotification(notificationID) end
				notificationID = ShowAboveRadarMessage("~b~Fréquence selectionnée\n~w~" .. frequence .. "Hz")
				PlayAudio("RADIO_BIP")

				TriggerServerEvent("pvoice_s:addPlayerToRadio", round(frequence, 2), GM.State.RadioState == 2)
			end
		end
		TriggerEvent("pichot:toggleNUI", { radio = true, freq = frequence + .0 }, true, true)
	elseif id == 4 then -- Fréquence manuelle
		TriggerEvent("pichot:askEntry", function(_, n)
			ClientRadioHandler({ id = 3, freq = n and string.len(n) > 0 and tonumber(n) or GM.State.RadioFrequence })
		end, {}, "Fréquence", 6, GM.State.RadioFrequence)
	elseif id == 5 then -- Update fréquence UI
		TriggerEvent("pichot:toggleNUI", { radio = false, freq = GM.State.RadioFrequence + .0 }, false, false)
	elseif id == 6 then -- Eteindre radio?
		local newMode = GM.State.RadioState
		TriggerServerEvent("pvoice_s:removePlayerFromAllRadio", true)
		TriggerEvent("pichot:toggleNUI", { radio = true, mode = newMode, freq = GM.State.RadioFrequence }, true, true)
	elseif id == 7 then -- Bind flic
		local moveIndex = tbl.key
		local min, max = table.unpack(itemBounds["Radio"])
		local newFrequence = mainFrequence + 0.01 * moveIndex

		if not newFrequence or newFrequence < min or newFrequence > max then ShowAboveRadarMessage("~r~Fréquence hors de portée! 📡") return end
		ClientRadioHandler({ id = 3, freq = newFrequence })
	end
end

local function radioInit()
	local frequence = GetResourceKvpFloat("mainFreq")
	if frequence then
		local min, max = table.unpack(itemBounds["Radio"])
		if frequence >= min and frequence <= max then
			mainFrequence = frequence
		end
	end

	RegisterControlKey("openRadio", "Ouvrir la radio", "p", function()
		if exports.gcphone:IsPhoneOpen() then return end
		if not CanUseRadio() then
			ShowAboveRadarMessage("~r~Impossible\n~w~Vous n'avez pas de radio équipée.") TriggerEvent("pichot:toggleNUI", { radio = false }, false, false)
		else
			TriggerEvent("pichot:toggleNUI", { radio = true, freq = GM.State.RadioFrequence + .0, mode = GM.State.RadioState }, true, true)
		end
	end)

	RegisterControlKey("muteMeRadio", "Muter votre voix en radio", "l", function()
		if UpdateOnscreenKeyboard() == 0 then return end

		if GM.State.RadioState > 0 then
			ClientRadioHandler({ id = 2, keep = true })
		end
	end)
end

Citizen.CreateThread(function()
	radioInit()
end)

AddEventHandler("pichot_voip:clientRadio", ClientRadioHandler)

-- MISC STUFF
TriggerEvent("pichot_data:broadcastAll", function(a)
	for k,v in pairs(GM) do
		if a[k] ~= nil then GM[k] = a[k] end
	end
end)

AddEventHandler("pichot_data:varUpdated", function(varName, varValue, varOnValue)
	if not GM.State[varName] then return end

	if varOnValue then
		GM.State[varName] = GM.State[varName] or {}
		GM.State[varName][varOnValue] = varValue
	else
		GM.State[varName] = varValue
	end
end)

RegisterCommand("frequence", function(_, args)
	local frequence = round(tonumber(args[1] or 0) or 0, 2)
	local min, max = table.unpack(itemBounds["Radio"])
	if not frequence or frequence < min or frequence > max then ShowAboveRadarMessage("~r~Fréquence hors de portée! 📡") return end

	mainFrequence = frequence
	SetResourceKvpFloat("mainFreq", frequence)

	ShowAboveRadarMessage(string.format("Fréquence favorite définie sur ~b~%sHz~w~ 📡", frequence))
end)