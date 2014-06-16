-- intersecting 0.1.1 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- Parameters

local TFIS = 0.02 -- fissure and tunnel width

-- 3D noise for fissure a

local np_weba = {
	offset = 0,
	scale = 1,
	spread = {x=192, y=192, z=192},
	seed = 5900033,
	octaves = 3,
	persist = 0.5
}

-- 3D noise for fissure b

local np_webb = {
	offset = 0,
	scale = 1,
	spread = {x=191, y=191, z=191},
	seed = 33,
	octaves = 3,
	persist = 0.5
}

-- 3D noise for fissure c

local np_webc = {
	offset = 0,
	scale = 1,
	spread = {x=190, y=190, z=190},
	seed = -18000001,
	octaves = 3,
	persist = 0.5
}

-- Stuff

intersecting = {}

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y > 48 then
		return
	end

	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	print ("[interasecting] chunk minp ("..x0.." "..y0.." "..z0..")")
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_air = minetest.get_content_id("air")
	local c_water = minetest.get_content_id("default:water_source")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxyz = {x=x0, y=y0, z=z0}
	
	local nvals_weba = minetest.get_perlin_map(np_weba, chulens):get3dMap_flat(minposxyz)
	local nvals_webb = minetest.get_perlin_map(np_webb, chulens):get3dMap_flat(minposxyz)
	local nvals_webc = minetest.get_perlin_map(np_webc, chulens):get3dMap_flat(minposxyz)
	
	local nixyz = 1
	for z = z0, z1 do -- for each xy plane progressing northwards
		for y = y0, y1 do -- for each x row progressing upwards
			local vi = area:index(x0, y, z)
			for x = x0, x1 do -- for each node do
				local nodid = data[vi]
				if nodid ~= c_water and nodid ~= c_air then
					local weba = math.abs(nvals_weba[nixyz]) < TFIS
					local webb = math.abs(nvals_webb[nixyz]) < TFIS
					local webc = math.abs(nvals_webc[nixyz]) < TFIS
					if (weba and webb) or (weba and webc) then
						data[vi] = c_air
					end
				end
				nixyz = nixyz + 1
				vi = vi + 1
			end
		end
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[intersecting] "..chugent.." ms")
end)
