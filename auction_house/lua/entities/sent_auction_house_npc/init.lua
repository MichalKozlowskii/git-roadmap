AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" ) 
 
include('shared.lua')
 
function ENT:Initialize()
	self:SetModel("models/Humans/Group01/Female_01.mdl") 
	self:SetHullType( HULL_HUMAN ) 
	self:SetHullSizeNormal( )
	self:SetNPCState( NPC_STATE_SCRIPT )
	self:SetSolid(  SOLID_BBOX )
	self:SetUseType( SIMPLE_USE ) 
	self:DropToFloor()
	self:SetMaxYawSpeed( 90 )
end

function ENT:Use(ply)
	auction_house_openUI(ply)
end