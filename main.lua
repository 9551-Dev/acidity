local acidity = require("acidity")

local map = acidity.noise_map_simple(1,20)

function map.raw.output_processor(t)
    return math.abs(t*2)
end

function love.load()
    love.graphics.setLineWidth(2)
    love.graphics.setPointSize(2)
end

local st = love.timer.getTime()

function love.draw()

    map:rebuild()

    local w,h = love.graphics.getDimensions()

    local t = ((love.timer.getTime()-st)/5+0.5)^2

    for x=1,w/2 do
        for y=1,h/2 do
            local c = map:get_point(x,y/t)

            c = math.min(c,1)
            c = math.max(c,-1)

            love.graphics.setColor(c,c,c)
            love.graphics.points((x-1)*2,(y-1)*2)
        end
    end
end