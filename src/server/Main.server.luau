local Server = script.Parent

-- Services hook DataService.onLoaded in start(), so DataService starts loading players last.
require(Server.WorldBuilder).build()
require(Server.LotService).start()
require(Server.OrderService).start()
require(Server.DataService).start()
