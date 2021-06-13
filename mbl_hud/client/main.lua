RLCore = nil
local characterInfoSheetCooldown = false
GLOBAL_PED = nil
local directions = { [0] = 'North Bound', [45] = 'North West', [90] = 'West Bound', [135] = 'South West', [180] = 'South Bound', [225] = 'South East', [270] = 'East Bound', [315] = 'North East', [360] = 'North Bound', } 
local playerLoaded = false
local playerData = nil
local pauseOpen = false
local showVehicleHud = false
local currentHunger, currentThirst, currentDrugs, currentStress, currentDrunk = 100, 100, 0, 0, 0
local inVehicle = false
local onCruiseControl = false



CreateThread(function ()
    while RLCore == nil do
        Citizen.Wait(0)
        TriggerEvent("RLCore:GetObject", function(obj) RLCore = obj end)
    end
end)


RegisterNetEvent("RLCore:Client:OnPlayerLoaded")
AddEventHandler("RLCore:Client:OnPlayerLoaded", function ()
    playerLoaded = true
end)

RegisterNetEvent('mbl_hud:client:toggleLogo')
AddEventHandler('mbl_hud:client:toggleLogo', function(toggle)
    if playerLoaded then
    SendNUIMessage({
        action = "toggleLogo",
        toggle = toggle,
    })
end
end)

Citizen.CreateThread(function()
    while true do
        if playerLoaded then
            local temp = PlayerPedId()
            inVehicle = IsPedInAnyVehicle(GLOBAL_PED)
            if GLOBAL_PED ~= temp then
                GLOBAL_PED = temp
            end
        end
        Citizen.Wait(200)
    end
end)

function openCharacterInfoSheet()
    characterInfoSheetCooldown = true
    SendNUIMessage({
        action = "showCharacterSheet",
    })
end

function updateClock()
    local hour, minute
    if GetClockHours() < 10 then
        hour = '0'..GetClockHours()
    else
        hour = GetClockHours()
    end
    if GetClockMinutes() < 10 then
        minute = '0'..GetClockMinutes()
    else
        minute = GetClockMinutes()
    end
    local time = hour..':'..minute
    SendNUIMessage({
        action = "updateClock",
        time = time
    })
end
Citizen.CreateThread(function()
    while true do
      InvalidateIdleCam()
      N_0x9e4cfff989258472()
      Wait(10000)
    end
end)

function updatePosition()
    local playerPed = GetPlayerPed(-1)
    local playerCoords = GetEntityCoords(playerPed)
    local street, cross = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
    local streetName = GetStreetNameFromHashKey(street)
    local crossName
    if cross ~= nil then
        crossName =  ', '..GetStreetNameFromHashKey(cross)
    else
        crossName = ''
    end

    for k,v in pairs(directions)do
        direction = GetEntityHeading(playerPed)
        if(math.abs(direction - k) < 22.5)then
            direction = v
            break
        end
    end

    SendNUIMessage({
        action = "updateStreet",
        street = streetName..crossName,
        heading = direction
    })
end

function updateStats()
    if playerLoaded then
    if RLCore ~= nil and   RLCore.Functions.GetPlayerData() ~= nil then
        RLCore.Functions.GetPlayerData(function(dt)
            if dt ~= nil then

            local currentHealth = (GetEntityHealth(PlayerPedId()) - 100)
            SendNUIMessage({
                action = "updateStats",
                healthBar = currentHealth,
                hunger = dt.metadata.hunger,
                thirst = dt.metadata.thirst,
                drugs = dt.metadata.drugpoint,
                stress = dt.metadata.stress,
                drunk = dt.metadata.drunk,
                armour = GetPedArmour(PlayerPedId())
            })
            end
        end)
    end
end
end


Citizen.CreateThread(function()
    while true do
        updateClock()
        updatePosition()
        updateStats()
        Citizen.Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        if inVehicle then
            local vehicle = GetVehiclePedIsIn(GLOBAL_PED, false)
            local current = GetEntitySpeed(vehicle)
            local mph = (current * 3.6)
            local speedPer = (mph / 245 * 100)
            local curRPM = GetVehicleCurrentRpm(vehicle)
            SendNUIMessage({
                action = "updateVehicleSpeed",
                percent = math.ceil(speedPer),
                mph = math.ceil(mph),
                rpm = math.ceil((curRPM * 100))
            })
        else
            Citizen.Wait(1000)
        end
    end
end)

