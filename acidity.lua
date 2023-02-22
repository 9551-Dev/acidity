local acidity = {}
local raw_map_methods = {}

-- objects
local I_map_interfacable = {}
acidity.noise_map_simple   = {}
acidity.noise_map_complex  = {}

local RANDOM,RANDOMSEED,LSHIFT,RSHIFT,CEIL = math.random,math.randomseed,bit32 and bit32.lshift or bit.lshift,bit32 and bit32.rshift or bit.rshift,math.ceil

local default_edge_1 = {x=0,y=0}
local default_edge_2 = {x=1,y=0}
local default_edge_3 = {x=0,y=1}
local default_edge_4 = {x=1,y=1}

local function default_easing_curve(t)
    return 6*t^5-15*t^4+10*t^3
end

local function default_output_processor(n)
    return (n+1)/2
end

local function offset_direction(x,y,b,chunk_size)
    return  (x - b.x*chunk_size)/chunk_size,
            (y - b.y*chunk_size)/chunk_size
end

local function dot(a,x,y)
    return a.x * x + a.y * y
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

local function cantor_pair(a,b)
    local hash_a = (a >= 0 and a*2 or a*-2-1)
    local hash_b = (b >= 0 and b*2 or b*-2-1)
    
    local hash_c = (hash_a >= hash_b and hash_a^2 + hash_a + hash_b or hash_a + hash_b^2)/2

    return (a < 0 and b < 0 or a >= 0 and b >= 0) and hash_c or -hash_c-1
end

local function calculate_vector_seed(map_seed,x,y)
    return cantor_pair(map_seed,cantor_pair(x,y))
end

local function generate_map_vector(map,x,y)

    local map_vectors = map.vector

    local seed = calculate_vector_seed(map.seed,x,y)

    RANDOMSEED(seed)

    local direction_vector = map_vectors.directions[
        RANDOM(1,map_vectors.ndirections)
    ]

    return direction_vector
end

local function init_map_chunk(map,x,y)
    local chunk_size = map.chunk_size
    local chunk_x = CEIL(x/chunk_size)
    local chunk_y = CEIL(y/chunk_size)

    local vector_grid = map.vector_grid

    vector_grid[chunk_x]  [chunk_y]   = generate_map_vector(map,chunk_x,  chunk_y)
    vector_grid[chunk_x+1][chunk_y]   = generate_map_vector(map,chunk_x+1,chunk_y)
    vector_grid[chunk_x]  [chunk_y+1] = generate_map_vector(map,chunk_x,  chunk_y+1)
    vector_grid[chunk_x+1][chunk_y+1] = generate_map_vector(map,chunk_x+1,chunk_y+1)
end

local function get_chunk_vectors(map,x,y)
    local chunk_size = map.chunk_size
    local chunk_x = CEIL(x/chunk_size)
    local chunk_y = CEIL(y/chunk_size)

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

function raw_map_methods:get_point(x,y)
    init_map_chunk(self,x,y)

    local a,b,c,d = get_chunk_vectors(self,x,y)

    local chunk_size = self.chunk_size

    local chunk_relative_x = (x-1)%chunk_size+1
    local chunk_relative_y = (y-1)%chunk_size+1

    local easing_curve = self.fading_function
    local edges        = self.edges

    local t1 = easing_curve(chunk_relative_x/chunk_size)
    local t2 = easing_curve(chunk_relative_y/chunk_size)

    local direction_a_x,direction_a_y = offset_direction(chunk_relative_x,chunk_relative_y,edges[1],chunk_size)
    local direction_b_x,direction_b_y = offset_direction(chunk_relative_x,chunk_relative_y,edges[2],chunk_size)
    local direction_c_x,direction_c_y = offset_direction(chunk_relative_x,chunk_relative_y,edges[3],chunk_size)
    local direction_d_x,direction_d_y = offset_direction(chunk_relative_x,chunk_relative_y,edges[4],chunk_size)

    local dot1 = dot(a,direction_a_x,direction_a_y)
    local dot2 = dot(b,direction_b_x,direction_b_y)
    local dot3 = dot(c,direction_c_x,direction_c_y)
    local dot4 = dot(d,direction_d_x,direction_d_y)


    return self.output_processor(bilinear_lerp(dot1,dot2,dot3,dot4,t1,t2))
