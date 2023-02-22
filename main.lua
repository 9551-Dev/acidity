local acidity = require("acidity")

love.cc.quantize(true)

local map = acidity.noise_map_simple(1,20)

function map.raw.output_processor(t)
    return math.abs(t*20)
end

function love.load()
    love.graphics.setLineWidth(2)
end

function love.draw()

    map.raw_config.frequency = math.ceil(os.clock())
    map:rebuild()

    local w,h = love.graphics.getDimensions()

    for x=1,w do
        for y=1,h do
            local c = map:get_point(x,y)

            c = math.min(c,1)
            c = math.max(c,-1)

            love.graphics.setColor(c,c,c)
            love.graphics.points(x,y)
        end
    end
end