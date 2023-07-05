local Touhou, super = Class(Wave)

function Touhou:init()
    super.init(self)

    self.time = 4.0
end

function Touhou:onStart()
	local y_offset = 80
    local mult = 0.5

    self.timer:every(30/60, function()
        local numbullets = 10
        for i = 1, numbullets+1 do
            local bullet = self:spawnBullet("poseur/touhoubullet", Game.battle.arena.x, Game.battle.arena.y + y_offset)
            bullet.offset = math.pi * 2 * i / numbullets
            bullet.negmult = mult
        end
        mult = mult + 0.05
    end)
end

return Touhou
