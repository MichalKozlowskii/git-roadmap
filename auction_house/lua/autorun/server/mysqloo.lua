require("mysqloo")

local auth = {
    Host = "localhost",
	Port = 3306,
	Username = "root",
	Password = "admin",
	Database = "auction_house"
}

auction_house_db = mysqloo.connect(auth.Host, auth.Username, auth.Password, auth.Database, auth.Port)


function auction_house_db:onConnected()
    local sql = [[CREATE TABLE IF NOT EXISTS `auction_house`.`auctions` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `seller_id` CHAR(17) NOT NULL,
        `seller_name` CHAR(30) NOT NULL,
        `fixed_bid` INT UNSIGNED NOT NULL,
        `item_name` VARCHAR(64) NOT NULL,
        `actual_price` INT UNSIGNED NOT NULL,
        `actual_winner_id` CHAR(17) NOT NULL,
        `end_time` BIGINT UNSIGNED NOT NULL,
        PRIMARY KEY (`id`))
      ENGINE = InnoDB;
      
      CREATE TABLE IF NOT EXISTS `auction_house`.`items_to_claim` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `player_id` CHAR(17) NOT NULL,
        `item_name` VARCHAR(64) NOT NULL,
        PRIMARY KEY (`id`))
      ENGINE = InnoDB;
      
      CREATE TABLE IF NOT EXISTS `auction_house`.`item_details` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `item_name` CHAR(64) NOT NULL,
        `item_class` CHAR(64) NOT NULL,
        `data` CHAR(200) NOT NULL,
        PRIMARY KEY (`id`))
      ENGINE = InnoDB;

      CREATE TABLE IF NOT EXISTS `auction_house`.`money_to_claim` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `player_id` CHAR(17) NOT NULL,
        `money_amount` BIGINT UNSIGNED NOT NULL,
        PRIMARY KEY (`id`))
      ENGINE = InnoDB;]]
    
    local q = self:query(sql)
    
    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end

    q:start()
end

auction_house_db:connect()


-- auctions --


function auction_house_db:createAuction(strSellerID, strSellerName, intFixedBid, strItemName, intActualPrice, strActualWinnerID, intEndtime)
    local sql = "INSERT INTO auctions (seller_id, seller_name, fixed_bid, item_name, actual_price, actual_winner_id, end_time) "
    sql = sql .. string.format("VALUES (%s, %s, %u, %s, %u, %s, %u)", auction_house_db:escape(strSellerID), "'"..auction_house_db:escape(strSellerName).."'", auction_house_db:escape(intFixedBid), "'"..auction_house_db:escape(strItemName).."'", auction_house_db:escape(intActualPrice), auction_house_db:escape(strActualWinnerID), auction_house_db:escape(intEndtime))

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print ( "Error:", err )
    end

    q:start()
end

function auction_house_db:getAuctionsTable(fnCallback)
    local sql = "SELECT * FROM auctions"
    
    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end
  
    function q:onSuccess(data)
        if fnCallback then
            fnCallback(data)
        end
    end

    q:start()
end

function auction_house_db:onNewBid(intID, intBidPrice, strBidderID)
    local sql = string.format("UPDATE auctions SET actual_price = %u, actual_winner_id = %s WHERE id = %u", auction_house_db:escape(intBidPrice), auction_house_db:escape(strBidderID), auction_house_db:escape(intID))

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end

    q:start()
end

function auction_house_db:setAuctionEndTime(intID, intTimeStamp) 
    local sql ="UPDATE auctions SET end_time = ".. auction_house_db:escape(intTimeStamp) .. " WHERE id = " .. auction_house_db:escape(intID)

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end

    q:start()
end

function auction_house_db:endAuction(intID) 
    local sql = "DELETE FROM auctions WHERE id = "..auction_house_db:escape(intID)

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end

    q:start()
end


-- claiming won items --


function auction_house_db:newItemToClaim(strPlayerID, strItemName)
    local sql = "INSERT INTO items_to_claim (player_id, item_name) "
    sql = sql .. string.format("VALUES (%s, %s)", auction_house_db:escape(strPlayerID), "'"..auction_house_db:escape(strItemName).."'")

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end

    q:start()
end

function auction_house_db:getItemsToClaim(fnCallback)
    local sql = "SELECT * FROM items_to_claim"
    
    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end
  
    function q:onSuccess(data)
        if fnCallback then
            fnCallback(data)
        end
    end

    q:start()
end

function auction_house_db:onItemClaim(intID) 
    local sql = "DELETE FROM items_to_claim WHERE id = "..auction_house_db:escape(intID)

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end

    q:start()
end

function auction_house_db:addItem(strItemName, strItemClass, strJSONData) 
    local sql = "INSERT INTO item_details (item_name, item_class, data) " .. string.format("VALUES(%s, %s, %s)", "'"..auction_house_db:escape(strItemName).."'", "'"..auction_house_db:escape(strItemClass).."'", "'"..auction_house_db:escape(strJSONData).."'")

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end

    q:start()
end

function auction_house_db:getItemDetails(fnCallback)
    local sql = "SELECT * FROM item_details"

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end
  
    function q:onSuccess(data)
        if fnCallback then
            fnCallback(data)
        end
    end

    q:start()
end


-- claiming returned money --


function auction_house_db:addMoneyToClaim(strPlayerID, intMoneyAmount)
    local sql = "INSERT INTO money_to_claim (player_id, money_amount) " .. string.format("VALUES(%s, %u)", auction_house_db:escape(strPlayerID), auction_house_db:escape(intMoneyAmount))

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end

    q:start()
end

function auction_house_db:getMoneyToClaim(fnCallback)
    local sql = "SELECT * FROM money_to_claim"

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end
  
    function q:onSuccess(data)
        if fnCallback then
            fnCallback(data)
        end
    end

    q:start()
end

function auction_house_db:onMoneyClaim(intID) 
    local sql = "DELETE FROM money_to_claim WHERE id = "..auction_house_db:escape(intID)

    local q = self:query(sql)

    function q:onError( err, sql )
        print( "Query errored!" )
        print( "Query:", sql )
        print( "Error:", err )
    end

    q:start()
end