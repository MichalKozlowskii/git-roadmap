concommand.Add("auction_house_npc_remove", function(ply)
	local eyeTrace = ply:GetEyeTrace()
	if !eyeTrace.Entity:IsValid() or !IsEntity(eyeTrace.Entity) or eyeTrace.Entity:GetClass() != "sent_auction_house_npc" then 
		print("You have to be looking at auction house npc entity!")
		return
	end

	eyeTrace.Entity:Remove()
end)

hook.Add( "ShutDown", "auction_house_ShutDown", function() 
	local f = file.Open("auction_house_npc_pos.txt", "w", "DATA")
	local tblPos = {}
	local tblAngles = {}
	for i, v in ipairs(ents.FindByClass("sent_auction_house_npc")) do
		tblPos[#tblPos + 1] = v:GetPos()
		tblAngles[#tblAngles + 1] = v:GetAngles()
	end

	if #tblPos == 0 or #tblAngles == 0 then return end
	
	local strPosJSON = util.TableToJSON(tblPos)
	local strAngleJSON = util.TableToJSON(tblAngles)
	
	f:Write(strPosJSON.."\n")
	f:Write(strAngleJSON)
	f:Close()
end)

hook.Add("InitPostEntity", "auction_house_InitPostEntity", function()
	local f = file.Open("auction_house_npc_pos.txt", "r", "DATA")

	if f:Size() <= 4 then return end
	
	local tblPosTemp = util.JSONToTable(f:ReadLine())
	local tblAnglesTemp = util.JSONToTable(f:ReadLine())
	local tblPos = {}
	local tblAngles = {}
	f:Close()

	timer.Simple(10, function()
		for i, v in ipairs(tblPosTemp) do -- get all pos coordinates into the table
			local tblTemp = string.Explode(" ", tostring(v))
			for index, value in ipairs(tblTemp) do
				tblPos[#tblPos+1] = tonumber(value)
			end
		end
		
		for i, v in ipairs(tblAnglesTemp) do -- get all angle coordinates into the table
			local tblTemp = string.Explode(" ", tostring(v))
			for index, value in ipairs(tblTemp) do
				tblAngles[#tblAngles+1] = tonumber(value)
			end
		end
		
		for i = 3, #tblPos, 3 do -- spawn npcs
			local npc = ents.Create("sent_auction_house_npc")
			npc:SetPos(Vector(tblPos[i-2], tblPos[i-1], tblPos[i]))
			npc:SetAngles(Angle(tblAngles[i-2], tblAngles[i-1], tblAngles[i-3]))
			npc:Spawn()
		end
	end)
end)