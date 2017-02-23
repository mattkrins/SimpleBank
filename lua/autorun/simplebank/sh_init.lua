local SimpleBank = {}
SimpleBank.Version = 1.1

function SimpleBank:AddLanguage(phrase, phraseString, nationality)
	SimpleBankLanguage = SimpleBankLanguage or {}
	if !phrase or !phraseString then return false end
	SimpleBankLanguage[nationality or "en"] = SimpleBankLanguage[nationality or "en"] or {}
	SimpleBankLanguage[nationality or "en"][phrase] = phraseString
end
SimpleBank:AddLanguage("to", "to")
SimpleBank:AddLanguage("cancel", "cancel")
SimpleBank:AddLanguage("confirm", "confirm")
SimpleBank:AddLanguage("deposit", "deposit")
SimpleBank:AddLanguage("deposited", "deposited")
SimpleBank:AddLanguage("withdraw", "withdraw")
SimpleBank:AddLanguage("withdrew", "withdrew")
SimpleBank:AddLanguage("transfer", "transfer")
SimpleBank:AddLanguage("transferred", "transferred")
SimpleBank:AddLanguage("transferee", "transferee")
SimpleBank:AddLanguage("account", "account")
SimpleBank:AddLanguage("balance", "balance")
SimpleBank:AddLanguage("cash", "cash")
SimpleBank:AddLanguage("on_hand", "on hand")
SimpleBank:AddLanguage("bank", "bank")
SimpleBank:AddLanguage("atm", "atm")
SimpleBank:AddLanguage("eftpos", "eftpos")
SimpleBank:AddLanguage("slogan", "security deposit your hard earned cash.")
SimpleBank:AddLanguage("confirm_amount", "confirm amount before transferring")
SimpleBank:AddLanguage("transfer_alert", "receive transfer alerts from others")
SimpleBank:AddLanguage("are_you_sure_want", "are you sure you want to")
SimpleBank:AddLanguage("please_enter", "please enter the")
SimpleBank:AddLanguage("of_transfer_player", " of the player you wish to transfer to.")
SimpleBank:AddLanguage("select_from_server", "select from server")
SimpleBank:AddLanguage("device_asking_amount", "set the asking amount for this device")
SimpleBank:AddLanguage("set_player_choice", "Set to 0 to allow the player to choose")
SimpleBank:AddLanguage("you_received", "you received")
SimpleBank:AddLanguage("transferred_from", "transferred from")
SimpleBank:AddLanguage("please_confirm", "please confirm")
SimpleBank:AddLanguage("find_by", "find by")
SimpleBank:AddLanguage("online", "online")
SimpleBank:AddLanguage("offline", "offline")
SimpleBank:AddLanguage("name", "name")
SimpleBank:AddLanguage("set", "set")
SimpleBank:AddLanguage("pay", "pay")
SimpleBank:AddLanguage("into", "into")
SimpleBank:AddLanguage("error", "error")
SimpleBank:AddLanguage("player", "player")
SimpleBank:AddLanguage("doesnt_exist", "does not exist")
SimpleBank:AddLanguage("cant_afford", "you cant afford that")
SimpleBank:AddLanguage("cant_self_trans", "cant transfer to self")



function GetSimpleBank() return SimpleBank or false end
function SimpleBank:language(phrase, cap)
	if !phrase then return "ERROR" end
	local lang_Convar = GetConVar( "gmod_language" ) or false
	local text = "Error" SimpleBankLanguage = SimpleBankLanguage or {}
	if lang_Convar and lang_Convar:GetString() and SimpleBankLanguage[lang_Convar:GetString()] and SimpleBankLanguage[lang_Convar:GetString()][phrase] then
		text = SimpleBankLanguage[lang_Convar:GetString()][phrase] or "ERROR"
	else
		text = SimpleBankLanguage["en"][phrase] or "ERROR"
	end
	if cap then
		text = string.upper( string.sub( text, 1, 1 ) )..string.sub( text, 2 )
		if cap == 2 then text = string.upper( text ) end
	end return text
