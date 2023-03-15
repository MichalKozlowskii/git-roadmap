auctionHouse = auctionHouse or {}

auctionHouse.minFixedBid = 200

auctionHouse.maxFixedBid = 100000

auctionHouse.minStartingPrice = 200

auctionHouse.maxStartingPrice = 100000

auctionHouse.IncreaseTimeThreshold = 10 -- for example, when it equals ten, it will increase auction's ending time by auctionHouse.AmountOfTimeToAdd when its less than 10 seconds left and someone bids

auctionHouse.AmountOfTimeToAdd = 20