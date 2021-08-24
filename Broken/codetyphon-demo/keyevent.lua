--! file: keyevent.lua
function key_event(key,player,dt,make_a_projectile)
  if love._console_name ~= nil then
    if key == "left" then player.x = player.x - player.speed * dt; end
    if key == "right" then player.x = player.x + player.speed * dt; end
    if key == "up" then player.y = player.y - player.speed * dt; end
    if key == "down" then player.y = player.y + player.speed * dt; end
    if key == "a" then make_a_projectile(); end
  else
    if love.keyboard.isDown("d") then
      player.x = player.x + player.speed * dt
    end
    if love.keyboard.isDown("a") then
      player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("w") then
      player.y = player.y - player.speed * dt
    end
    if love.keyboard.isDown("s") then
      player.y = player.y + player.speed * dt
    end
    if love.keyboard.isDown("space") then
      make_a_projectile()
    end
  end
end

return key_event