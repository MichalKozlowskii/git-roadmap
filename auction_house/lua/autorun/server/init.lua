util.AddNetworkString("auction_house_create_auction")
util.AddNetworkString("auction_house_bid")
util.AddNetworkString("auction_house_fetch_auctions")
util.AddNetworkString("auction_house_fetch_items_to_claim")
util.AddNetworkString("auction_house_fetch_money_to_claim")
util.AddNetworkString("auction_house_item_claim")
util.AddNetworkString("auction_house_money_claim")
util.AddNetworkString("auction_house_openUI")

local tblAuctions = tblAuctions or {}

local function fetchAuctions()
    net.Start("auction_house_fetch_auctions")
    if table.IsEmpty(tblAuctions) then
        auction_house_db:getAuctionsTable(function(data)
            tblAuctions = data
            net.WriteTable(tblAuctions)
            net.Broadcast()
        end)
    else
        net.WriteTable(tblAuctions)
        net.Broadcast()
    end
end

local function fetchItemsToClaim()
    auction_house_db:getItemsToClaim(function(data)
        net.Start("auction_house_fetch_items_to_claim")
        net.WriteTable(data)
        net.Broadcast()
    end)
end

local function fetchMoneyToClaim()
    auction_house_db:getMoneyToClaim(function(data)
        net.Start("auction_house_fetch_money_to_claim")
        net.WriteTable(data)
        net.Broadcast()
    end)
end

local function getItemNames(ply) 
    local inv = ply.Inventory
    tblItemNames = {}
    
    for _, item in pairs(inv:GetItems()) do
        local strItemName = item:GetName()
        table.insert(tblItemNames, strItemName)
    end

    auction_house_db:getItemDetails(function(data)
        for _, item in pairs(inv:GetItems()) do
            local strItemName = item:GetName()
            local bItemFound = false

            for i, v in ipairs(data) do
                if v.item_name == strItemName then
                    bItemFound = true
                    break
                end
            end

            local tblData = table.Copy(item.Data)
            tblData.Amount = 1

            if !bItemFound then 
                auction_house_db:addItem(strItemName, item:GetClass(), util.TableToJSON(tblData)) 
            end
        end
    end)

    return tblItemNames
end

function auction_house_openUI(ply)
    net.Start("auction_house_openUI")
    net.WriteTable(getItemNames(ply))
    net.Send(ply)

    fetchAuctions()
    timer.Simple(1, function()
        fetchItemsToClaim()
    end)
    timer.Simple(1, function()
        fetchMoneyToClaim()
    end)
end

hook.Add( "PlayerSay", "auction_house_playersay", function( ply, text )
    if string.lower(text) == "!auctions" then
        auction_house_openUI(ply)
    end
end)

concommand.Add("auction_house", function(ply)
    auction_house_openUI(ply)
end)

-- claiming items -- 

net.Receive("auction_house_item_claim", function(len, ply)
    local intID = net.ReadInt(32)
    auction_house_db:getItemsToClaim(function(data)
        for i, v in ipairs(data) do
            if v.id == intID then 
                if v.player_id == ply:SteamID64() then
                    auction_house_db:getItemDetails(function(data)
                        for index, value in ipairs(data) do
                            if v.item_name == value.item_name then
                                local tblItemData = util.JSONToTable(value.data)
                                local item = itemstore.Item(value.item_class, tblItemData)
                                local inv = ply.Inventory

                                if inv:AddItem(item, false) == false then 
                                    DarkRP.notify(ply, NOTIFY_ERROR, 2, "You don't have enough space in your inventory!")
                                else
                                    DarkRP.notify(ply, NOTIFY_GENERIC, 2, "Item has been added to your inventory!")
                                    auction_house_db:onItemClaim(intID)
                                    fetchItemsToClaim()
                                end
                            end
                        end
                    end)
                else 
                    DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't claim item!")
                end
            end
        end
    end)
end)

-- claiming money --

net.Receive("auction_house_money_claim", function(len, ply)
    local intID = net.ReadInt(32)
    auction_house_db:getMoneyToClaim(function(data)
        for i, v in ipairs(data) do
            if v.id == intID then
                if v.player_id == ply:SteamID64() then
                    ply:addMoney(v.money_amount)
                    auction_house_db:onMoneyClaim(v.id) 
                    DarkRP.notify(ply, NOTIFY_GENERIC, 2, "You've succesfully claimed your money!")
                    fetchMoneyToClaim()
                else
                    DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't claim money!")
                end
            end
        end
    end)
end)

-- auctions --

local function updateAuctionsTable(tblAuctions, intBidPrice, intAuctionID, strBidderID)
    for i, v in ipairs(tblAuctions) do
        if v.id == intAuctionID then 
            if v.fixed_bid == 0 then
                if intBidPrice > v.actual_price then 
                    tblAuctions[i].actual_price = intBidPrice
                    tblAuctions[i].actual_winner_id = strBidderID
                    auction_house_db:onNewBid(intAuctionID, intBidPrice, strBidderID)
                end
            else 
                if intBidPrice >= v.actual_price + v.fixed_bid then 
                    tblAuctions[i].actual_price = intBidPrice
                    tblAuctions[i].actual_winner_id = strBidderID
                    auction_house_db:onNewBid(intAuctionID, intBidPrice, strBidderID)
                end
            end
            if os.time() - v.end_time <= auctionHouse.IncreaseTimeThreshold then -- extend auction's end time if threshold exceeded
                auction_house_db:setAuctionEndTime(v.id, v.end_time + auctionHouse.AmountOfTimeToAdd)
                tblAuctions[i].end_time = v.end_time + auctionHouse.AmountOfTimeToAdd
            end
        end
    end
    fetchAuctions()
