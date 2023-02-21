local acidity = require("acidity")


local map = acidity.new_map(10,64)

local orig_line = love.graphics.line
function love.graphics.line(x,y,x_,y_)
    orig_line(x+20,y+20,x_+20,y_+20)
end
local orig_points = love.graphics.points
function love.graphics.points(x,y)
    orig_points(x+20,y+20)
end

function love.load()
    love.graphics.setLineWidth(2)
end

function love.draw()
    for x=1,450 do
        for y=1,150 do
            local c = map:get_block(x,y)
            love.graphics.setColor(c,c,c)
            love.graphics.points(x,y)
        end
    end

    love.graphics.setColor(1,0,0)
    for x,ls in pairs(map.vector_grid) do
        x = x - 1
        for y,vec in pairs(ls) do
            y = y - 1
            local nx = x * 64
            local ny = y * 64

            local enx = x*64 + vec.x*15
            local eny = y*64 + vec.y*15

            love.graphics.line(nx,ny,enx,eny)
        end
    end
end