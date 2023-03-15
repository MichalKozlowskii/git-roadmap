include('shared.lua')

local function draw3d2d(ent)
    local name = "Auction House"
    local color = Color(255, 255, 255)
    if LocalPlayer():GetPos():DistToSqr(ent:GetPos()) >= 50000 then return end

    local pos = ent:LocalToWorld(Vector(0, -2, 75))
    local ang = ent:LocalToWorldAngles(Angle(0, 90, 90))
    cam.Start3D2D(pos, ang, 0.2)
        draw.RoundedBox( 1, -65, 0, 130, 25, Color(0, 0, 0))
        draw.DrawText(name, "auctions_panel_font", 0, 0, color, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

function ENT:Draw()
    self:DrawModel()
    draw3d2d(self)
end