end

local function onAuctionEnd(tblAuctions)
    for i, v in ipairs(tblAuctions) do
        if os.time() >= v.end_time then 

            local strWinnerID = ""
            if v.actual_winner_id == "0" then 
                strWinnerID = v.seller_id
            else 
                strWinnerID = v.actual_winner_id
            end

            auction_house_db:newItemToClaim(strWinnerID, v.item_name)

            auction_house_db:endAuction(v.id) 
            table.remove(tblAuctions, i)
            fetchAuctions()

            timer.Simple(1, function()
                fetchItemsToClaim()
            end)
        end
    end
end

local function createAuction(len, ply)
    if !ply:IsValid() then return end
    
    local strSellerID = tostring(ply:SteamID64())
    local strSellerName = ply:Name()
    local strItemName = net.ReadString()
    local intFixedBid = net.ReadInt(32)
    local intStartingPrice = net.ReadInt(32)
    local intDaysCount = net.ReadInt(32)
    local intHoursCount = net.ReadInt(32)
    local intMinutesCount = net.ReadInt(32)

    if intDaysCount == 0 and intHoursCount == 0 and intMinutesCount == 0 then 
        DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't create auction! (Invalid time)")
        return 
    end

    if intFixedBid != 0 then 
        if intFixedBid < auctionHouse.minFixedBid or intFixedBid > auctionHouse.maxFixedBid then
            DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't create auction! (Fixed bid too low or too high)")
            return
        end
    end

    if intStartingPrice < auctionHouse.minStartingPrice or intStartingPrice > auctionHouse.maxStartingPrice then
        DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't create auction! (Starting price too low or too high)")
        return
    end

    local intEndTime = os.time() + 3600 * 24 * intDaysCount + 3600 * intHoursCount + 60 * intMinutesCount

    local bItemFound = false

    for _, item in pairs(ply.Inventory:GetItems()) do
        if item:GetName() == strItemName then 
            bItemFound = true
            if item:GetAmount() > 1 then
                item:SetAmount(item:GetAmount() - 1)
                ply.Inventory:Sync()
            elseif item:GetAmount() == 1 then 
                local intSlot = item:GetSlot()
                ply.Inventory:SetItem(intSlot, nil)
            end
        end
    end

    if !bItemFound then
        DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't create auction! (You don't have the item)")
        return
    end

    auction_house_db:createAuction(strSellerID, strSellerName, intFixedBid, strItemName, intStartingPrice, "0", intEndTime)

    auction_house_db:getAuctionsTable(function(data)
        tblAuctions = data
        net.Start("auction_house_fetch_auctions")
        net.WriteTable(tblAuctions)
        net.Broadcast()
    end)

    DarkRP.notify(ply, NOTIFY_GENERIC, 2, "You've succesfully created a new auction!")

end
net.Receive("auction_house_create_auction", createAuction)


local function changeCurrentPrice(len, ply)
    local intBidPrice = net.ReadInt(32)
    local intAuctionID = net.ReadInt(32)
    local strBidderID = ply:SteamID64()

    if !ply:IsValid() then return end

    if !ply:canAfford(intBidPrice) then
        DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't make a bid! (You don't have enough money)")
        return
    end

    local bAuctionExists = false

    for i, v in ipairs(tblAuctions) do 
        if v.id == intAuctionID then 
            bAuctionExists = true
            if v.actual_winner_id == ply:SteamID64() then 
                DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't make a bid! (You are already winning)")
                return
            end

            if intBidPrice <= v.actual_price then 
                DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't make a bid! (Bid too low)")
                return 
            end
        end
    end

    if !bAuctionExists then 
        DarkRP.notify(ply, NOTIFY_ERROR, 2, "Couldn't make a bid! (Auction has ended)")
        return
    end

    -- return previous bidder's money
    for i, v in ipairs(tblAuctions) do
        if v.id == intAuctionID and v.actual_winner_id != "0" then 
            auction_house_db:addMoneyToClaim(v.actual_winner_id, v.actual_price)
            fetchItemsToClaim()
            break
        end
    end

    if table.IsEmpty(tblAuctions) then
        auction_house_db:getAuctionsTable(function(data)
            tblAuctions = data 
            updateAuctionsTable(tblAuctions, intBidPrice, intAuctionID, strBidderID)

        end)    
    else
        updateAuctionsTable(tblAuctions, intBidPrice, intAuctionID, strBidderID)
    end

    ply:addMoney(-intBidPrice)

    DarkRP.notify(ply, NOTIFY_GENERIC, 2, "You've succesfully made a bid on auction!")
end
net.Receive("auction_house_bid", changeCurrentPrice)


timer.Create("auction_house_delete_auction_timer", 1, 0, function()
    if table.IsEmpty(tblAuctions) then
        auction_house_db:getAuctionsTable(function(data)
            tblAuctions = data 
            onAuctionEnd(tblAuctions)
        end)
    else
        onAuctionEnd(tblAuctions)
    end
end)