end
if SERVER then
	SimpleBank.Connected = false
	SimpleBank.table = {}
	function SimpleBank:GetGamemode()
		if gmod.GetGamemode() and gmod.GetGamemode().Name then return gmod.GetGamemode().Name else return "ERROR" end
	end
	function SimpleBank:gamemode(name)
		if !name then return false end if string.find( self:GetGamemode(), name) or GetConVar( "gamemode" ):GetString() == name then return true else return false end
	end
	function SimpleBank:Msg(message, color)
		MsgC( Color( 232, 164, 164 ), "SimpleBank: ", (color or color_white), (message or "Error.")," \n" )
	end
	function SimpleBank:Notify(ply, string, error, length, sound)
		if !IsValid(ply) then return false end
		local CustomFunction = hook.Call( "SimpleBankNotify", nil, ply, string, error, length, sound ) or false
		if CustomFunction then return CustomFunction end
		local soundFile = ""
		local icon = "NOTIFY_UNDO"
		if error then
			icon = "NOTIFY_ERROR"
			soundFile = " surface.PlaySound( 'buttons/button10.wav' )"
			if isstring(error) then icon = error end
		end
		if sound then
			soundFile = " surface.PlaySound( 'buttons/button15.wav' )"
			if isstring(sound) then soundFile = " surface.PlaySound( '"..sound.."' )" end
		end
		ply:ChatPrint( string or "Error." )
		ply:SendLua( "notification.AddLegacy( '"..(string or "Error.").."', "..icon..", "..(length or "2").." )"..soundFile )
		return true
	end
	function SimpleBank:Player(SteamID, Loop)
		if !SteamID then return false end
		if !self.Connected then if Loop then return false end self:Init() return self:Player(SteamID, true) end
		self.table = self.table or {}
		for k,v in pairs(self.table) do
		if v.Users == SteamID then return v end
		end return false
	end
	function SimpleBank:Read(SteamID, Loop)
		if !SteamID then return false end
		local found = self:Player(SteamID) or false
		if found then return (found.Balance or 0) else if Loop then return false end self:Init(SteamID) return self:Read(SteamID, true) end
	end
	function SimpleBank:Purge()
		MySQLite.begin()
			MySQLite.queueQuery("DROP TABLE IF EXISTS SimpleBank_Accounts;")
			MySQLite.queueQuery("DROP TABLE IF EXISTS SimpleBank_Transactions;")
			MySQLite.queueQuery("DROP TABLE IF EXISTS SimpleBank_Bills;")
			MySQLite.queueQuery("DROP TABLE IF EXISTS SimpleBank_Loans;")
		MySQLite.commit(function() self:Msg( "Database Purged.", Color(255,0,0) ) end)
		self.Connected = false
		self.table = {}
	end
	function SimpleBank:Convert()
		MySQLite.tableExists( "SimpleBank", function(exists)
			if !exists then return end
			MySQLite.query("SELECT * FROM SimpleBank;", function(data)
				for k,v in pairs(data) do
					if v.SteamID then MySQLite.query("INSERT INTO SimpleBank_Accounts ( Name, Users, Balance ) VALUES ( ''"..v.SteamID.."'', '"..v.SteamID.."', '"..(v.Balance or 0).."' );") end
				end
				MySQLite.query( "DROP TABLE IF EXISTS SimpleBank;", function() self:Msg( "Database Updated to version "..self.Version..".", Color(0,255,0) ) end )
			end)
		end)
	end
	function SimpleBank:Setup()
		self:Convert()
		MySQLite.begin()
			MySQLite.queueQuery("CREATE TABLE IF NOT EXISTS SimpleBank_Accounts ( Name string, Users string, Balance int );")
			MySQLite.queueQuery("CREATE TABLE IF NOT EXISTS SimpleBank_Transactions ( Account string, Recipient string, Amount int, DateTime int );")
			MySQLite.queueQuery("CREATE TABLE IF NOT EXISTS SimpleBank_Bills ( Account string, Amount int );")
			MySQLite.queueQuery("CREATE TABLE IF NOT EXISTS SimpleBank_Loans ( Account string, Amount int );")
		MySQLite.commit()
		self:Msg( "Database Built.", Color(0,255,0) )
	end
	function SimpleBank:Init(SteamID)
		if !MySQLite then print("SimpleBank: Failed to load as it requires MySQLite. You can grab it from https://github.com/FPtje/MySQLite") return false end
		if !SteamID then
			MySQLite.tableExists( "SimpleBank_Accounts", function(exists)
				if !exists then self:Setup() end
				self.Connected = true
				self:Msg( "Connected.", Color(175,175,255) )
			end)
			hook.Call( "SimpleBankInitialize", nil, false )
			return true
		else
			if !self:Player(SteamID) then
				MySQLite.query("SELECT * FROM SimpleBank_Accounts WHERE Name='User' AND Users="..MySQLite.SQLStr(SteamID)..";", function(data)
					if data then return end
					local StartingBalance = GetConVar( "SimpleBank_StartingBalance" ):GetInt() or 0
					MySQLite.query("INSERT INTO SimpleBank_Accounts ( Name, Users, Balance ) VALUES ( 'User', "..MySQLite.SQLStr(SteamID)..", '"..tostring(StartingBalance).."' );")
					self:Msg( "Account Generated for: "..tostring(SteamID).."." )
				end)
				hook.Call( "SimpleBankPlayerInitialize", nil, SteamID )
			end
		end
		return self:Update()
	end
	hook.Add( "Initialize", "SimpleBank_Initialize", function () SimpleBank:Init() end )
	hook.Add( "DatabaseInitialized", "SimpleBank_DatabaseInitialized", function () if MySQLite then SimpleBank:Init() end end )
	hook.Add( "PlayerInitialSpawn", "SimpleBank_PlayerInitialSpawn", function (ply) if MySQLite then SimpleBank:Init(SteamID) end end )
	hook.Add( "PostPlayerDeath", "SimpleBank_PostPlayerDeath", function (ply)
		local DropRate = GetConVar( "SimpleBank_DropRate" ):GetInt() or 0
		if math.Round(DropRate) < 1 then return end
		local Cash = SimpleBank:GetMoney(ply) or 0
		if !Cash or Cash < 100 then return end
		local ToDrop = math.Round((DropRate/100)*Cash)
		if !SimpleBank:SetMoney(ply, Cash-ToDrop) then return end
		SimpleBank:DropMoney(ply, ToDrop)
	end )
	concommand.Add( "SimpleBank_Purge", function( ply ) if IsValid(ply) and ply:IsSuperAdmin() then SimpleBank:Purge() end end )
	function SimpleBank:Insert(database, values)
		if !database or !values or !istable(values) then return false end
		local sanitized = {} for k,v in pairs(values) do if isnumber(v) then sanitized[k] = v else sanitized[k] = MySQLite.SQLStr(v) end end
		MySQLite.query("INSERT INTO "..database.." VALUES ( "..table.concat( sanitized,", " ).." );")
	end
	function SimpleBank:GetTransactions(SteamID)
		if !SteamID then return self.transactions or {} end
		local transactions = { }
		for k,v in pairs(self.transactions or {}) do
			if (v.Account == SteamID or v.Recipient == SteamID) then table.insert(transactions, v) end
			if #transactions > 100 then break end
		end table.SortByMember( transactions, "DateTime" )
		return transactions
	end
	function SimpleBank:Update(SteamID, amount)
		if !self.Connected then return self:Init() end
		if SteamID then
			if amount and self:Read(SteamID) then
				MySQLite.query("UPDATE SimpleBank_Accounts SET Balance="..MySQLite.SQLStr(amount).." WHERE Users="..MySQLite.SQLStr(SteamID)..";")
				self:Update()
			end
			local ply = player.GetBySteamID( SteamID )
			if IsValid(ply) then
				net.Start( "SimpleBank" )
					net.WriteInt( 2, 5 )
					net.WriteFloat(amount or self:Read(SteamID) or 0)
					net.WriteTable(self:GetTransactions(SteamID))
				net.Send(ply)
			end
		else
			MySQLite.begin()
				MySQLite.queueQuery("SELECT * FROM SimpleBank_Accounts;", function(data) self.table = data end)
				MySQLite.queueQuery("SELECT * FROM SimpleBank_Transactions;", function(data) self.transactions = data end)
			MySQLite.commit()
		end
	end
	function SimpleBank:DropMoney(ply, amount)
		if !IsValid(ply) or !amount or amount < 0 then return false end
		local CustomFunction = hook.Call( "SimpleBankDropMoney", nil, ply, amount ) or false
		if CustomFunction then return CustomFunction end
		if SimpleBank:gamemode("DarkRP") then
			if DARKRP_VERSION and string.find( DARKRP_VERSION, "2.2") then
				local moneybag = ents.Create("cash_bundle") moneybag:SetPos(ply:GetPos()) moneybag:Spawn() moneybag:GetTable().Amount = amount
			else
				DarkRP.createMoneyBag(ply:GetPos(), amount)
			end
			return true
		end
		if SimpleBank:gamemode("NutScript") then nut.currency.spawn(ply:GetPos(), amount) return true end
		if SimpleBank:gamemode("fprp") then fprp.createshekelBag(ply:GetPos(), amount) return true end
		if SimpleBank:gamemode("Pistachio") then local money = ents.Create("pistachio_money") money:SetPos( ply:GetPos() ) money:Spawn() money:SetMoney( amount ) return true end
		if SimpleBank:gamemode("CityScript") then local moneybag = ents.Create("token_bundle") moneybag:SetPos(ply:GetPos()) moneybag:Spawn() moneybag:Setamount(amount) return true end
		if SimpleBank:gamemode("City Life") then
			local ent = ents.Create("ent_money")
			ent:SetPos(ply:GetPos())
			ent:SetOwner(ply:Name())
			ent:SetModel("models/props/cs_assault/money.mdl")
			ent:SetNWInt("ID", ply:UniqueID())
			ent:SetNWInt("moneyamount", amount)
			ent:Spawn()
			ent:SetColor(255, 255, 255, 255)
			ent:Activate() return true
		end
		return false
	end
	function SimpleBank:GetMoney(ply, tryAgain)
		if !IsValid(ply) then return false end
		local CustomFunction = hook.Call( "SimpleBankGetMoney", nil, ply ) or false
		if CustomFunction then Cash = CustomFunction or 0 end
		local Balance = self:Read(ply:SteamID())
		if !Balance and !tryAgain then return self:GetMoney(ply, true) end
		if !Balance and tryAgain then return false end
		local Cash = false
		if self:gamemode("DarkRP") then
			if DARKRP_VERSION and string.find( DARKRP_VERSION, "2.2") then
				Cash = ply:GetNWInt("money", 0) or 0
			else
				Cash = ply:getDarkRPVar("money") or 0
			end
		end
		if self:gamemode("NutScript") then Cash = ply:getChar():getMoney() or 0 end
		if self:gamemode("Orange Cosmos RP") then Cash = ply:GetMoney("Wallet") or 0 end
		if self:gamemode("CityScript") then Cash = tonumber(ply:GetNWString("money", 0) or 0) end
		if self:gamemode("Pistachio") then Cash = ply:GetPrivateVar("money") or 0 end
		if self:gamemode("fprp") then Cash = ply:getfprpVar("shekel") or 0 end
		if self:gamemode("Tiramisu") or self:gamemode("LifeRP") then Cash = tonumber(CAKE.GetCharField( ply, "money" ) or 0) end
		if self:gamemode("City Life") then Cash = ply:GetNWInt("money", 0) or 0 return true end
		return (Cash or 0), (Balance or 0)
	end
	function SimpleBank:SetMoney(ply, amount)
		if !IsValid(ply) then return false end
		local CustomFunction = hook.Call( "SimpleBankSetMoney", nil, ply, amount ) or false
		if CustomFunction then return CustomFunction end
		if self:gamemode("DarkRP") then
			if DARKRP_VERSION and string.find( DARKRP_VERSION, "2.2") then
				ply:SetNWInt("money", amount or 0)
			else
				ply:setDarkRPVar("money", amount or 0)
			end
			return true
		end
		if self:gamemode("NutScript") then ply:getChar():setMoney(amount or 0) return true end
		if self:gamemode("Orange Cosmos RP") then ply:SetMoney( "Wallet", amount or 0 ) return true	end
		if self:gamemode("CityScript") then ply:SetNWString("money", amount or 0) return true end
		if self:gamemode("Pistachio") then ply:SetPrivateVar("money", amount or 0) return true end
		if self:gamemode("fprp") then ply:setfprpVar("shekel", amount or 0) return true end
		if self:gamemode("Tiramisu") or self:gamemode("LifeRP") then CAKE.SetCharField( ply, "money", amount or 0 ) ply:SetNWInt("money", amount or 0 ) return true end
		if self:gamemode("City Life") then ply:SetNWInt("money", amount or 0) return true end
		if SimpleBank_SetMoney then SimpleBank_SetMoney(ply, amount or 0) return true end
		return false
	end
	function SimpleBank:Open(ply)
		if !IsValid(ply) then return false end
		local Cash, Balance = self:GetMoney(ply)
		if !Balance or !Cash then return false end
		net.Start( "SimpleBank" )
			net.WriteInt( 2, 5 )
			net.WriteFloat(Balance)
			net.WriteTable(self:GetTransactions(ply:SteamID()))
		net.Send(ply)
		net.Start( "SimpleBank" )
			net.WriteInt( 1, 5 )
			net.WriteFloat(Balance)
			net.WriteFloat(Cash)
		net.Send(ply)
	end
	function SimpleBank:Transfer(ply, SteamID, amount)
		if !IsValid(ply) or !SteamID or !amount or (math.Round(amount) < 1) then return false end
		local _, Balance = self:GetMoney(ply)
		local toBalance = self:Read(SteamID)
		if !Balance then return self:Notify(ply, SimpleBank:language("account", 1).." "..SimpleBank:language("error", 1), true) end
		if !toBalance then return self:Notify(ply, SimpleBank:language("transferee", 1).." "..SimpleBank:language("account", 1).." "..SimpleBank:language("error", 1), true) end
		if ply:SteamID() == SteamID then return self:Notify(ply, SimpleBank:language("cant_self_trans", 1), true) end
		local NewBalance = Balance - amount
		local NewtoBalance = toBalance + amount
		if NewBalance < 0 then return self:Notify(ply, SimpleBank:language("cant_afford", 1), true, 2, "buttons/button8.wav") end
		self:Update(ply, NewBalance)
		self:Update(SteamID, NewtoBalance)
		hook.Call( "SimpleBankOnTransfer", nil, ply, SteamID, amount )
		local plyTo = player.GetBySteamID( SteamID ) or false
		local nick = SteamID
		if plyTo and IsValid(plyTo) then
			nick = plyTo:Nick()
			plyTo:ConCommand( 'SimpleBank_Alert '..amount..' "'..ply:Nick()..'"' )
		end
		self:Notify(ply, SimpleBank:language("transferred", 1).." $"..amount.." "..SimpleBank:language("to").." "..nick..".", false, 2, "buttons/button5.wav")
	end
	function SimpleBank:FindOwner(entity)
		if !IsValid(entity) then return false end
		local CustomFunction = hook.Call( "SimpleBankFindOwner", nil, entity ) or false
		if CustomFunction then return CustomFunction end
		if self:gamemode("DarkRP") then if entity.Getowning_ent then return entity:Getowning_ent() end end
		if self:gamemode("CityScript") then if entity.dt and entity.dt.ownIndex and player.GetByID(entity.dt.ownIndex) then return player.GetByID(entity.dt.ownIndex) end end
		if entity.GetOwner then return entity:GetOwner() end
		if entity.Owner then return entity.Owner end
		if entity.GetNWEntity then return entity:GetNWEntity("owner") end
		return false
	end
	function SimpleBankRemoteEftpos(ply, entity)
		if !IsValid(ply) or !IsValid(entity) then return false end
		local _, Balance = SimpleBank:GetMoney(ply)
		if !Balance then return SimpleBank:Notify(ply, SimpleBank:language("account", 1).." "..SimpleBank:language("error", 1), true) end
		local Owner = SimpleBank:FindOwner(entity)
		if !Owner then return SimpleBank:Notify(ply, SimpleBank:language("eftpos", 1).." "..SimpleBank:language("error", 1), true) end
		net.Start( "SimpleBank" )
			net.WriteInt( 3, 5 )
			net.WriteFloat(entity:GetCost() or 0)
			net.WriteFloat(Balance)
			net.WriteEntity(Owner)
			net.WriteEntity(entity)
		net.Send(ply)
	end
	util.AddNetworkString( "SimpleBank" )
	net.Receive( "SimpleBank", function( len, ply )
		if ( !IsValid( ply ) or !ply:IsPlayer() ) then return end
		local switch = net.ReadInt( 5 ) or 0
		local amount = net.ReadFloat() or false
		local Cash, Balance = SimpleBank:GetMoney(ply)
		if !Balance or !Cash then return end
		if switch == 5 then
			local ent = net.ReadEntity() or false
			if !IsValid(ent) then return SimpleBank:Notify(ply, SimpleBank:language("eftpos", 1).." "..SimpleBank:language("doesnt_exist"), true) end
			local Owner = SimpleBank:FindOwner(ent)
			if !Owner or Owner!=ply then return SimpleBank:Notify(ply, "Not "..SimpleBank:language("eftpos", 1).." Owner.", true) end
			ent:SetCost(math.Round(amount)) return
		end
		if !amount or math.Round(amount) < 1 then return SimpleBank:Notify(ply, "Invalid Amount!", true) end
		if switch == 1 then
			local NewCash = Cash - amount
			local NewBalance = Balance + amount
			if NewCash < 0 then return SimpleBank:Notify(ply, SimpleBank:language("cant_afford", 1), true, 2, "buttons/button8.wav") end
			if !SimpleBank:SetMoney(ply, NewCash) then return SimpleBank:Notify(ply, SimpleBank:language("error", 1), true) end
			SimpleBank:Insert("SimpleBank_Transactions", {ply:SteamID(), ply:SteamID(), amount, os.time()})
			SimpleBank:Update(ply:SteamID(), NewBalance)
			hook.Call( "SimpleBankDeposit", nil, ply, amount )
			if amount > 8000 then SimpleBank:Msg( ply:Nick().." "..SimpleBank:language("deposited").." $"..amount ) end
			SimpleBank:Notify(ply, SimpleBank:language("deposited", 1).." $"..amount..".", false, 3, "buttons/button4.wav") return
		end
		if switch == 2 then
			local NewBalance = Balance - amount
			local NewCash = Cash + amount
			if NewBalance < 0 then return SimpleBank:Notify(ply, SimpleBank:language("cant_afford", 1), true, 2, "buttons/button8.wav") end
			if !SimpleBank:SetMoney(ply, NewCash) then return SimpleBank:Notify(ply, SimpleBank:language("error", 1), true) end
			SimpleBank:Update(ply:SteamID(), NewBalance)
			hook.Call( "SimpleBankWithdraw", nil, ply, amount )
			if amount > 8000 then SimpleBank:Msg( ply:Nick().." "..SimpleBank:language("withdrew").." $"..amount ) end
			SimpleBank:Notify(ply, SimpleBank:language("withdrew", 1).." $"..amount..".", false, 3, "buttons/button4.wav") return
		end
		if switch == 3 then
			local to = net.ReadEntity() or false
			if !to or !IsValid(to) then return SimpleBank:Notify(ply, SimpleBank:language("player", 1).." "..SimpleBank:language("doesnt_exist"), true) end
			SimpleBank:Transfer(ply, to:SteamID(), amount) return
		end
		if switch == 6 then
			local SteamID = net.ReadString() or ""
			local found = SimpleBank:Player(SteamID) or false
			if !found or found == nil then return SimpleBank:Notify(ply, SimpleBank:language("player", 1).." "..SimpleBank:language("doesnt_exist"), true) end
			SimpleBank:Transfer(ply, SteamID, amount) return
		end
		ply:Ban( 1440, true )
	end )
	cvars.AddChangeCallback( "SimpleBank_Model", function( cVar, modelOld, model )
		if !util.IsValidModel(model) then return end
		for _, v in pairs(ents.FindByClass( "simplebank" )) do
			if IsValid(v) then v:SetModel( model ) end
		end
	end )
