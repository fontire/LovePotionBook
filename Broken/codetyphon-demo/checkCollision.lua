function checkCollision(a, b, padding_up, padding_down, padding_left,
                        padding_right)
    -- With locals it's common usage to use underscores instead of camelCasing
    local a_left = a.x + padding_left
    local a_right = a.x + a.width - padding_right
    local a_top = a.y + padding_up
    local a_bottom = a.y + a.height - padding_down

    local b_left = b.x + padding_left
    local b_right = b.x + b.width - padding_right
    local b_top = b.y + padding_up
    local b_bottom = b.y + b.height - padding_down

    -- Directly return this boolean value without using if-statement
    return
        a_right > b_left and a_left < b_right and a_bottom > b_top and a_top <
            b_bottom
end

return checkCollision
