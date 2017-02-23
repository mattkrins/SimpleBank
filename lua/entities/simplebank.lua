AddCSLuaFile()
DEFINE_BASECLASS( "base_anim" )

ENT.Type = "anim"
ENT.PrintName = "Simple Bank"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "SimpleBank"

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )
		if ( !tr.Hit ) then return end
		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 36 )
		ent:Spawn()
		ent:Activate()
		return ent
	end
	function ENT:Initialize()
		local ATMModel = GetConVar( "SimpleBank_Model" ):GetString()
		if util.IsValidModel(ATMModel) then self:SetModel( ATMModel ) else self:SetModel( "models/props_phx/construct/glass/glass_plate1x1.mdl" ) end
		if !GetSimpleBank then if IsValid(self) then self:Remove() end return end
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:DrawShadow( false )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetColor( Color(0,0,0,255) )
		self:PhysicsInit( SOLID_VPHYSICS )
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then phys:Wake() end
	end
	function ENT:Use( activator, caller )
		local ply = activator or caller
		if !ply:IsPlayer() then return end
		if (self.LastUse or 0) >= CurTime() then return end
		self.LastUse = CurTime() + 2
		GetSimpleBank():Open(ply)
	end
	function ENT:Touch( entity )
		if !IsValid(entity) then return end
		local SimpleBank = GetSimpleBank()
		if !SimpleBank:gamemode("DarkRP") then return end
		local Owner = SimpleBank:FindOwner(entity)
		if entity:GetClass() ~= "spawned_money" or entity.USED or entity.hasMerged or !Owner then return end
		local _, Balance = SimpleBank:GetMoney(Owner) if !Balance then return end
		entity.USED = true
		entity.hasMerged = true
		local amount = entity:Getamount()
		entity:Remove()
		SimpleBank:Update(Owner, Balance+amount)
		SimpleBank:Notify(Owner, SimpleBank:language("deposited", 1).." $"..amount.." "..SimpleBank:language("into", 1).." "..SimpleBank:language("bank", 1), false, 3, "buttons/button4.wav")
	end
end

if CLIENT then
	function draw.ContainerBox( r, x, y, w, h, c, p )
		draw.RoundedBox( r or 0, x or 0, y or 0, w or 0, h or 0, c or color_white )
		if p then p(x or 0, y or 0, w or 0, h or 0) end
	end
	local a
	surface.CreateFont("Bank3D", {font = "DermaDefault", size = 140, weight = 550, antialias = true, shadow = false})
	function ENT:Draw()
		self:DrawModel()
		local ShowText = GetConVar( "SimpleBank_ShowText" ) or false
		if ShowText then ShowText = ShowText:GetBool() or false end
		local Pos = self:GetPos()
		if ShowText and IsValid(self) and Pos:Distance(LocalPlayer():GetPos()) < 500 then
			local SimpleBank = GetSimpleBank()
			local Ang = self:GetAngles()
			Ang:RotateAroundAxis(Ang:Up(), 90)
			Ang:RotateAroundAxis(Ang:Forward(), 0)
			local Up = -30
			a = math.Clamp((a or 0)+FrameTime()*250,a or 0,255)
			cam.Start3D2D(Pos + Ang:Up() + (Ang:Right() * Up), Ang, 0.1)
				draw.SimpleTextOutlined( SimpleBank:language("atm", 2), "Bank3D", 0, 0, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,100) )
			cam.End3D2D()
			if Pos:Distance(LocalPlayer():GetPos()) < 180 then
				cam.Start3D2D(Pos + (Ang:Up()*1) + (Ang:Right() * Up), Ang, 0.1)
					draw.RoundedBox( 0, -150-5, 150-5, 300+10, 300+10, Color( 0, 0, 0, a-100 ) )
					draw.ContainerBox( 0, -150, 150, 300, 300, Color( 26, 26, 26, a ), function(x, y, w, h)
						draw.ContainerBox( 0, x+(w/2)-25, y+10, 50, 50, Color( 53, 178, 51, a ), function(x, y, w, h)
							draw.SimpleText( "SB", "DermaLarge", x+w/2, y+h/2, Color(255,255,255,a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						end)
						draw.ContainerBox( 4, x+5, y+70, 150, 22, Color( 116, 179, 0, a ), function(x, y, w, h)
							draw.SimpleText( LocalPlayer():Nick(), "DermaDefault", x+(w/2), y+(h/2), Color(255,255,255,a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						end)
						draw.ContainerBox( 4, x+5, y+100, 150, 22, Color( 116, 179, 0, a ), function(x, y, w, h)
							draw.SimpleText( "Account Balance: $"..(SimpleBank.Balance or 0), "DermaDefault", x+5, y+10, Color(255,255,255,a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
						end)
						draw.ContainerBox( 4, x+5, y+130, 150, 160, Color( 116, 179, 0, a ), function(x, y, w, h)
							draw.SimpleText( "Recent Transactions:", "DermaDefault", x+(w/2), y+10, Color(255,255,255,a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
							for k, v in pairs(SimpleBank.Transactions or {}) do
								if k > 13 then break end
								local txt = ""
								if v.Recipient == LocalPlayer():SteamID() then
									txt = "Transfered $"..v.Amount
								elseif v.Recipient != LocalPlayer():SteamID() then
									txt = "Received $"..v.Amount
								elseif v.Account == LocalPlayer():SteamID() then
									txt = "Sent $"..v.Amount
								end
								draw.SimpleText( txt, "DermaDefault", x+(w/2), y+15+(k*10), Color(0,0,0,a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
							end
						end)
						draw.ContainerBox( 4, x+160, y+130, 135, 160, Color( 116, 179, 0, a ), function(x, y, w, h)
							draw.SimpleText( "Bills Due:", "DermaDefault", x+(w/2), y+10, Color(255,255,255,a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						end)
					end)
				cam.End3D2D()
			elseif ShowText and a != 0 then
				a = 0
			end
		end
	end
end
