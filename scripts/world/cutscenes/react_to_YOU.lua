return function(cutscene)
	local YOU = cutscene:getCharacter("YOU")

	local susie = cutscene:getCharacter("susie")
	if susie then
        cutscene:detachFollowers()

        cutscene:setSpeaker(susie)
		cutscene:showNametag("Susie")
		cutscene:text("* So uh...", "sus_nervous")
		cutscene:hideNametag()
		cutscene:look(YOU, "left")
		cutscene:wait(cutscene:walkTo(susie, YOU.x-60, YOU.y))
		cutscene:look(susie, "right")
		cutscene:showNametag("Susie")
		cutscene:text("* Who are you supposed to be?", "nervous_side")
		cutscene:text("* ...YOU?", "surprise")
		cutscene:text("* Dude, are you pulling my leg or what?", "surprise_smile")
		cutscene:text("* No way someone can have such a LAME name![wait:5] Hahaha!!", "sincere_smile")
		cutscene:text("* ...", "sincere_smile")
		cutscene:text("* Wait, you're serious?", "shock_down")
		cutscene:text("* Oops.", "shock_nervous")
		cutscene:text("* Well uh.. I'm Susie!", "shy_b")
		cutscene:text("* Nice to meet you,[wait:3] YOU the Frog...", "sincere_smile")
		cutscene:text("* ...Who looks at me[wait:3] with a dead inside expression[wait:3] piercing me...", "sus_nervous")
		cutscene:hideNametag()

		cutscene:look(YOU, "down")
		cutscene:wait(2)
		local zoomMusic = Music("forestalt")
		zoomMusic.source:setLooping(false)
		Game.world.camera:setZoom(2)
		local emotion
		Game.world.timer:after(1/4, function()
			Game.world.camera:setZoom(3)
			Game.world.timer:after(1/4, function()
				Game.world.camera:setZoom(4)
				Game.world.timer:after(1/2, function()
					Game.world.camera:setZoom(6)
					Game.world.timer:after(1/2, function()
						emotion = Sprite("bigemotion", -9, 4)
						emotion:setScale(0.125, 0.125)
						Game.world.camera:setZoom(8)
						cutscene:detachCamera()
						Game.world.camera.y = Game.world.camera.y - 18
						YOU:addChild(emotion)
					end)
				end)
			end)
		end)
		cutscene:wait(function()
			return not zoomMusic:isPlaying()
		end)
		zoomMusic:remove()
		emotion:remove()
		Game.world.camera:setZoom(1)
		cutscene:alignFollowers()
		cutscene:attachFollowersImmediate()
		cutscene:attachCameraImmediate()
	end
end