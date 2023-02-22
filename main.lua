local acidity = require("acidity")

function love.load()
    love.graphics.setLineWidth(2)
end

function love.draw()
    local map = acidity.noise_map_complex(1000001,50,1,2,0.5)
    local w,h = love.graphics.getDimensions()

    local min  =  math.huge
    local max  = -math.huge

    for x=1,w do
        for y=1,h do
            local c = map:get_point(x,y)
            max = math.max(max,c)
            min = math.min(min,c)
            love.graphics.setColor(c,c,c)
            love.graphics.points(x,y)
        end
    end

    --error(("%f:%f"):format(max,min))

    --[[love.graphics.setColor(1,0,0)
    for x,ls in pairs(map.vector_grid) do
        x = x - 1
        for y,vec in pairs(ls) do
            y = y - 1
            local nx = x * 32
            local ny = y * 32

            local enx = x*32 + vec.x*15
            local eny = y*32 + vec.y*15

            love.graphics.line(nx,ny,enx,eny)
        end
    end]]
end