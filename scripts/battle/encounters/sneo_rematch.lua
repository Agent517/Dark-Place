local SNEORematch, super = Class(Encounter)

function SNEORematch:init()
    super:init(self)

    self.text = "* Time to be a BIG SHOT once more!"

    self.music = "deltarune/spamton_neo_mix_ex_wip"

    self.background = true

	--self.default_xactions = false

    -- Add the enemy to the encounter
    self:addEnemy("spamtonneo", 518, 250)
	
	self.flee = false

    self.boss_rush = false
	
    if Game:getFlag("sneo_defeated") == true then
        self.boss_rush = true
    end
end

function SNEORematch:onBattleStart(battler)
    --Game:setFlag("f1", true)
    if Game:hasPartyMember("susie") then
	    Game.battle:registerXAction("susie", "Snap")
	    Game.battle:registerXAction("susie", "AutoAim", "Homing\nbullets", 80)
    else
	    Game.battle:registerXAction(battler.chara.id, "Snap")
    end
end

function SNEORematch:getPartyPosition(index)
    if Game.battle.party[4] then
	    if index == 1 then -- if it's the first party member (in this case, kris)
		    return 103, 136 -- just an example please do not do this number
		elseif index == 2 then -- if it's the first party member (in this case, kris)
		    return 111, 188 -- just an example please do not do this number
		elseif index == 3 then -- if it's the first party member (in this case, kris)
		    return 105, 249 -- just an example please do not do this number
		elseif index == 4 then -- if it's the first party member (in this case, kris)
		    return 97, 305 -- just an example please do not do this number
	    else
		    return super:getPartyPosition(self, index)
		end
	else
	    if index == 1 then -- if it's the first party member (in this case, kris)
		    return 103, 136 -- just an example please do not do this number
		else
		    return super:getPartyPosition(self, index)
		end
	end
end

return SNEORematch