end

if CLIENT then
	local function MakeButton(x, y, h, w, parent, text, color, font, func, version)
		local Button = vgui.Create( "DButton", parent or nil )
		if func then Button.OnClick = func end
		Button:SetPos( x or 0, y or 0 )
		Button:SetSize( h or 0, w or 0 )
		Button:SetText("")
		Button.Text = text or ""
		Button.Font = font or "DermaDefault"
		Button.Color = color or Color(0,0,0,255)
		if !version then
			Button.Paint = function(s, w, h) draw.SimpleText( s.Text, s.Font, w/2, h/2, s.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER ) end
		else
			local gradient = Material( "gui/gradient", "noclamp smooth" )
			Button.Paint = function(s, w, h)
				draw.RoundedBox( 0, 0, 0, w, h, SimpleBank.Theme.Button )
				if s:IsHovered() and !s:GetDisabled() then draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) ) end
				surface.SetDrawColor(SimpleBank.Theme.ButtonGradient)
				surface.SetMaterial( gradient )
				surface.DrawTexturedRectRotated(0, 0, w, w*2, -90)
				surface.SetDrawColor(SimpleBank.Theme.ButtonOutline)
				surface.DrawOutlinedRect( 0, 0, w, h )
				draw.SimpleText( s.Text, s.Font, w/2, h/2, s.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				if s:GetDisabled() then draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50, 150 ) ) end
			end
		end
		Button.DoClick = function(s)
			if s.OnClick then s:OnClick() end
		end
		return Button
	end
	surface.CreateFont("BankGUITitle", {font = "DermaDefault", size = 45, weight = 250, antialias = true, shadow = false})
	surface.CreateFont("BankGUIButton", {font = "DermaDefault", size = 22, weight = 50, antialias = true, shadow = false})
	SimpleBank.Theme = {}
	SimpleBank.Theme.Content = Color(26,26,26,255)
	SimpleBank.Theme.Title = color_white
	SimpleBank.Theme.SubTitle = Color(200,200,200,255)
	SimpleBank.Theme.Text = Color(200,200,200,255)
	SimpleBank.Theme.Button = Color(116,179,0,255)
	SimpleBank.Theme.ButtonText = color_white
	SimpleBank.Theme.ButtonOutline = Color(0,0,0,0)
	SimpleBank.Theme.ButtonGradient = Color(0,0,0,0)
	function SimpleBank:Close(noSound)
		if !IsValid(self.Frame) then return false end
		if !noSound then surface.PlaySound( "common/wpn_hudoff.wav" ) end
		if self.Closing then return false end
		self.Closing = true
		self.Frame:AlphaTo( 0, 0.1, 0, function(tab, this) if IsValid(this) then this:Remove() self.Closing = false end end	)
		timer.Simple( 0.2, function() if self and IsValid(self.Frame) then self.Frame:Remove() self.Closing = false end end)
	end
	function SimpleBank:Eftpos(Cost, Balance, ply, entity)
		if !Cost or !Balance or !ply or !entity then return end
		if IsValid(self.EftposFrame) then self.EftposFrame:Remove() end
		local Frame	= vgui.Create( "DFrame" )
		self.EftposFrame = Frame
		Frame:SetSize( ScrW(), ScrH() )
		Frame:SetTitle("")
		Frame:ShowCloseButton( false )
		Frame:MakePopup()
		Frame.Paint = function(s, w, h) end
		Frame.Close = function(s)
			if !IsValid(s) then return false end
			s:AlphaTo( 0, 0.2, 0, function(tab, this) if IsValid(this) then this:Remove() end end	)
			timer.Simple( 0.3, function() if s and IsValid(s) then s:Remove() end end)
		end
		local Background = vgui.Create( "DButton", Frame )
		Background:SetSize( Frame:GetWide(), Frame:GetTall() )
		Background:SetText("")
		Background:SetCursor( "arrow" )
		Background.Paint = function(s, w, h)
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 150 ) )
		end
		Background:SetAlpha( 0 )
		Background:AlphaTo( 255, 0.1 )
		Background.DoClick = function(s)
			self.EftposFrame:Close()
		end
		local Content = vgui.Create( "DPanel", Background )
		Content:SetSize( Background:GetWide()/4, Background:GetTall()/4 )
		Content:Center()
		local x, y = Content:GetPos()
		Content:SetPos(x,y+(Content:GetTall()/4))
		Content:SetAlpha( 0 )
		Content:AlphaTo( 255, 0.3 )
		Content:MoveTo( x, y, 0.3, 0, -1)

		local owner = false
		local name = false
		if ply and IsValid(ply) then
			if LocalPlayer() == ply then owner = true end
			name = ply:Nick()
		end
		local Have = tonumber(Balance or 0) or 0
		local Price = tonumber(Cost or 0) or 0
		local CanPay = false
		if Price > 1 and Have >= Price then CanPay = true end
		Content.Paint = function(s, w, h)
			draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
			draw.RoundedBox( 8, 0, 0, w-2, h-2, Color( 220, 220, 220, 255 ) )
			draw.SimpleText( SimpleBank:language("eftpos", 2), "BankGUITitle", w/2, 10, Color(70,70,70,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			surface.SetDrawColor(Color(100,100,100,255))
			surface.DrawOutlinedRect( w/2-(w/8), 80, w/4, 1 )
			if owner then
				draw.SimpleText( SimpleBank:language("device_asking_amount", 1), "DermaDefault", w/2, 60, Color(100,100,100,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
				draw.SimpleText( SimpleBank:language("set_player_choice", 1)..".", "DermaDefault", w/2, h/2+20, Color(100,100,100,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			else
				draw.SimpleText( SimpleBank:language("account", 1).." "..SimpleBank:language("balance", 1)..": $"..Have, "DermaDefault", w/2, 60, Color(100,100,100,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
				if Price > 0 then
					local PriceColor = Color(255,50,50,255)
					if CanPay then PriceColor = Color(140,170,50,255) end
					draw.SimpleText( "$"..(Price or 0), "BankGUITitle", w/2, h/2-30, PriceColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
				end
				if name then draw.SimpleText( SimpleBank:language("to", 1).." "..SimpleBank:language("account")..": "..name, "DermaDefault", w/2, h/2+20, Color(100,100,100,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP ) end
			end
		end
		if owner then Have = 9000 end
		local DTextEntry = false
		if Price < 1 or owner then
			local DNumberScratch
			DTextEntry = vgui.Create( "DNumberWang", Content )
			DTextEntry:SetPos( (Content:GetWide()/2)-100, (Content:GetTall()/2)-15 )
			DTextEntry:SetSize( 200, 30 )
			DTextEntry:SetValue( 0 )
			DTextEntry:SetMin( 0 )
			DTextEntry:SetMax( Have )
			DTextEntry:SetDecimals( 0 )
			DTextEntry.OnValueChanged = function(s, v)
				DNumberScratch:SetValue( v )
			end
			DNumberScratch = vgui.Create( "DNumberScratch", Content )
			DNumberScratch:SetPos( (Content:GetWide()/2)+100, (Content:GetTall()/2)-15 )
			DNumberScratch:SetSize( 20, 30 )
			DNumberScratch:SetValue( 0 )
			DNumberScratch:SetMin( 0 )
			DNumberScratch:SetMax( Have )
			DNumberScratch:SetDecimals( 1 )
			DNumberScratch.OnValueChanged = function(s, v)
				DTextEntry:SetValue( v )
			end
			if Price > 0 then
				DTextEntry:SetValue( Price )
			end
		end

		local Cancel = MakeButton(Content:GetWide()-140, Content:GetTall()-40, 70, 25, Content, SimpleBank:language("cancel", 2), Color(100,100,100,255), "BankGUIButton", function(s)
			self.EftposFrame:Close()
		end)
		if owner then
			local Set = MakeButton(Content:GetWide()-60, Content:GetTall()-40, 40, 25, Content, SimpleBank:language("set", 2), Color(97,149,224,255), "BankGUIButton", function(s)
				local amount = tonumber(DTextEntry:GetValue() or 0) or 0
				net.Start( "SimpleBank" )
					net.WriteInt( 5, 5 )
					net.WriteFloat( amount )
					net.WriteEntity( entity )
				net.SendToServer()
				self.EftposFrame:Close()
			end)
		else
			local PayNow = MakeButton(Content:GetWide()-60, Content:GetTall()-40, 40, 25, Content, SimpleBank:language("pay", 2), Color(100,100,100,255), "BankGUIButton", function(s)
				local amount = 0
				if Price < 1 and DTextEntry then
					amount = tonumber(DTextEntry:GetValue() or 0) or 0
					if amount < 1 then return end
				else
					if !CanPay then return end
				end
				local paying = amount
				if Price > paying then paying = Price end
				net.Start( "SimpleBank" )
					net.WriteInt( 3, 5 )
					net.WriteFloat( paying )
					net.WriteEntity( ply )
				net.SendToServer()
				self.EftposFrame:Close()
			end)
			PayNow.Paint = function(s, w, h)
				local amount = 0
				if Price < 1 and DTextEntry then amount = tonumber(DTextEntry:GetValue()) end
				if CanPay or amount > 0 then s.Color = Color(97,149,224,255) else s.Color = Color(100,100,100,255) end
				draw.SimpleText( SimpleBank:language("pay", 2), "BankGUIButton", w/2, h/2, s.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		end
	end
	function SimpleBank:Alert(amount, ply)
		if IsValid(self.AlertBox) then self.AlertBox:Remove() end
		if !GetConVar( "SimpleBank_GetAlerts" ):GetBool() then return end
		local Content = vgui.Create( "DFrame" )
		self.AlertBox = Content
		Content:SetTitle("")
		Content:ShowCloseButton( false )
		Content:SetPos( ScrW()-310, ScrH()-70 )
		Content:SetSize( 300, 60 )
		Content:SetAlpha( 0 )
		Content:AlphaTo( 255, 0.5 )
		Content.Paint = function(s, w, h)
			draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
			draw.RoundedBox( 8, 0, 0, w-2, h-2, Color( 220, 220, 220, 255 ) )
			draw.SimpleText( SimpleBank:language("you_received", 1).." $"..(amount or 0), "BankGUIButton", 10, 5, Color(70,70,70,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			draw.SimpleText( SimpleBank:language("transferred_from", 1)..": "..(ply or "Unknown"), "DermaDefault", 10, 35, Color(100,100,100,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			surface.SetDrawColor(Color(100,100,100,255))
			surface.DrawOutlinedRect( 10, 30, w-20, 1 )
		end
		Content.GraceRemove = function(s)
			if !IsValid(s) then return false end
			s:AlphaTo( 0, 0.5, 0, function(tab, this) if IsValid(this) then this:Remove() end end	)
			timer.Simple( 0.6, function() if s and IsValid(s) then s:Remove() end end)
		end
		timer.Simple( 4, function() if self and IsValid(self.AlertBox) then self.AlertBox:GraceRemove() end end)
	end
	concommand.Add( "SimpleBank_Alert", function( ply, cmd, args )  SimpleBank:Alert(args[1] or 0, args[2] or "Unknown") end )
	function SimpleBank:Init(Balance, Cash)
		if IsValid(self.Frame) then self.Frame:Remove() end
		self.Closing = false
		surface.PlaySound( "buttons/button14.wav" )
		local Frame	= vgui.Create( "DFrame" )
		self.Frame = Frame
		self.Selected = nil
		Frame:SetSize( ScrW(), ScrH() )
		Frame:SetTitle("")
		Frame:ShowCloseButton( false )
		Frame:MakePopup()
		Frame.Paint = function(s, w, h) end
		local Background = vgui.Create( "DButton", Frame )
		Background:SetSize( Frame:GetWide(), Frame:GetTall() )
		Background:SetText("")
		Background:SetCursor( "arrow" )
		Background.Paint = function(s, w, h)
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 150 ) )
			if input.IsKeyDown( KEY_ESCAPE ) and !self.Closing then self:Close() end
		end
		Background:SetAlpha( 0 )
		Background:AlphaTo( 255, 0.1 )
		Background.DoClick = function(s)
			self:Close()
		end
		local Content = vgui.Create( "DPanel", Background )
		self.Content = Content
		Content:SetSize( Background:GetWide()/4, Background:GetTall()/2 )
		Content:Center()
		local x, y = Content:GetPos()
		Content:SetPos(x,y+(Content:GetTall()/4))
		Content:SetAlpha( 0 )
		Content:AlphaTo( 255, 0.3 )
		Content:MoveTo( x, y, 0.3, 0, -1)
		Content.Paint = function(s, w, h)
			draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
			draw.RoundedBox( 8, 0, 0, w-2, h-2, Color( 26, 26, 26, 255 ) )
			draw.SimpleText( SimpleBank:language("bank", 1).." "..SimpleBank:language("atm", 2), "BankGUITitle", w/2, 10, SimpleBank.Theme.Title, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			draw.SimpleText( SimpleBank:language("slogan", 1), "DermaDefault", w/2, 60, SimpleBank.Theme.SubTitle, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			surface.SetDrawColor(Color(100,100,100,255))
			surface.DrawOutlinedRect( w/2-(w/8), 80, w/4, 1 )
			draw.SimpleText( SimpleBank:language("account", 1).." "..SimpleBank:language("balance", 1)..": $"..Balance, "DermaDefault", w/2, 85, SimpleBank.Theme.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			draw.SimpleText( SimpleBank:language("cash", 1).." "..SimpleBank:language("on_hand")..": $"..Cash, "DermaDefault", w/2, 100, SimpleBank.Theme.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		end
		local MaxAmount = Balance or 0
		if (Cash or 0) > MaxAmount then MaxAmount = Cash end
		local DNumberScratch
		local DTextEntry = vgui.Create( "DNumberWang", Content )
		DTextEntry:SetPos( (Content:GetWide()/2)-100, (Content:GetTall()/2)-80 )
		DTextEntry:SetSize( 200, 30 )
		DTextEntry:SetValue( 0 )
		DTextEntry:SetMin( 0 )
		DTextEntry:SetMax( MaxAmount )
		DTextEntry:SetDecimals( 0 )
		DTextEntry.OnValueChanged = function(s, v)
			DNumberScratch:SetValue( v )
		end
		DNumberScratch = vgui.Create( "DNumberScratch", Content )
		DNumberScratch:SetPos( (Content:GetWide()/2)+100, (Content:GetTall()/2)-80 )
		DNumberScratch:SetSize( 20, 30 )
		DNumberScratch:SetValue( 0 )
		DNumberScratch:SetMin( 0 )
		DNumberScratch:SetMax( MaxAmount )
		DNumberScratch:SetDecimals( 1 )
		DNumberScratch.OnValueChanged = function(s, v)
			DTextEntry:SetValue( v )
		end
		local Deposit = MakeButton((Content:GetWide()/2)-100, (Content:GetTall()/2)-40, 200, 30, Content, SimpleBank:language("deposit", 1), SimpleBank.Theme.ButtonText, "BankGUIButton", function(s)
			local amount = tonumber(DTextEntry:GetValue())
			if !amount or amount < 1 then return end
			net.Start( "SimpleBank" )
				net.WriteInt( 1, 5 )
				net.WriteFloat( amount )
			net.SendToServer()
			self:Close(true)
		end, true)
		local Withdraw = MakeButton((Content:GetWide()/2)-100, (Content:GetTall()/2)-5, 200, 30, Content, SimpleBank:language("withdraw", 1), SimpleBank.Theme.ButtonText, "BankGUIButton", function(s)
			local amount = tonumber(DTextEntry:GetValue())
			if !amount or amount < 1 then return end
			net.Start( "SimpleBank" )
				net.WriteInt( 2, 5 )
				net.WriteFloat( amount )
			net.SendToServer()
			self:Close(true)
		end, true)
		local DermaCheckbox
		local DoTransfer = function(amount, to)
			if GetConVar( "SimpleBank_ConfirmTransfers" ):GetBool() then
				Derma_Query( SimpleBank:language("are_you_sure_want", 1).." "..SimpleBank:language("transfer").." $"..amount.." "..SimpleBank:language("to").." "..to:Nick().."?", SimpleBank:language("please_confirm", 1).." "..SimpleBank:language("transfer")..".", SimpleBank:language("confirm", 1), function()
					net.Start( "SimpleBank" )
						net.WriteInt( 3, 5 )
						net.WriteFloat( amount )
						net.WriteEntity( to )
					net.SendToServer()
					self:Close(true)
				end, SimpleBank:language("cancel", 1) )
			else
				net.Start( "SimpleBank" )
					net.WriteInt( 3, 5 )
					net.WriteFloat( amount )
					net.WriteEntity( to )
				net.SendToServer()
				self:Close(true)
			end
		end
		local players = table.Copy(player.GetAll() or {})
		table.RemoveByValue(players, LocalPlayer())
		local Transfer = MakeButton((Content:GetWide()/2)-100, (Content:GetTall()/2)+30, 200, 30, Content, SimpleBank:language("transfer", 1), SimpleBank.Theme.ButtonText, "BankGUIButton", function(s)
			local amount = tonumber(DTextEntry:GetValue())
			if !amount or amount < 1 then return end
			local Menu = DermaMenu()
			if #players >= 1 then
				Menu:AddOption( SimpleBank:language("find_by", 1).." "..SimpleBank:language("online").." "..SimpleBank:language("name"), function()
					Derma_StringRequest( SimpleBank:language("find_by", 1).." "..SimpleBank:language("online").." "..SimpleBank:language("name"), SimpleBank:language("please_enter", 1)..SimpleBank:language("name")..SimpleBank:language("of_transfer_player"), "", function(text)
						if !text or text=="" then return end
						for _,v in pairs(players) do
							if string.find( v:Nick(), text) then
								DoTransfer(amount, v) break
							end
						end
					end, function() return end)
				end	)
			end
			Menu:AddOption( SimpleBank:language("find_by", 1).." "..SimpleBank:language("offline").." SteamID", function()
				Derma_StringRequest( SimpleBank:language("find_by", 1).." "..SimpleBank:language("offline").." SteamID", SimpleBank:language("please_enter", 1).." SteamID"..SimpleBank:language("of_transfer_player"), "", function(text)
					if !text or text=="" then return end
					net.Start( "SimpleBank" )
						net.WriteInt( 6, 5 )
						net.WriteFloat( amount )
						net.WriteString( text )
					net.SendToServer()
				end, function() return end)
			end	)
			if #players >= 1 then
				Menu:AddSpacer()
				local SubMenu = Menu:AddSubMenu( SimpleBank:language("select_from_server", 1) )
				for _,v in pairs(players) do
					SubMenu:AddOption( v:Nick(), function()
						DoTransfer(amount, v)
					end )
				end
			end
			Menu:Open()
		end, true)

		DermaCheckbox = vgui.Create( "DCheckBoxLabel", Content )
		DermaCheckbox:SetPos( (Content:GetWide()/2)-100, (Content:GetTall()/2)+65 )
		DermaCheckbox:SetSize( 200, 300 )
		DermaCheckbox:SetText( SimpleBank:language("confirm_amount", 1) )
		DermaCheckbox:SetValue( GetConVar( "SimpleBank_ConfirmTransfers" ):GetBool() or false )
		DermaCheckbox:SetTextColor( SimpleBank.Theme.Text )
		DermaCheckbox.OnChange = function(s, v)
			GetConVar( "SimpleBank_ConfirmTransfers" ):SetBool(v)
		end
		DermaCheckbox = vgui.Create( "DCheckBoxLabel", Content )
		DermaCheckbox:SetPos( (Content:GetWide()/2)-100, (Content:GetTall()/2)+85 )
		DermaCheckbox:SetSize( 200, 300 )
		DermaCheckbox:SetText( SimpleBank:language("transfer_alert", 1) )
		DermaCheckbox:SetValue( GetConVar( "SimpleBank_GetAlerts" ):GetBool() or false )
		DermaCheckbox:SetTextColor( SimpleBank.Theme.Text )
		DermaCheckbox.OnChange = function(s, v)
			GetConVar( "SimpleBank_GetAlerts" ):SetBool(v)
		end

		local Cancel = MakeButton(Content:GetWide()-80, Content:GetTall()-40, 70, 25, Content, SimpleBank:language("cancel", 2), SimpleBank.Theme.ButtonText, "BankGUIButton", function(s)
			self:Close()
		end)
	end
	net.Receive( "SimpleBank", function()
		local switch = net.ReadInt( 5 ) or 0
		if switch == 1 then SimpleBank:Init(net.ReadFloat() or 0,net.ReadFloat() or 0) end
		if switch == 2 then SimpleBank.Balance = net.ReadFloat() or 0  SimpleBank.Transactions = net.ReadTable() or {} end
		if switch == 3 then SimpleBank:Eftpos(net.ReadFloat() or 0, net.ReadFloat() or 0, net.ReadEntity() or false, net.ReadEntity() or false) end
	end )
end

return SimpleBank
