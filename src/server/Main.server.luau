local Server = script.Parent

-- Services hook DataService.onLoaded in start(), so DataService starts loading players last.
require(Server.WorldBuilder).build()
require(Server.WorldService).start()
require(Server.MoveService).start()
require(Server.LotService).start()
require(Server.OrderService).start()
require(Server.GateService).start()
require(Server.ChaserService).start()
require(Server.RideService).start()
require(Server.ShopService).start()
require(Server.DataService).start()
