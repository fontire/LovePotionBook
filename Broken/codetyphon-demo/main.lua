local key_event = require "keyevent"
local restart_event = require "restart_event"
local checkCollision = require "checkCollision"
local player = {}
local enemys = {}
local foods = {}
local projectiles = {}
local time = 0
local score = 0
_gw = 500 -- game screen width
_gh = 800 -- game screen height
local gameover = false
local key = ""

local can_make_projectile = 0


function init()
    player.width = player_img:getWidth()
    player.height = player_img:getHeight()
    player.x = _gw / 2 - player.width/2
    player.y = _gh - player.height
    player.speed = 300
    enemys = {}
    foods = {}
    projectiles = {}
    time = 0
    score = 0
    gameover = false
    bgaudio = love.audio.newSource("assets/bg.mp3", "static")
    love.audio.play(bgaudio)
    scoreText:set(score)
end

function make_a_enemy()
    local enemy = {}
    enemy.x = math.random(0, _gw)
    enemy.y = -200
    enemy.width = enemy_img:getWidth()
    enemy.height = enemy_img:getHeight()
    enemy.speed = 300
    table.insert(enemys, enemy)
end

function make_a_food()
    local food = {}
    food.x = math.random(100, 500)
    food.y = 0
    food.width = 50
    food.height = 50
    table.insert(foods, food)
end

function love.gamepadpressed(joystick, button)
    if button == 'start' then
        love.event.quit()
    end

    key = ""
    if button == "dpup" then key = "up" end
    if button == "dpdown" then key = "down" end
    if button == "dpright" then key = "right" end
    if button == "dpleft" then key = "left" end
    if button == "a" then key = "a" end
    if button == "b" then key = "b" end
end

function love.gamepadreleased(joystick, button)
    key = ""
end

function make_a_projectile()
    can_make_projectile = can_make_projectile - 1
    if can_make_projectile <= 0 then
        can_make_projectile = 10
        local projectile = {}
        projectile.width = projectile_img:getWidth()
        projectile.height = projectile_img:getHeight()
        projectile.x = player.x + player.width / 2 - projectile.width / 2
        projectile.y = player.y
        projectile.speed = 800
        table.insert(projectiles, projectile)
        audio = love.audio.newSource("assets/short.wav", "static")
        love.audio.play(audio)
    end

end

function love.load()
    love.window.setMode( _gw, _gh,{
        fullscreen=false
    } )
    --love.window.setTitle('Space War')
    local font = love.graphics.newFont(50, "mono", 10)
    gameoverText = love.graphics.newText(font, "Game Over")
    font2 = love.graphics.newFont(30, "mono", 10)
    restartText = love.graphics.newText(font2, "press B to restart")
    local fontScore = love.graphics.newFont(20, "mono", 10)
    scoreText = love.graphics.newText(fontScore, score)
    player_img = love.graphics.newImage("assets/player.png")
    enemy_img = love.graphics.newImage("assets/enemy.png")
    projectile_img = love.graphics.newImage("assets/projectile.png")
    init()
end

function love.update(dt)
    if gameover == false then
        time = time + 1

        if time % 60 == 0 then make_a_enemy() end
        -- if time % 300 == 0 then make_a_food() end

        for i, v in ipairs(enemys) do
            v.y = v.y + v.speed * dt
            if checkCollision(player, v, 20, 30, 10, 10) then
                gameover = true
            end
        end
        for i, v in ipairs(foods) do v.y = v.y + 100 * dt end
        for i, v in ipairs(projectiles) do
            v.y = v.y - v.speed * dt
            for ii, vv in ipairs(enemys) do
                if checkCollision(v, vv, 5, 20, 0, 0) then
                    table.remove(projectiles, i)
                    table.remove(enemys, ii)
                    audio = love.audio.newSource("assets/pixel.wav", "static")
                    love.audio.play(audio)
                    score = score + 1
                    scoreText:set(score)
                end
            end
        end

        key_event(key, player, dt, make_a_projectile)
    end

    if gameover == true then
        --if restart_event then
        --   print(restart_event)
        --else
        --    print('nil')
        --end
        restart_event(key,init)
    end

end

function love.draw()
    love.graphics.draw(player_img, player.x, player.y)
    for i, v in ipairs(enemys) do love.graphics.draw(enemy_img, v.x, v.y) end
    -- for i, v in ipairs(foods) do
    --     love.graphics.setColor(50, 200, 50)
    --     love.graphics.rectangle("fill", v.x, v.y, v.width, v.height)
    -- end
    for i, v in ipairs(projectiles) do
        love.graphics.draw(projectile_img, v.x, v.y)
    end

    love.graphics.draw(scoreText, 20, 20)

    if gameover == true then 
        love.graphics.draw(gameoverText, 120, 200)
        love.graphics.draw(restartText, 120, 300)  
    end
end
