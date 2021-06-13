RLCore = nil
TriggerEvent('RLCore:GetObject', function(obj) RLCore = obj end)


RLCore.Functions.CreateCallback("getmoney31", function (source,cb)
    local xPlayer = RLCore.Functions.GetPlayer(source)
    cb(xPlayer.Functions.GetMoney("cash"))
end)