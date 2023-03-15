local tblAuctions = tblAuctions or {}
local tblItemsToClaim = tblItemsToClaim or {}
local tblMoneyToClaim = tblMoneyToClaim or {}
local bShouldUpdate = false
local bShouldUpdateItems = false
local bShouldUpdateMoney = false

net.Receive("auction_house_fetch_auctions", function()
    tblAuctions = net.ReadTable()
    bShouldUpdate = true
end)

net.Receive("auction_house_fetch_items_to_claim", function()
    tblItemsToClaim = net.ReadTable()
    bShouldUpdateItems = true
end)

net.Receive("auction_house_fetch_money_to_claim", function()
    tblMoneyToClaim = net.ReadTable()
    bShouldUpdateMoney = true
end)

local function formatTimeStamp(seconds)
    seconds = tonumber(seconds) or 0

    local hourly_seconds = 60 * 60
    local daily_seconds = 24 * hourly_seconds


    local days = math.floor((seconds / daily_seconds) % 30)
    local hours = math.floor((seconds / hourly_seconds) % 24)
    local mins = math.floor((seconds / 60) % 60)
    local secs = math.floor(seconds % 60)

    return string.format("%ud %uh %um %us", days, hours, mins, secs)
end

local function activeAuctionsUI(parentPanel)
    if IsValid(parentPanel) then
        parentPanel:Clear()
        bShouldUpdate = true
    end

    local w, h = parentPanel:GetSize()

    local scroll = vgui.Create("DScrollPanel", parentPanel)

    scroll:Dock(FILL)
    scroll:DockMargin(w * 0.025, h * 0.025, w * 0.025, h * 0.025)

    timer.Create("auction_house_update_check_timer", 1, 0, function()
        if bShouldUpdate and IsValid(scroll) and scroll:IsVisible() then
            bShouldUpdate = false
            scroll:Clear()
            if table.IsEmpty(tblAuctions) then
                scroll.PaintOver = function(self, w, h)
                    draw.SimpleText("No active auctions now!", "auctions_panel_font", w * 0.5, h * 0.4, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            else 
                for i, v in ipairs(tblAuctions) do
                    local strSellerName = v.seller_name
                    local intFixedBid = v.fixed_bid

                    local auctionPanel = vgui.Create("DPanel", scroll)
                    auctionPanel:SetSize(0, h*0.15)
                    auctionPanel:Dock(TOP)
                    auctionPanel:DockMargin(0, 0, 0, 3)
                    auctionPanel.Paint = function(self, w, h) -- potem dojebac zeby czcionka mniejsza na mniejszym ekranie
                        local intTimeLeft = v.end_time - os.time()
                        local strTimeLeft = "Ends in: "..formatTimeStamp(intTimeLeft)

                        if os.time() >= v.end_time then 
                            strTimeLeft = "Auction has ended!"
                        end

                        draw.RoundedBox(5, 0, 0, w, h, PIXEL.CopyColor(PIXEL.Colors.Header))
                        draw.SimpleText("Seller: "..strSellerName, "auctions_panel_font18", w * 0.01, h * 0.1, COL, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText(strTimeLeft, "auctions_panel_font18", w * 0.315, h * 0.1, COL, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText("Current price: "..v.actual_price.."$", "auctions_panel_font18", w * 0.01, h * 0.6, COL, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText("Item: "..v.item_name, "auctions_panel_font18", w * 0.315, h * 0.6, COL, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        
                        if intFixedBid != 0 then 
                            draw.SimpleText("Fixed Bid: "..intFixedBid.."$", "auctions_panel_font18", w * 0.56, h * 0.1, COL, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        end
                    end

                    local bidButton = vgui.Create("PIXEL.Button", auctionPanel)
                    bidButton:SetPos(w * 0.8, 0)
                    bidButton:SetSize(w * 0.2, h)
                    bidButton.PaintExtra = function(w, h)
                        draw.SimpleText("Bid", "auctions_panel_font", 40, 25, Color(255,255,255,255))
                    end
                    bidButton.DoClick = function()
                        local bidFrame = vgui.Create("PIXEL.Frame")
                        bidFrame:SetSize(ScrW()/8, ScrH()/10)
                        bidFrame:Center()
                        bidFrame:SetTitle("Bid")
                        bidFrame:MakePopup()

                        local w, h = bidFrame:GetSize()

                        local bidEntry = vgui.Create("DNumberWang", bidFrame)
                        bidEntry:SetPos(w * 0.3, h* 0.4)
                        bidEntry:SetWide(w * 0.4)
                        bidEntry:HideWang()

                        local min = 0

                        if intFixedBid == 0 then 
                            min = v.actual_price + 1
                        else
                            min = v.actual_price + intFixedBid
                        end

                        bidEntry:SetMin(min)
                        bidEntry:SetValue(bidEntry:GetMin())
                        bidEntry.Paint = function(self, w, h)
                            draw.RoundedBox(0, 0, 0, w, h, Color(22, 22, 22))
                            self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
                        end
                        bidEntry.Think = function()
                            if bidEntry:GetValue() < bidEntry:GetMin() then
                                bidEntry:SetValue(bidEntry:GetMin())
                            end
                        end

                        local placeBidButton = vgui.Create("PIXEL.Button", bidFrame)
                        placeBidButton:SetPos(w * 0.3, h * 0.6)
                        placeBidButton:SetSize(w * 0.4, h * 0.2)
                        placeBidButton.PaintExtra = function(w, h)
                            draw.SimpleText("Bid", "auctions_panel_font18", 35, 2, Color(255,255,255,255))
                        end
                        placeBidButton.DoClick = function()
                            net.Start("auction_house_bid")
                            net.WriteInt(bidEntry:GetValue(), 32)
                            net.WriteInt(v.id, 32)
                            net.SendToServer()
                        end
                    end
                end
            end
        end
    end)
end

local function createAuctionUI(parentPanel, tblItemNames)

    if IsValid(parentPanel) then
        parentPanel:Clear()
    end

    local w, h = parentPanel:GetSize()

    local scroll = vgui.Create("DScrollPanel", parentPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(w * 0.025, h * 0.025, w * 0.025, h * 0.025)
    
    local itemList = vgui.Create("PIXEL.ComboBox", scroll)
    itemList:SetValue("Choose item")
    for i, v in ipairs(tblItemNames) do
        itemList:AddChoice(v)
    end

    local fixedBidEntry = vgui.Create("DNumberWang", scroll)
    fixedBidEntry:SetPos(w * 0.3, h* 0.08)
    fixedBidEntry:SetWide(w * 0.225)
    fixedBidEntry:SetMin(auctionHouse.minFixedBid)
    fixedBidEntry:SetMax(auctionHouse.maxFixedBid)
    fixedBidEntry:SetValue(auctionHouse.minFixedBid)
    fixedBidEntry.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(22, 22, 22))
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end
    fixedBidEntry.Think = function()
        if fixedBidEntry:GetValue() > fixedBidEntry:GetMax() then
            fixedBidEntry:SetValue(fixedBidEntry:GetMax())
        elseif fixedBidEntry:GetValue() < fixedBidEntry:GetMin() then
            fixedBidEntry:SetValue(fixedBidEntry:GetMin())
        end
    end
    fixedBidEntry:SetVisible(false)

    local fixedCheckbox = vgui.Create("PIXEL.LabelledCheckbox", scroll)
    fixedCheckbox:SetPos(w * 0.3, h * 0.01)
    fixedCheckbox:SetText("Fixed bid amount?")
    fixedCheckbox.bChecked = false
    fixedCheckbox.OnToggled = function(bToggled)
       if !fixedCheckbox.bChecked then
            fixedCheckbox.bChecked = true
       else
            fixedCheckbox.bChecked = false
       end
       fixedBidEntry:SetVisible(fixedCheckbox.bChecked)
    end

    local startingPriceLabel = vgui.Create("PIXEL.Label", scroll)
    startingPriceLabel:SetPos(w * 0.7, h * 0.013)
    startingPriceLabel:SetText("Starting price")
    startingPriceLabel:SetWide(w * 0.3)

    local startingPriceEntry = vgui.Create("DNumberWang", scroll)
    startingPriceEntry:SetPos(w * 0.7, h * 0.08)
    startingPriceEntry:SetWide(w * 0.14)
    startingPriceEntry:SetMin(auctionHouse.minStartingPrice)
    startingPriceEntry:SetMax(auctionHouse.maxStartingPrice)
    startingPriceEntry:SetValue(auctionHouse.minStartingPrice)
    startingPriceEntry.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(22, 22, 22))
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end
    startingPriceEntry.Think = function()
        if startingPriceEntry:GetValue() > startingPriceEntry:GetMax() then
            startingPriceEntry:SetValue(startingPriceEntry:GetMax())
        elseif startingPriceEntry:GetValue() < startingPriceEntry:GetMin() then
            startingPriceEntry:SetValue(startingPriceEntry:GetMin())
        end
    end

    local lastTimePanel = vgui.Create("DPanel", scroll)
    lastTimePanel:SetPos(0, h * 0.08)
    lastTimePanel:SetSize(w * 0.2, h * 0.2)
    lastTimePanel:SetVisible(true)
    lastTimePanel.Paint = function() end
    

    local pW, pH = lastTimePanel:GetSize()

    local lastTimeLabel = vgui.Create("PIXEL.Label", lastTimePanel)
    lastTimeLabel:SetText("Last time")
    lastTimeLabel:SetWide(pW)

    local daysLabel = vgui.Create("PIXEL.Label", lastTimePanel)
    daysLabel:SetText("Days:")
    daysLabel:SetPos(0, pH * 0.25)

    local daysEntry = vgui.Create("DNumberWang", lastTimePanel)
    daysEntry:SetPos(pW * 0.7, pH * 0.25)
    daysEntry:SetWide(pW * 0.3)
    daysEntry:SetMax(7)
    daysEntry.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(22, 22, 22))
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end
    daysEntry.Think = function()
        if daysEntry:GetValue() > daysEntry:GetMax() then
            daysEntry:SetValue(daysEntry:GetValue())
        end
    end

    local hoursLabel = vgui.Create("PIXEL.Label", lastTimePanel)
    hoursLabel:SetText("Hours:")
    hoursLabel:SetPos(0, pH * 0.5)

    local hoursEntry = vgui.Create("DNumberWang", lastTimePanel)
    hoursEntry:SetPos(pW * 0.7, pH * 0.5)
    hoursEntry:SetWide(pW * 0.3)
    hoursEntry:SetMax(23)
    hoursEntry.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(22, 22, 22))
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end
    hoursEntry.Think = function()
        if hoursEntry:GetValue() > hoursEntry:GetMax() then
            hoursEntry:SetValue(hoursEntry:GetValue())
        end
    end
    
    local minutesLabel = vgui.Create("PIXEL.Label", lastTimePanel)
    minutesLabel:SetText("Minutes:")
    minutesLabel:SetPos(0, pH * 0.75)

    local minutesEntry = vgui.Create("DNumberWang", lastTimePanel)
    minutesEntry:SetPos(pW * 0.7, pH * 0.75)
    minutesEntry:SetWide(pW * 0.3)
    minutesEntry:SetMax(59)
    minutesEntry.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(22, 22, 22))
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end
    minutesEntry.Think = function()
        if minutesEntry:GetValue() > minutesEntry:GetMax() then
            minutesEntry:SetValue(minutesEntry:GetValue())
        end
    end

    local createButton = vgui.Create("PIXEL.Button", scroll)
    createButton:SetPos(w * 0.75, h * 0.88)
    createButton:SetWide(w * 0.2)
    createButton.PaintExtra = function(w, h)
        draw.SimpleText("Create auction", "auctions_panel_font", 10, 3, Color(255,255,255,255), TEXT_ALIGN_LEFT)
    end
    createButton.DoClick = function()
        if !itemList:GetSelected() then return end
        if daysEntry:GetValue() == 0 and hoursEntry:GetValue() == 0 and minutesEntry:GetValue() == 0 then return end

        net.Start("auction_house_create_auction")
        net.WriteString(itemList:GetSelected())
        
        if fixedCheckbox.bChecked then 
            net.WriteInt(fixedBidEntry:GetValue(), 32)
        else
            net.WriteInt(0, 32)
        end

        net.WriteInt(startingPriceEntry:GetValue(), 32)
        net.WriteInt(daysEntry:GetValue(), 32)
        net.WriteInt(hoursEntry:GetValue(), 32)
        net.WriteInt(minutesEntry:GetValue(), 32)
        
        net.SendToServer()
    end
end

local function itemsToClaimUI(parentPanel)
    if IsValid(parentPanel) then
        parentPanel:Clear()
        bShouldUpdateItems = true
    end

    local w, h = parentPanel:GetSize()
    local scroll = vgui.Create("DScrollPanel", parentPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(w * 0.025, h * 0.025, w * 0.025, h * 0.025)

    timer.Create("auction_house_update_items_check_timer", 1, 0, function()
        if bShouldUpdateItems and IsValid(scroll) and scroll:IsVisible() then
            bShouldUpdateItems = false
            scroll:Clear()

            if table.IsEmpty(tblItemsToClaim) then
                scroll.PaintOver = function(self, w, h)
                    draw.SimpleText("No items to claim!", "auctions_panel_font", w * 0.5, h * 0.4, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            else
                local bFound = false

                for i, v in ipairs(tblItemsToClaim) do
                    if v.player_id == LocalPlayer():SteamID64() then
                        bFound = true

                        local itemsPanel = vgui.Create("DPanel", scroll)
                        itemsPanel:SetSize(0, h*0.15)
                        itemsPanel:Dock(TOP)
                        itemsPanel:DockMargin(0, 0, 0, 3)
                        itemsPanel.Paint = function(self, w, h)
                            draw.RoundedBox(5, 0, 0, w, h, PIXEL.CopyColor(PIXEL.Colors.Header))
                            draw.SimpleText(v.item_name, "auctions_panel_font18", w * 0.05, h * 0.3, COL, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        end

                        local claimButton = vgui.Create("PIXEL.Button", itemsPanel)
                        claimButton:SetPos(w * 0.8, 0)
                        claimButton:SetSize(w * 0.2, h)
                        claimButton.PaintExtra = function(w, h)
                            draw.SimpleText("Claim", "auctions_panel_font", 30, 25, Color(255,255,255,255))
                        end
                        claimButton.DoClick = function()
                            net.Start("auction_house_item_claim")
                            net.WriteInt(v.id, 32)
                            net.SendToServer()
                        end
                    end
                end

                if !bFound then 
                    scroll.PaintOver = function(self, w, h)
                        draw.SimpleText("No items to claim!", "auctions_panel_font", w * 0.5, h * 0.4, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end
        end
    end)
end

local function moneyToClaimUI(parentPanel)
    if IsValid(parentPanel) then
        parentPanel:Clear() 
        bShouldUpdateMoney = true
    end

    local w, h = parentPanel:GetSize()
    local scroll = vgui.Create("DScrollPanel", parentPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(w * 0.025, h * 0.025, w * 0.025, h * 0.025)

    timer.Create("auction_house_update_money_check_timer", 1, 0, function()
        if bShouldUpdateMoney and IsValid(scroll) and scroll:IsVisible() then
            bShouldUpdateMoney = false
            scroll:Clear()

            if table.IsEmpty(tblMoneyToClaim) then
                scroll.PaintOver = function(self, w, h)
                    draw.SimpleText("No money to claim!", "auctions_panel_font", w * 0.5, h * 0.4, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            else
                local bFound = false
                for i, v in ipairs(tblMoneyToClaim) do
                    if v.player_id == LocalPlayer():SteamID64() then
                        bFound = true

                        local itemsPanel = vgui.Create("DPanel", scroll)
                        itemsPanel:SetSize(0, h*0.15)
                        itemsPanel:Dock(TOP)
                        itemsPanel:DockMargin(0, 0, 0, 3)
                        itemsPanel.Paint = function(self, w, h)
                            draw.RoundedBox(5, 0, 0, w, h, PIXEL.CopyColor(PIXEL.Colors.Header))
                            draw.SimpleText(v.money_amount .. "$", "auctions_panel_font18", w * 0.05, h * 0.3, COL, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        end

                        local claimButton = vgui.Create("PIXEL.Button", itemsPanel)
                        claimButton:SetPos(w * 0.8, 0)
                        claimButton:SetSize(w * 0.2, h)
                        claimButton.PaintExtra = function(w, h)
                            draw.SimpleText("Claim", "auctions_panel_font", 30, 25, Color(255,255,255,255))
                        end
                        claimButton.DoClick = function()
                            net.Start("auction_house_money_claim")
                            net.WriteInt(v.id, 32)
                            net.SendToServer()
                        end
                    end
                end

                if !bFound then 
                    scroll.PaintOver = function(self, w, h)
                        draw.SimpleText("No money to claim!", "auctions_panel_font", w * 0.5, h * 0.4, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end
        end
    end)
end


local function drawUI()
    local tblItemNames = net.ReadTable()

    local frame = vgui.Create("PIXEL.Frame")
    frame:SetSize(ScrW() * 0.5, ScrH() * 0.5)
    frame:Center()
    frame:SetVisible(true)
    frame:SetTitle("Auction house")
    frame:MakePopup()

    local w, h = frame:GetSize()

    local side = vgui.Create("PIXEL.Sidebar", frame)
    side:Dock(LEFT)
    side:SetWide(w * 0.25)

    local panel = vgui.Create("DPanel", frame)
    panel:Dock(FILL)
    panel.Paint = function() end
    panel.Think = function()
        side:SelectItem("auction_house_active_auctions")

        panel.Think = function() end
    end


    side:AddItem("auction_house_active_auctions", "Active auctions", "nmFCQci", function()
        activeAuctionsUI(panel)
    end)

    side:AddItem("auction_house_create_auction", "Create auction", "H21BQUs", function()
        createAuctionUI(panel, tblItemNames)
    end)

    side:AddItem("auction_house_claim_items", "Claim items", "4BMsHRG" ,function()
        itemsToClaimUI(panel)
    end)

    side:AddItem("auction_house_claim_money", "Claim money", "4BMsHRG" ,function()
        moneyToClaimUI(panel)
    end)
end
net.Receive("auction_house_openUI", drawUI)