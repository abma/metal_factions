
function widget:GetInfo()
	return {
		name      = "Metal Factions Tooltip",
		desc      = "overrides default tooltip, shows shield and weapon info",
		author    = "raaar, based on a Kernel Panic widget by zwszg",
		date      = "September 2012",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

local frameSkip = 4       -- draw once every frameSkip+1 frames 
local counter = 0
local xpArr = {
"",
"\255\255\100\0I",
"\255\255\120\50II",
"\255\240\140\75III",
"\255\220\150\100IV",
"\255\200\200\200V",
"\255\210\210\200VI",
"\255\220\220\200VII",
"\255\230\230\200VIII",
"\255\240\240\200IX",
"\255\255\255\200X"
}
local tempTooltip = nil
local min = math.min
local floor = math.floor
local ceil = math.ceil
local modf = math.modf
local GetMouseState = Spring.GetMouseState
local TraceScreenRay = Spring.TraceScreenRay
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
local spGetUnitExperience = Spring.GetUnitExperience
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetUnitTeam = Spring.GetUnitTeam

function widget:Initialize()
	Spring.SendCommands({"tooltip 0"})
	
	Spring.SetDrawSelectionInfo(false)
	
	-- find shield weapon and its max power
	for _,ud in pairs(UnitDefs) do
		ud.shieldPower   = 0;
		local shieldDefID = ud.shieldWeaponDef
		ud.shieldPower = ((shieldDefID)and(WeaponDefs[shieldDefID].shieldPower))or(-1)
	end
end
 
 
function widget:Shutdown()
        Spring.SendCommands({"tooltip 1"})
end
 
 
-- format number  
-- TODO put this on a lib
function FormatNbr(x,digits)
	if x then
		local _,fractional = modf(x)
		if fractional==0 then
			return x
		elseif fractional<0.01 then
			return floor(x)
		elseif fractional>0.99 then
			return ceil(x)
		else
			local ret=string.format("%."..(digits or 0).."f",x)
			if digits and digits>0 then
				while true do
					local last = string.sub(ret,string.len(ret))
					if last=="0" or last=="." then
						ret = string.sub(ret,1,string.len(ret)-1)
					end
					if last~="0" then
						break
					end
				end
			end
			return ret
		end
	end
end

-- generates upgrade data string for player
function GetTooltipUpgradeData(teamId)
	local NewTooltip = ""
	
	-- get upgrades for team
	local statusStr = spGetTeamRulesParam(teamId,"upgrade_status")
	local listStr = spGetTeamRulesParam(teamId,"upgrade_list")
	local modStr = spGetTeamRulesParam(teamId,"upgrade_modifiers")
	
	if (statusStr) then
		NewTooltip = NewTooltip..statusStr.."\n"
	end
	if (listStr) then
		NewTooltip = NewTooltip..listStr.."\n"
	end
	if (modStr) then
		NewTooltip = NewTooltip.." \nEFFECTS\n"..modStr
	end
			
	return NewTooltip
end


-- generates upgrade summary string for player
function GetTooltipUpgradeLabel(teamId)
	local NewTooltip = ""
	
	-- get upgrades for team
	local labelStr = spGetTeamRulesParam(teamId,"upgrade_label")
	
	if (labelStr) then
		NewTooltip = NewTooltip..labelStr
	else
		NewTooltip = NewTooltip.."Upgrades: \255\130\130\130[0]  [0]  [0]"
	end
			
	return NewTooltip
end

-- generates weapon data string for unit
function GetTooltipWeaponData(ud, xpMod, rangeMod, dmgMod)
	local NewTooltip = ""
	
	if not rangeMod then
		rangeMod = 1
	end
	if not dmgMod then
		dmgMod = 1
	end
	
	if ud.canKamikaze then
	    local weapname=ud.selfDExplosion
	    local weap=nil
	    for wid,weaponDef in pairs(WeaponDefs) do
	        if weaponDef.name==weapname then
	        	weap=WeaponDefs[wid]
	        end
	    end
	    if weap then
	        local weapon_action="Damage"
	        if weap.damages and weap.damages.paralyzeDamageTime and weap.damages.paralyzeDamageTime>0 then
	                weapon_action="Paralyze"
	        end
	        NewTooltip = NewTooltip.."\n\255\255\213\213Damage: \255\255\170\170"..FormatNbr(dmgMod * weap.damages[Game.armorTypes.default],2).."/once"
	    end
    elseif ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
		for _,w in pairs(ud.weapons) do
			local weap=WeaponDefs[w.weaponDef]
		    if weap.isShield == false and weap.description ~= "No Weapon" then
                local weapon_action="Dmg/s"
                local reloadTime = weap.reload / xpMod
                local isBeamLaser = weap.type == "BeamLaser"
                local dps = dmgMod * (weap.damages[Game.armorTypes.default] * (weap.projectiles*weap.salvoSize)) / reloadTime
                local energyPerSecond = (weap.energyCost * (weap.projectiles*weap.salvoSize)) / reloadTime

                local range = weap.range * rangeMod
                local hitpower = "L"
                
                if ( weap.damages[Game.armorTypes.default] == weap.damages[Game.armorTypes.armor_heavy] ) then
                	hitpower = "H"
                elseif ( weap.damages[Game.armorTypes.default] == weap.damages[Game.armorTypes.armor_medium] ) then
                	hitpower = "M"
                end
                
                if weap.damages and weap.damages.paralyzeDamageTime and weap.damages.paralyzeDamageTime>0 then
                   weapon_action="Paralyze/s"
                end
                NewTooltip = NewTooltip.."\n\255\255\255\255"..weap.description.."    "..weapon_action..": \255\255\255\255"..
                FormatNbr(dps,1).."("..hitpower..")     Range: "..FormatNbr(range,2)

                if energyPerSecond  > 0 then
                   NewTooltip = NewTooltip.."     \255\255\255\0E/s: "..FormatNbr(energyPerSecond,1)
                end
                
                if weap.waterWeapon then
                	 NewTooltip = NewTooltip.."    \255\64\64\255WATER"
                end
		    end
		end
    end
    
    return NewTooltip
end
 
-- generates new tooltip 
function GenerateNewTooltip()
        local CurrentTooltip = Spring.GetCurrentTooltip()
 
        if tempTooltip and frameSkip > 0 then
           counter = counter +1
           if (counter % (frameSkip+1) ~= 0) then
              return tempTooltip
           end
        end
 
        local NewTooltip = ""
        local HotkeyTooltip = ""
        local FoundTooltipType = nil
        local mx,my,gx,gy,gz,id
 
        mx,my = GetMouseState()
        if mx and my then
                local _,pos = TraceScreenRay(mx,my,true,true)
                if pos then
                        gx,gy,gz=unpack(pos)
                end
                local kind,var1 = TraceScreenRay(mx,my,false,true)
                if kind=="unit" then
                        id = var1
                end
        end
 
        
        if spGetSelectedUnitsCount()>1 then
			NewTooltip=NewTooltip.."\255\255\255\255"..spGetSelectedUnitsCount().."\255\255\255\255 units selected\255\255\255\255\n"
        end
        
 
        local TerrainType = string.match(CurrentTooltip,"Terrain type: (.+)\nSpeeds T/K/H/S ")
        local TerrainSpeeds = string.match(CurrentTooltip,"Speeds T/K/H/S (.+)\nHardness")
        if TerrainType~=nil then
                NewTooltip=NewTooltip.."\255\255\255\64"..TerrainType
                if TerrainSpeeds~=nil then
                        TerrainSpeedList={}
                        for Speed in string.gmatch(TerrainSpeeds,"[0-7]+.[0-7]+") do
                                table.insert(TerrainSpeedList,Speed)
                        end
                        if #TerrainSpeedList>=1 then
                                local DiffSpeed = false
                                for _,Speeds in pairs(TerrainSpeedList) do
                                        if Speeds~=TerrainSpeedList[1] then
                                                DiffSpeed = true
                                        end
                                end
                                for i=1,#TerrainSpeedList do
                                        while true do
                                                local last = string.sub(TerrainSpeedList[i],string.len(TerrainSpeedList[i]))
                                                if last=="0" or last=="." then
                                                        TerrainSpeedList[i] = string.sub(TerrainSpeedList[i],1,string.len(TerrainSpeedList[i])-1)
                                                end
                                                if last~="0" then
                                                        break
                                                end
                                        end
                                end
                                if DiffSpeed then
                                        NewTooltip=NewTooltip.."\nSpeeds x "..TerrainSpeeds
                                else
                                        NewTooltip=NewTooltip.."\nSpeed x"..TerrainSpeedList[1]
                                end
                        end
                end
                if gx and gz then
                        --NewTooltip=NewTooltip.."\n\n("..(32)*floor((gx+16)/32)..","..(32)*floor((gz+16)/32)..")"
                        NewTooltip=NewTooltip.."\n\n("..floor(gx+0.5)..","..floor(gz+0.5)..")"
                end
                FoundTooltipType="terrain"
        end
 
        local buildpower = 1
        
        -- compute total buildpower of units selected 
        if spGetSelectedUnitsCount() >= 1 then
           for _,u in pairs(spGetSelectedUnits()) do
		      local def=UnitDefs[Spring.GetUnitDefID(u)]
		      buildpower = buildpower + def.buildSpeed
           end
        end   

        local unitpre = string.match(CurrentTooltip,"(.-)\nBuild:") or string.match(CurrentTooltip,"(.-)\n\255\255\255\255Build:") or ""
        local unitname = string.match(CurrentTooltip,"Build: (.+) %- ")
        local unitdesc = string.match(CurrentTooltip," %- (.+)\nHealth ")
        local unithealth = string.match(CurrentTooltip,"Health (.+)\nMetal")
        local unitbuildtime = string.match(CurrentTooltip.."\n","Build time (.-)\n")
        local unitmetalcost = string.match(CurrentTooltip,"Metal cost (.-)\nEnergy cost ")
        local unitenergycost = string.match(CurrentTooltip,"\nEnergy cost (.-).Build time ")

        if unitname and unitdesc and unithealth and unitbuildtime then
            local fud = nil
            for _,ud in pairs(UnitDefs) do
                    --[[
                    Spring.Echo("ud.humanName=",ud.humanName)
                    Spring.Echo("ud.tooltip=",ud.tooltip)
                    Spring.Echo("ud.health=",ud.health)
                    Spring.Echo("ud.buildTime=",ud.buildTime)
                    ]]--
                    if ud.humanName==unitname and ud.tooltip==unitdesc and ""..ud.health==unithealth and
                            ""..ud.buildTime==unitbuildtime then
                            fud=ud
                            break
                    end
            end
            if fud then
        		local armorTypeStr= "L"
        		if ( Game.armorTypes[fud.armorType] == "armor_heavy" ) then armorTypeStr = "H"
        		elseif ( Game.armorTypes[fud.armorType] == "armor_medium" ) then armorTypeStr = "M" end
        
                NewTooltip = NewTooltip.."\n"..unitpre.."\n"..fud.humanName.." ("..fud.tooltip..")\n"..
						"\255\200\200\200Metal: "..unitmetalcost.."    \255\255\255\0Energy: "..unitenergycost..""..
                        "\255\213\213\255".."    Build time: ".."\255\170\170\255"..
                        floor((29+floor(31+fud.buildTime/(buildpower/32)))/30).."s\n"..
                        "\255\200\200\200Health: ".."\255\200\200\200"..fud.health.."("..armorTypeStr..")"
                        if fud.shieldPower > 0 then NewTooltip=NewTooltip.."\255\64\64\255     Shield: "..FormatNbr(fud.shieldPower) end
						
				-- weapons
                if fud.weapons and fud.weapons[1] and fud.weapons[1].weaponDef then
					NewTooltip = NewTooltip..GetTooltipWeaponData(fud,1)
                end
                
                -- speed
                NewTooltip = NewTooltip.."\255\255\255\255\n"
                if fud.speed and fud.speed>0 then
                        NewTooltip = NewTooltip.."\255\193\255\187Speed: \255\134\255\121"..FormatNbr(fud.speed,2).."\255\255\255\255"
                end
                FoundTooltipType="knownbuildbutton"

                if fud.windGenerator > 1 then
	               	local minWindE = FormatNbr((fud.windGenerator/25)*Game.windMin,0)
                	local maxWindE = FormatNbr((fud.windGenerator/25)*Game.windMax,0)
                	NewTooltip = NewTooltip.."Generates \255\255\255\0"..minWindE.."-"..maxWindE.." E/s\255\255\255\255 (up to +20% on higher ground) \n"
                elseif fud.tidalGenerator == 1 then
                	NewTooltip = NewTooltip.."Generates \255\255\255\0"..Game.tidal.." E/s\255\255\255\255\n"
                end

                if fud.customParams.tip then
                	NewTooltip = NewTooltip.."\n\255\180\180\180"..fud.customParams.tip.."\255\255\255\255\n"
                end
            else
                NewTooltip = NewTooltip.."\n"..unitpre.."\n"..unitname.." ("..unitdesc..")\n"..
                        "\255\255\213\213Health: ".."\255\255\170\170"..unithealth..
                        "\n\255\213\213\255Build time: ".."\255\170\170\255"..
                        floor((29+floor(31+unitbuildtime/(buildpower/32)))/30).."s"..
                        "\255\255\255\255\n"
                FoundTooltipType="unknownbuildbutton"
            end
        end
 
        local isItLiveUnitTooltip = string.match(CurrentTooltip,"Experience (.+) Cost ")
        if isItLiveUnitTooltip or CurrentTooltip=="" then

                -- id being calculated way above
                if not id and spGetSelectedUnitsCount()>=1 then
                        id = spGetSelectedUnits()[spGetSelectedUnitsCount()]
                end
                
				-- many units
				if id and spGetSelectedUnitsCount()>1 then
					local totalMetalMake = 0
					local totalMetalUse = 0 
					local totalEnergyMake = 0
					local totalEnergyUse = 0
					local totalHealth = 0
					local totalMaxHealth = 0
					local totalShieldPower = 0
					local totalMaxShieldPower = 0
					local totalEnergyCost = 0
					local totalMetalCost = 0
					local anyShield = false
					
					for _,u in pairs(spGetSelectedUnits()) do
					
						local hpMod = spGetUnitRulesParam(u,"upgrade_hp")
						if not hpMod then
							hpMod = 1
						else
							hpMod = 1 + hpMod
						end
						local ud=UnitDefs[Spring.GetUnitDefID(u)]
						local metalMake,metalUse,energyMake,energyUse = Spring.GetUnitResources(u)
						local health,maxHealth,paralyzeDamage,captureProgress,buildProgress = Spring.GetUnitHealth(u)						
						health = health * hpMod
						maxHealth = maxHealth * hpMod
						local hasShield, ShieldPower=Spring.GetUnitShieldState(u)
						local maxShieldPower = ud.shieldPower
						if(hasShield) then
							anyShield = true
						end
						
						-- energy and metal cost
						totalEnergyCost = totalEnergyCost + ud.energyCost
						totalMetalCost = totalMetalCost + ud.metalCost
												
						if (health and maxHealth) then
	                        totalHealth = totalHealth + health
	                        totalMaxHealth = totalMaxHealth + maxHealth
                        end
                        if (hasShield) then
	                        totalShieldPower = totalShieldPower + ShieldPower
	                        totalMaxShieldPower = totalMaxShieldPower + maxShieldPower
						end
						
						-- energy and metal upkeep
						if( metalMake and metalUse and energyMake and energyUse) then
							totalMetalMake = totalMetalMake + metalMake
							totalMetalUse = totalMetalUse + metalUse
							totalEnergyMake = totalEnergyMake + energyMake
							totalEnergyUse = totalEnergyUse + energyUse							
						end
					end
					
					-- cost
					NewTooltip = NewTooltip.."\255\200\200\200Metal: "..totalMetalCost.."    \255\255\255\0Energy: "..totalEnergyCost.."\n"
					
					-- health totals					
                    NewTooltip = NewTooltip.."\255\200\200\200Health: ".."\255\200\200\200"..floor(totalHealth).."\255\200\200\200/\255\200\200\200"..floor(totalMaxHealth)
                    if anyShield then NewTooltip=NewTooltip.."\255\64\64\255      Shield: "..FormatNbr(math.min(totalShieldPower,totalMaxShieldPower)).."/"..FormatNbr(totalMaxShieldPower) end

                    -- energy and metal upkeep totals
                    if true then
                        NewTooltip = NewTooltip.."\n\255\200\200\200Metal: \255\0\255\0+"..FormatNbr(totalMetalMake,1).."\255\255\255\255/\255\255\0\0"..FormatNbr(-totalMetalUse,1)
						NewTooltip = NewTooltip.."    \255\255\255\0Energy: \255\0\255\0+"..FormatNbr(totalEnergyMake,1).."\255\255\255\255/\255\255\0\0"..FormatNbr(-totalEnergyUse,1)
                    end
					FoundTooltipType="liveunit"
					
                -- one unit
                elseif id or spGetSelectedUnitsCount()==1 then
                        local u=id
                        local ud=UnitDefs[Spring.GetUnitDefID(u)]

                        local metalMake,metalUse,energyMake,energyUse = Spring.GetUnitResources(u)
        				local isFriendly = metalMake ~= nil       -- assume only friendly units have this info

                        -- build progress, health and shield
                        local health,maxHealth,paralyzeDamage,captureProgress,buildProgress = Spring.GetUnitHealth(u)
                        stunned_or_beingbuilt, stunned, beingbuilt = Spring.GetUnitIsStunned(u)
                        NewTooltip = NewTooltip.."\n"..ud.humanName.." ("..ud.tooltip..")"
						local hpMod = spGetUnitRulesParam(u,"upgrade_hp")
						if not hpMod then
							hpMod = 1
						else
							hpMod = 1 + hpMod
						end
						health = health * hpMod
						maxHealth = maxHealth * hpMod
						-- experience
						local xp = spGetUnitExperience(u)
						local xpMod = 1
                        if xp and xp>0 then
                    		local xpIndex = math.min(10,math.max(floor(11*xp/(xp+1)),0))+1
                    		xpMod = 1+0.35*(xp/(xp+1))
                    		if(xpIndex > 1) then
                            	NewTooltip = NewTooltip.."\255\255\255\255    Experience: "..xpArr[xpIndex]
                            end
                        end
                        local dmgMod = spGetUnitRulesParam(u,"upgrade_damage")
						if not dmgMod then
							dmgMod = 1
						else
							dmgMod = 1 + dmgMod
						end
                        local rangeMod = spGetUnitRulesParam(u,"upgrade_range")
						if not rangeMod then
							rangeMod = 1
						else
							rangeMod = 1 + rangeMod
						end
												
						                        
                        -- paralysis
                        if stunned then
                                NewTooltip = NewTooltip.."\255\194\173\255   PARALYZED"
                        end
                        -- cloaking
                        if spGetUnitIsCloaked(u) then
                                NewTooltip = NewTooltip.."\255\170\170\170   CLOAKED"
                        end        
                        -- alliance                
                        if isFriendly == false then
                        	NewTooltip = NewTooltip.."   \255\255\0\0ENEMY"	
                        end
                        NewTooltip = NewTooltip.."\n"
                        if buildProgress and buildProgress<1 then
                                NewTooltip = NewTooltip.."\255\213\213\255".."Build progress: ".."\255\170\170\255"..FormatNbr(100*buildProgress).."%\n"
                        end

						-- cost
						NewTooltip = NewTooltip.."\255\200\200\200Metal: "..ud.metalCost.."    \255\255\255\0Energy: "..ud.energyCost.."\n"


                		local armorTypeStr= "L"
                		if ( Game.armorTypes[ud.armorType] == "armor_heavy" ) then armorTypeStr = "H"
                		elseif ( Game.armorTypes[ud.armorType] == "armor_medium" ) then armorTypeStr = "M" end

						local hasShield, ShieldPower=Spring.GetUnitShieldState(id)
						local maxShieldPower = ud.shieldPower
						if (health ~= nil) then
                        	NewTooltip = NewTooltip.."\255\200\200\200Health: ".."\255\200\200\200"..floor(health).."\255\200\200\200/\255\200\200\200"..floor(maxHealth).."("..armorTypeStr..")"
                        	if hasShield then NewTooltip=NewTooltip.."\255\64\64\255      Shield: "..FormatNbr(math.min(ShieldPower,maxShieldPower)).."/"..FormatNbr(maxShieldPower) end
                        end
                        
                        -- energy and metal upkeep
                        if isFriendly then
	                        NewTooltip = NewTooltip.."    \255\200\200\200Metal: \255\0\255\0+"..FormatNbr(metalMake,1).."\255\255\255\255/\255\255\0\0"..FormatNbr(-metalUse,1)
	                        NewTooltip = NewTooltip.."    \255\255\255\0Energy: \255\0\255\0+"..FormatNbr(energyMake,1).."\255\255\255\255/\255\255\0\0"..FormatNbr(-energyUse,1)
						    -- NewTooltip=NewTooltip.."\255\255\255\0     +E/M ratio: "..FormatNbr(energyMake / ud.metalCost,4).."\n"
                        end

                        -- weapons
                        NewTooltip = NewTooltip..GetTooltipWeaponData(ud,xpMod,rangeMod,dmgMod).."\n"
                        
                        -- upgrades (upgrade centers only)
                        local isUpgradeCenter = string.find(ud.name, "upgrade_center")
                        local teamId = spGetUnitTeam(u)
                        if isUpgradeCenter then
                        	NewTooltip = NewTooltip..GetTooltipUpgradeData(teamId).."\n\n"
						end
						
						-- speed
                        if ud.speed and ud.speed>0 then
							local speedMod = spGetUnitRulesParam(u,"upgrade_speed")
							if not speedMod then
								speedMod = 1
							else
								speedMod = 1 + speedMod
							end
							
                            local vx,vy,vz = spGetUnitVelocity(u)
                            local speed = 30*math.sqrt(vx*vx+vz*vz)
                            NewTooltip = NewTooltip.."\255\193\255\187Speed: \255\134\255\121"..FormatNbr(speed).."\255\193\255\187/\255\134\255\121"..FormatNbr(ud.speed*speedMod,2).."\255\255\255\255      "
                        end

                        if ud.transportCapacity>0 and ud.transportMass>0 and isFriendly then
                                local currentCapacityUsage = 0 
                                local currentMassUsage = 0

								-- get sum of mass and size for all transported units                                
                                for _,tUnit in pairs(Spring.GetUnitIsTransporting(u)) do
									local tUd=UnitDefs[Spring.GetUnitDefID(tUnit)]
                                	currentCapacityUsage = currentCapacityUsage + tUd.xsize 
                                	currentMassUsage = currentMassUsage + tUd.mass
                                end
                                 
                                NewTooltip = NewTooltip.."\255\255\255\255Transport: "..FormatNbr(min(2,(currentCapacityUsage/ud.transportCapacity))*50,0).."% / "..FormatNbr((currentMassUsage/ud.transportMass)*100,0).."%      "
                        end

						-- upgrade summary
						if not isUpgradeCenter then
							NewTooltip = NewTooltip..GetTooltipUpgradeLabel(spGetUnitTeam(u))
 						end
 						
						if ud.customParams.tip then
                			NewTooltip = NewTooltip.."\n\255\180\180\180"..ud.customParams.tip.."\255\255\255\255\n"
                		end
 
                        FoundTooltipType="liveunit"
                end
        end
 
        local hotkeys = string.match(CurrentTooltip.."\n","Hotkeys: (.-)\n")
        if hotkeys then
                HotkeyTooltip = "\n\255\255\196\128Hotkeys: ".."\255\255\128\001"..hotkeys.."\255\255\255\255"
                CurrentTooltip=string.gsub(CurrentTooltip.."\n","Hotkeys: .-\n","")
                NewTooltip=NewTooltip..HotkeyTooltip
                CurrentTooltip=CurrentTooltip..HotkeyTooltip
        end
 
        local action = string.match(CurrentTooltip,"(.-)\n")
        if action then
                action = string.match(action,"(.-): ")
                if action then
                        CurrentTooltip=string.gsub(CurrentTooltip,"(.-): ","",1)
                        CurrentTooltip="\255\170\255\170"..action..":\255\255\255\255 "..CurrentTooltip
                end
        end
 
 
        if FoundTooltipType then
 				tempTooltip = NewTooltip
                return NewTooltip
        else
        		tempTooltip = CurrentTooltip
                return CurrentTooltip
        end
end
 
 
local FontSize
local xTooltipSize = 0
local yTooltipSize = 0
 
function widget:DrawScreenEffects(vsx,vsy)
        WG.KP_ToolTip=nil
        if Spring.IsGUIHidden() then
                return
        end
 
        local nttString = GenerateNewTooltip()
        local nttList = {}
        local maxWidth = 0
        for line in string.gmatch(nttString,"[^\r\n]+") do
                table.insert(nttList,"\255\255\255\255"..line)
                if gl.GetTextWidth(line)>maxWidth then
                        maxWidth=gl.GetTextWidth(line)
                end
        end
 
        if not FontSize then
                FontSize = math.max(8,4+vsy/100)
        end
 
        local TextWidthFixHack = 1
        if tonumber(string.sub(Game.version,1,4))<=0.785 and string.sub(Game.version,1,5)~="0.78+" then
                TextWidthFixHack = (vsx/vsy)*(4/3)
        end
        xTooltipSize = FontSize*(1+maxWidth*TextWidthFixHack)
        yTooltipSize = FontSize*(1+#nttList)
 
        -- Bottom left position by default
        local x1,y1,x2,y2=0,0,xTooltipSize,yTooltipSize
 
        -- if there's a KP_OnsHelpTip, and if it is on bottom left corner, then place KP_ToolTip above
        if WG.KP_OnsHelpTip and WG.KP_OnsHelpTip.x1 and WG.KP_OnsHelpTip.y1 and WG.KP_OnsHelpTip.x1==0 and WG.KP_OnsHelpTip.y1==0 then
                y1=WG.KP_OnsHelpTip.y2 or 0
                y2=y1+yTooltipSize
        end
 
        -- Note: this line is done even if the KP_ToolTip is devoid of text
        -- The only case where KP_ToolTip is nil are when the widget is off or the GUI is hidden
        WG.KP_ToolTip={x1=x1,y1=y1,x2=x2,y2=y2,xSize=xTooltipSize,ySize=yTooltipSize,FontSize=FontSize}
 
        gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA) -- default
        if WG.MidKnightBG then
                gl.Color(1,1,1,1)
                gl.Texture("bitmaps/tooltipbg.png")
                gl.TexRect(x1,y1,x2*1.2,y2*1.2,0.01,0.99,0.99,0.01)
                gl.Texture(false)
        else
                gl.Color(0.0,0.0,0.0,0.5)  --background
                gl.Rect(x1,y1,x2,y2)
                gl.Color(0.0,0.0,0.0,1)  --border
                gl.LineWidth(1)
                gl.Shape(GL.LINE_LOOP,{
                        {v={x1,y2}},{v={x2,y2}},
                        {v={x2,y1}},{v={x1,y1}},})
                gl.Color(1,1,1,1)
        end
        for k=1,#nttList do
                gl.Text(nttList[k],x1+FontSize/2,y1+FontSize*(#nttList+0.5-k),FontSize,'o')
        end
        gl.Text("\255\255\255\255 ",0,0,FontSize,'o') -- Reset color to white for other widgets using gl.Text
end
 
 
--function widget:MouseWheel(up,value)
--        local xMouse,yMouse = GetMouseState()
--        if xMouse < xTooltipSize and yMouse < yTooltipSize and not Spring.IsGUIHidden() then
--                if up then
--                        FontSize = math.max(FontSize - 1,2)
--                else
--                        FontSize = FontSize + 1
--                end
--                return true
--        end
--        return false
--end