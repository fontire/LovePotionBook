function restart_event(key,callback)
  if love._console_name ~= nil then
    if key == "b" then callback(); end
  else
    if love.keyboard.isDown("b") then
      callback()
    end
  end
end

return restart_event