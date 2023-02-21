local acidity = {}
local map_methods = {}

local function normalize(a)
    local lenght = math.sqrt(a.x^2 + a.y^2)

    a.x = a.x / lenght
    a.y = a.y / lenght

    return a
end

local edge_1 = {x=0,y=0}
local edge_2 = {x=64,y=0}
local edge_3 = {x=0,y=64}
local edge_4 = {x=64,y=64}

local function sub(a,b)
    return {
        x = a.x - b.x,
        y = a.y - b.y
    }
end

local function dot(a,b)
    return a.x * b.x + a.y * b.y
end

local function fade_easing_curve(t)
    return 6*t^5-15*t^4+10*t^3
end

local vector_directions     = {0,45,90,135,180,225,270}
local vector_directions_cnt = #vector_directions
local generated_vectors     = {}
for i=1,vector_directions_cnt do
    local angle = vector_directions[i]
    generated_vectors[i] = normalize{
        x=math.cos(angle),
        y=math.sin(angle)
    }
end

local function createNDarray(n, tbl)
    tbl = tbl or {}
    if n == 0 then return tbl end
    setmetatable(tbl, {__index = function(t, k)
        local new = createNDarray(n-1)
        t[k] = new
        return new
    end})
    return tbl
end

local function make_chunk_seed(map_seed,x,y)
    local seed = x

    seed = seed + bit.lshift(y,16)
    seed = seed + bit.rshift(y,16)

    return seed^map_seed
end

local function init_map_vector(map,x,y)
    local seed = make_chunk_seed(map.seed,x,y)

    math.randomseed(seed)
    local direction_vector = generated_vectors[
        math.random(1,vector_directions_cnt)
    ]

    return direction_vector
end

local function init_map_chunk(map,x,y)
    local chunk_size = map.chunk_size
    local chunk_x = math.ceil(x/chunk_size)
    local chunk_y = math.ceil(y/chunk_size)

    local vector_grid = map.vector_grid

    vector_grid[chunk_x]  [chunk_y]   = init_map_vector(map,chunk_x,  chunk_y)
    vector_grid[chunk_x+1][chunk_y]   = init_map_vector(map,chunk_x+1,chunk_y)
    vector_grid[chunk_x]  [chunk_y+1] = init_map_vector(map,chunk_x,  chunk_y+1)
    vector_grid[chunk_x+1][chunk_y+1] = init_map_vector(map,chunk_x+1,chunk_y+1)
end

local function get_chunk_vectors(map,x,y)
    local chunk_size = map.chunk_size
    local chunk_x = math.ceil(x/chunk_size)
    local chunk_y = math.ceil(y/chunk_size)

    local vector_grid = map.vector_grid

    return vector_grid[chunk_x][chunk_y],
        vector_grid[chunk_x+1] [chunk_y],
        vector_grid[chunk_x]   [chunk_y+1],
        vector_grid[chunk_x+1] [chunk_y+1]
end

local function bilinear_lerp(a,b,c,d,t1,t2)
    local ab = (1-t1)*a + t1*b
    local cd = (1-t1)*c + t1*d

    return (1-t2)*ab + t2*cd
end

function map_methods:get_block(x,y)
    init_map_chunk(self,x,y)
    local a,b,c,d = get_chunk_vectors(self,x,y)

    local chunk_point = {
        x = (x-1)%self.chunk_size+1,
        y = (y-1)%self.chunk_size+1
    }

    local t1 = fade_easing_curve(chunk_point.x/self.chunk_size)
    local t2 = fade_easing_curve(chunk_point.y/self.chunk_size)

    local a_dir = sub(chunk_point,edge_1)
    local b_dir = sub(chunk_point,edge_2)
    local c_dir = sub(chunk_point,edge_3)
    local d_dir = sub(chunk_point,edge_4)

    local dot1 = dot(a,a_dir)
    local dot2 = dot(b,b_dir)
    local dot3 = dot(c,c_dir)
    local dot4 = dot(d,d_dir)

    return bilinear_lerp(dot1,dot2,dot3,dot4,t1,t2)/16
end

function acidity.new_map(seed,chunk_size)
    return setmetatable({
        chunk_size=chunk_size,
        seed=seed,
        vector_grid=createNDarray(1)
    },{__index=map_methods})
end

return acidity