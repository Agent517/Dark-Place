---@class JukeboxMenu : Object
---@overload fun(...) : JukeboxMenu
local JukeboxMenu, super = Class(Object)

JukeboxMenu.MAX_WIDTH = 540
JukeboxMenu.SONG_INFO_AREA_X = 300
JukeboxMenu.MIN_WIDTH = JukeboxMenu.MAX_WIDTH - JukeboxMenu.SONG_INFO_AREA_X

function JukeboxMenu:init(simple)
    super.init(self, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, simple and self.MIN_WIDTH or self.MAX_WIDTH, 360)

    self.parallax_x = 0
    self.parallax_y = 0
    self.layer = WORLD_LAYERS["ui"]
    self:setOrigin(0.5, 0.5)

    self.box = UIBox(0, 0, self.width, self.height)
    self.box.layer = -1
    self.box.debug_select = false
    self:addChild(self.box)

    ---@type love.Font
    self.font = Assets.getFont("main")
    self.font_2 = Assets.getFont("plain")
    -- DP HACK
    self.font_cjk = Assets.getFont("simsun_small")

    self.heart = Sprite("player/heart_menu")
    self.heart:setOrigin(0.5, 0.5)
    self.heart:setScale(2)
    self.heart:setColor(Game:getSoulColor())
    self.heart.layer = 1
    self.heart.x = 16
    self:addChild(self.heart)

    self.none_text = "---"
    self.none_album = "default"
    self.default_song = {
        name = nil,
        file = nil,
        composer = nil,
        released = nil,
        origin = nil,
        locked = nil,
        album = nil
    }

    self.songs = modRequire("scripts.jukebox_songs")
    self.album_art_cache = {}
    self.album_art_cache[self.none_album] = Assets.getTexture("albums/"..self.none_album)
    for _,song in ipairs(self.songs) do
        if song.locked == nil then
            song.locked = not Mod:evaluateCond(song, self)
        else
            song._locked_explicit = true
        end
        if song.album and not self.album_art_cache[song.album] then
            self.album_art_cache[song.album] = Assets.getTexture("albums/"..song.album)
        end
    end

    self.pages = {}
    self.page_index = 1
    self.songs_per_page = 7
    self.selected_index = {}
    for page = 1, math.ceil(#self.songs / self.songs_per_page) do
        local start_index = 1 + (page-1) * self.songs_per_page
        self.pages[page] = {unpack(self.songs, start_index, math.min(start_index + self.songs_per_page - 1, #self.songs))}
        self.selected_index[page] = 1
    end

    local playing_song = nil
    for _,song in ipairs(self.songs) do
        if not song.locked and song.file == Game.world.music.current then
            playing_song = song
            break
        end
    end
    if playing_song then
        for page_index,page in ipairs(self.pages) do
            local song_index = Utils.getIndex(page, playing_song)
            if song_index then
                self.page_index = page_index
                self.selected_index[page_index] = song_index
            end
        end
    end

    self:calculateHeartTargetY()
    self.heart.y = self.heart_target_y

    self.info_collpasible = not simple and false -- yeah
    self.info_accordion_timer_handle = nil
end

function JukeboxMenu:draw()
    super.draw(self)

    Draw.pushScissor()
    local box_pad = 20 -- HACK because working with UIBoxes is annoying
    Draw.scissor(-box_pad, -box_pad, self.width+box_pad*2, self.height+box_pad*2)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.printf("JUKEBOX", 0, -17, self.width, "center")
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", -16, 20, self.width+32, 1)

    local page = self.pages[self.page_index]

    love.graphics.setLineWidth(1)
    local world_music = (Game.world.music and Game.world.music:isPlaying()) and Game.world.music
    for i = 1, self.songs_per_page do
        love.graphics.setColor(0, 0.4, 0)
        love.graphics.rectangle("line", 2, 40 + 40 * (i - 1), 240, 1)

        local song = page[i] or self.default_song
        local name = song.name or self.none_text
        if song.locked then name = "Locked" end
        love.graphics.setColor(1, 1, 1)
        if not song.file or song.locked then
            love.graphics.setColor(0.5, 0.5, 0.5)
        elseif world_music and world_music.current == song.file then
            love.graphics.setColor(1, 1, 0)
        end
        local scale_x = math.min(math.floor(196 / self.font:getWidth(name) * 100) / 100, 1)
        love.graphics.print(name, 40, 40 + 40 * (i - 1) + 3, 0, scale_x, 1)
    end

    -- draw the last line
    love.graphics.setColor(0, 0.4, 0)
    love.graphics.rectangle("line", 2, 40 + 40 * self.songs_per_page, 240, 1)
    love.graphics.setLineWidth(4)
    love.graphics.setColor(1, 1, 1)

    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.setFont(self.font_2)
    love.graphics.printf("Page "..self.page_index.."/"..#self.pages, -16, (43 + 40 * (self.songs_per_page - 1)) + 60, 276, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)

    --[[
    love.graphics.rectangle("line", -16, 330, 276, 1)

    love.graphics.print("[X] Back", 0, 340)
    love.graphics.printf("[C] Info", 0, 340, 250, "right")
    ]]

    local info_area_sep_padding = 40
    local info_area_sep_a = (self.width - self.SONG_INFO_AREA_X + info_area_sep_padding)/(self.MIN_WIDTH + info_area_sep_padding)
    love.graphics.setColor(1, 1, 1, info_area_sep_a)
    love.graphics.rectangle("line", self.SONG_INFO_AREA_X - info_area_sep_padding, 20, 1, 356)
    love.graphics.setColor(1, 1, 1)

    local song = page[self.selected_index[self.page_index]] or self.default_song

    love.graphics.setColor(1, 1, 1)
    local album_art_path = song.album or self.none_album
    if not song.file or song.locked then
        album_art_path = self.none_album
    end
    local album_art = self.album_art_cache[album_art_path]
    love.graphics.draw(album_art, 410, 162, 0, 1, 1, album_art:getWidth()/2, album_art:getHeight()/2)

    local info_font = self.font
    local info_scale = 0.5
    -- DP HACK
    if song.cjk_info then
        info_font = self.font_cjk
        info_scale = 1
    end
    love.graphics.setFont(info_font)
    local info_w = 260 / info_scale
    local info = string.format(
        "Composer: %s\nReleased: %s\nOrigin: %s",
        song.composer or self.none_text,
        song.released or self.none_text,
        song.origin or self.none_text
    )
    local _, info_lines = info_font:getWrap(info, info_w)
    local info_yoff = info_font:getHeight() * #info_lines * info_scale
    love.graphics.printf(info, 270, 372 - info_yoff, info_w, "left", 0, info_scale, info_scale)

    love.graphics.setColor(1, 1, 1)

    Draw.popScissor()
end

function JukeboxMenu:update()
    local function warpIndex(index)
        return Utils.clampWrap(index, 1, self.songs_per_page)
    end

    if not OVERLAY_OPEN then
        --close menu
        if Input.pressed("cancel", false) then
            Assets.playSound("ui_cancel_small")
            Game.world:closeMenu()
            return
        end

        --play song
        if Input.pressed("confirm", false) then
            local song = self.pages[self.page_index][self.selected_index[self.page_index]] or self.default_song

            if not song._locked_explicit then
                song.locked = not Mod:evaluateCond(song, self)
            end

            if not song.locked and song.file then
                Game.world.music:play(song.file, 1)
            else
                Assets.playSound("error")
            end
        end

        --page left
        if Input.pressed("left", true) then
            Assets.playSound("ui_move")
            self.page_index = self.page_index - 1
        end
        --page right
        if Input.pressed("right", true) then
            Assets.playSound("ui_move")
            self.page_index = self.page_index + 1
        end
        self.page_index = Utils.clampWrap(self.page_index, 1, #self.pages)

        local page = self.pages[self.page_index]
        --move up
        if Input.pressed("up", true) then
            Assets.playSound("ui_move")
            self.selected_index[self.page_index] = warpIndex(self.selected_index[self.page_index] - 1)
            while not page[self.selected_index[self.page_index]] do
                self.selected_index[self.page_index] = warpIndex(self.selected_index[self.page_index] - 1)
            end
        end
        --move down
        if Input.pressed("down", true) then
            Assets.playSound("ui_move")
            self.selected_index[self.page_index] = warpIndex(self.selected_index[self.page_index] + 1)
            while not page[self.selected_index[self.page_index]] do
                self.selected_index[self.page_index] = warpIndex(self.selected_index[self.page_index] + 1)
            end
        end
        --self.selected_index[self.page_index] = warpIndex(self.selected_index[self.page_index])

        if self.info_collpasible and Input.pressed("menu", false) then
            local dest_width = Utils.xor(self.width > self.MIN_WIDTH, self.info_accordion_timer_handle and self.info_accordion_timer_handle.direction)
                and self.MIN_WIDTH or self.MAX_WIDTH
            --[[Log:print(self.width, self.width > self.MIN_WIDTH,
                not not self.info_reveal_timer_handle, self.info_reveal_timer_handle and self.info_reveal_timer_handle.direction,
                dest_width)]]
            Assets.stopAndPlaySound("wing")
            if self.info_accordion_timer_handle then
                Game.world.timer:cancel(self.info_accordion_timer_handle)
            end
            self.info_accordion_timer_handle = Game.world.timer:approach(1/3.5,
                self.width, dest_width,
                function(value)
                    value = math.floor(value)
                    self.width = value
                    self.box.width = value
                end,
                "out-sine",
                function()
                    self.info_accordion_timer_handle = nil
                end
            )
            ---@diagnostic disable-next-line: inject-field
            self.info_accordion_timer_handle.direction = dest_width == self.MIN_WIDTH
        end
    end

    --soul positions
    self:calculateHeartTargetY()
    if math.abs(self.heart_target_y - self.heart.y) <= 2 then
        self.heart.y = self.heart_target_y
    end
    self.heart.y = self.heart.y + (self.heart_target_y - self.heart.y) / 2 * DTMULT
end

function JukeboxMenu:calculateHeartTargetY()
    self.heart_target_y = 60 + 40 * (self.selected_index[self.page_index] - 1)
end

function JukeboxMenu:close()
    Game.world.menu = nil
    self:remove()
end

function JukeboxMenu:onRemove()
    if self.info_accordion_timer_handle then
        Game.world.timer:cancel(self.info_accordion_timer_handle)
    end
end

return JukeboxMenu