exports('toggleHud', function(toggle)
    if toggle then
        SendNUIMessage({
            action = "enableHud",
        })
    else
        SendNUIMessage({
            action = "disableHud",
        })
    end
end)

exports('toggleMiniMap', function(toggle)
    DisplayRadar(toggle)
end)

Citizen.CreateThread(function()
    while true do
        if playerLoaded then
            if IsPauseMenuActive() then
                if not pauseOpen then
                    SendNUIMessage({
                        action = "disableHud",
                    })
                    pauseOpen = true
                end
            else
                if pauseOpen then
                    SendNUIMessage({
                        action = "enableHud",
                    })
                    pauseOpen = false
                end
            end
            if GLOBAL_PED ~= nil and GLOBAL_PED > 0 then
                if inVehicle then
                    if not showVehicleHud then
                        DisplayRadar(true)
                        SendNUIMessage({
                            action = "enableVehicleHud",
                        })
                        showVehicleHud = true
                    end
                else
                    if showVehicleHud then
                        DisplayRadar(false)
                        SendNUIMessage({
                            action = "disableVehicleHud",
                        })
                        showVehicleHud = false
                    end
                end
            end
        end
        Citizen.Wait(200)
    end
end)

RegisterNetEvent('RLCore:Client:OnPlayerLoaded')
AddEventHandler('RLCore:Client:OnPlayerLoaded', function()
    if RLCore ~= nil then
            SendNUIMessage({
                action = "enableHud",
            })
            playerLoaded = true
           
            playerData = RLCore.Functions.GetPlayerData()
            RLCore.Functions.TriggerCallback("getmoney31", function(money)
                print(money)
            SendNUIMessage({
                action = "updateHudInformation",
                playerName = playerData.charinfo.firstname.." "..playerData.charinfo.lastname,
                playerCash = money,
                playerId = GetPlayerServerId(PlayerId()),
        })
    end)
end
end)

RegisterNetEvent('RLCore:Client:OnPlayerUnLoaded')
AddEventHandler('RLCore:Client:OnPlayerUnLoaded', function(unload, ready, data)
playerData = nil
playerLoaded = false
inVehicle = false
DisplayRadar(false)
showVehicleHud = false
end)

RegisterNetEvent('mbl:characters:cashAdjustment')
AddEventHandler('mbl:characters:cashAdjustment', function(amount)
    if RLCore ~= nil then
    if playerData then
        playerData.cash = tonumber(amount)
        SendNUIMessage({
            action = "updateCash",
            playerCash = playerData.cash,
        })
    end
end
end)

RegisterNetEvent('mbl_hud:client:updateRadioChannel')
AddEventHandler('mbl_hud:client:updateRadioChannel', function(show, channel)
    SendNUIMessage({
        action = "updateRadioChannel",
        radioTrue = show,
        channel = channel
    })
end)

RegisterNetEvent('mbl_hud:client:updateTalking')
AddEventHandler('mbl_hud:client:updateTalking', function(html)
    SendNUIMessage({
        action = "updateCurrentlySpeaking",
        html = html,
    })
end)

RegisterNetEvent('mbl_hud:client:updateVoiceLevel')
AddEventHandler('mbl_hud:client:updateVoiceLevel', function(level)
    SendNUIMessage({
        action = "voiceLevel",
        level = level
    })
end)

RegisterNetEvent('mbl:switchCharacter')
AddEventHandler('mbl:switchCharacter', function()
    SendNUIMessage({
        action = "disableHud",
    })
end)

RegisterNUICallback("showCharacterSheetCooldownReset", function(data, cb)
    characterInfoSheetCooldown = false
end)

CreateThread(function ()
    RegisterCommand("+hud", OpenHud)
    RegisterKeyMapping("+hud", "Hudu aç", "keyboard", "capslock")
end)



OpenHud = function ()
    if IsControlPressed(0, 137) and IsControlReleased(0, 137) then end
    if not characterInfoSheetCooldown then
        openCharacterInfoSheet()
    end
end