end

function acidity.create_map_raw(seed,chunk_size,vector_grid,edges,direction_types,fading_function,output_processor)
    return setmetatable({
        chunk_size       = chunk_size,
        seed             = seed,
        vector_grid      = vector_grid,
        edges            = edges,
        vector           = direction_types,
        fading_function  = fading_function,
        output_processor = output_processor

    },{__index=raw_map_methods})
end

-- constructors
setmetatable(I_map_interfacable,{__call=function(methods,interface_parent)
    setmetatable(getmetatable(interface_parent).__index,{__index=methods})
    return interface_parent
end,__tostring=function() return "CLASS-IMapInterfacable" end})

setmetatable(acidity.noise_map_simple,{__call=function(methods,seed,frequency,generate_vector_directions,custom_edges,fade,output)
    local generated_vectors = {}

    local directions = generate_vector_directions or 8

    local n = 0
    for dir=0,math.pi*2,(math.pi*2)/directions do
        n = n + 1
        generated_vectors[n] = {
            x=math.cos(dir),
            y=math.sin(dir)
        }
    end

    local self = {raw=acidity.create_map_raw(
        seed,frequency,createNDarray(1),
        custom_edges or {
            {x=default_edge_1.x,y=default_edge_1.y},
            {x=default_edge_2.x,y=default_edge_2.y},
            {x=default_edge_3.x,y=default_edge_3.y},
            {x=default_edge_4.x,y=default_edge_4.y}
        },
        {
            ndirections = directions,
            directions  = generated_vectors
        },fade or default_easing_curve,output or default_output_processor
    )}

    return I_map_interfacable(setmetatable(self,{__index=methods,__tostring=function() return "Object-noise_map_simple" end}))
end,__tostring=function() return "CLASS-noise_map_simple" end})

setmetatable(acidity.noise_map_complex,{__call=function(methods,seed,frequency,octaves,lacunarity,persistance,generate_vector_directions,custom_edges,fade,output)
    local self = {
        octaves     = octaves,
        lacunarity  = lacunarity,
        persistance = persistance
    }

    local generated_vectors = {}

    local directions = generate_vector_directions or 8

    local n = 0
    for dir=0,math.pi*2,(math.pi*2)/directions do
        n = n + 1
        generated_vectors[n] = {
            x=math.cos(dir),
            y=math.sin(dir)
        }
    end

    local edges = custom_edges or {
        {x=default_edge_1.x,y=default_edge_1.y},
        {x=default_edge_2.x,y=default_edge_2.y},
        {x=default_edge_3.x,y=default_edge_3.y},
        {x=default_edge_4.x,y=default_edge_4.y}
    }

    local vector_directions = {
        ndirections = directions,
        directions  = generated_vectors
    }

    local fade_processor   = fade   or default_easing_curve
    local output_processor = output or default_output_processor

    local function generate_octaves()
        for i=1,#self do self[i] = nil end
        for i=1,octaves do
            local octave_id = i-1
            local octave_amplitude =      persistance            ^ octave_id
            local octave_frequency = CEIL(frequency/(lacunarity  ^ octave_id))

            self[i] = {
                raw = acidity.create_map_raw(
                    seed,octave_frequency,createNDarray(1),edges,vector_directions,fade_processor,output_processor
                ),
                frequency = octave_frequency,
                amplitude = octave_amplitude
            }
        end
    end

    generate_octaves()

    self.generate_octaves = generate_octaves

    return setmetatable(self,{__index=methods,__tostring=function() return "Object-noise_map_complex" end})
end,__tostring=function() return "CLASS-noise_map_complex" end})

function acidity.noise_map_complex:get_point(x,y)
    local total = 0

    local octaves = self.octaves

    local total_amplitude = 0

    for i=1,octaves do
        local octave = self[i]

        local amplitude = octave.amplitude

        total = total + (octave.raw:get_point(x,y) * amplitude)

        total_amplitude = total_amplitude + amplitude
    end

    return total/total_amplitude
end

function acidity.noise_map_simple:get_point(x,y)
    return self.raw:get_point(x,y)
end

return acidity