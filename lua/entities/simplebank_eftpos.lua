AddCSLuaFile()
DEFINE_BASECLASS( "base_anim" )

ENT.Type = "anim"
ENT.PrintName = "Simple Bank Eftpos"
ENT.Author = "StealthPaw"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "SimpleBank"

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "Cost" );
	self:NetworkVar("Entity", 0, "owning_ent")
end

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )
		if ( !tr.Hit ) then return end
		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 5 )
		ent:SetAngles(Angle(-90,0,0))
		ent:Spawn()
		ent:Activate()
		ent:Setowning_ent(ply)
		return ent
	end
	function ENT:Initialize()
		self:SetModel( "models/props_lab/keypad.mdl" )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:DrawShadow( false )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetColor( Color(240,255,240,255) )
		self:SetCost(0)
		self.damage = 100
		if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then phys:Wake() end
		hook.Add("PlayerDisconnected", self, self.onPlayerDisconnected)
	end
	function ENT:Use( activator, caller )
		local ply = activator or caller
		if !ply:IsPlayer() then return end
		if (self.LastUse or 0) >= CurTime() then return end
		self.LastUse = CurTime() + 2
		SimpleBankRemoteEftpos(ply, self)
	end
	function ENT:OnTakeDamage(dmg)
		self:TakePhysicsDamage(dmg)
		self.damage = self.damage - dmg:GetDamage()
		if self.damage <= 0 then
			self:Destruct()
			self:Remove()
		end
	end
	function ENT:Destruct()
		local vPoint = self:GetPos()
		local effectdata = EffectData()
		effectdata:SetStart(vPoint)
		effectdata:SetOrigin(vPoint)
		effectdata:SetScale(1)
		util.Effect("Explosion", effectdata)
	end
	function ENT:onPlayerDisconnected(ply)
		if self.dt.owning_ent == ply then
			self:Remove()
		end
	end
end

if CLIENT then
	surface.CreateFont("Eftpos3D", {font = "DermaDefault", size = 90, weight = 550, antialias = true, shadow = false})
	function ENT:Draw()
		self:DrawModel()
		local dist = self:GetPos():Distance(LocalPlayer():GetPos())
		if IsValid(LocalPlayer()) and IsValid(self) and dist < 200 then
			local Pos = self:GetPos()
			local Ang = self:GetAngles()
			Ang:RotateAroundAxis(Ang:Up(), 90)
			Ang:RotateAroundAxis(Ang:Forward(), 90)
			local Forward = 1.1
			local Up = -3
			local Cost = self:GetCost() or 0
			cam.Start3D2D(Pos + (Ang:Up() * Forward) + (Ang:Right() * Up), Ang, 0.01)
				draw.RoundedBox( 8, -165, -100, 330, 200, Color( 0, 0, 0, 240 ) )
				local x = 0
				if Cost > 0 then
					x = -40
					draw.SimpleTextOutlined( "$"..Cost, "Eftpos3D", 0, 40, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0,0,0,100) )
				end
				draw.SimpleTextOutlined( "EFTPOS", "Eftpos3D", 0, x, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0,0,0,100) )
				draw.SimpleTextOutlined( "SimpleBank", "Eftpos3D", 0, 790, Color(153,101,50,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,100) )
			cam.End3D2D()
			Forward = 0
			Ang:RotateAroundAxis(Ang:Forward(), 180)
			cam.Start3D2D(Pos + (Ang:Up() * Forward) + (Ang:Right() * Up), Ang, 0.01)
				surface.SetDrawColor( 175, 185, 145, 255 )
				surface.DrawRect( -300, -252, 600, 1100 )
			cam.End3D2D()
		end
	end
end