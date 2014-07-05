-- intersecting 0.2.2 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- stable sand, drops default
-- luxore in stone, above stone, craftable to lights

-- TODO
-- integrate caves as cava = math.abs(n_weba) > CAVT
-- include lava, to replace v6 cavegen

-- Parameters

local TFIS = 0.02 -- Fissure and tunnel width
local LUX = true -- Enable luxore
local LUXCHA = 1 / 8 ^ 3 -- Luxore chance per stone node.

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

-- 3D noise for tunnel/fissure combinations

local np_biome = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048},
	seed = -181,
	octaves = 1,
	persist = 0
}

-- Stuff

intersecting = {}

-- Nodes

minetest.register_node("intersecting:sand", {
	description = "Stable sand",
	tiles = {"default_sand.png"},
	is_ground_content = false,
	groups = {crumbly=2, sand=1},
	drop = "default:sand",
	sounds = default.node_sound_sand_defaults(),
})

minetest.register_node("intersecting:luxoff", {
	description = "Dark Lux Ore",
	tiles = {"intersecting_luxore.png"},
	light_source = 14,
	groups = {cracky=3},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("intersecting:luxore", {
	description = "Lux Ore",
	tiles = {"intersecting_luxore.png"},
	light_source = 14,
	groups = {cracky=3},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("intersecting:light", {
	description = "Light",
	tiles = {"intersecting_light.png"},
	light_source = 14,
	groups = {cracky=3,oddly_breakable_by_hand=3},
	sounds = default.node_sound_glass_defaults(),
})

-- Crafting.

minetest.register_craft({
    output = "intersecting:light 8",
    recipe = {
        {"default:glass", "default:glass", "default:glass"},
        {"default:glass", "intersecting:luxore", "default:glass"},
        {"default:glass", "default:glass", "default:glass"},
    },
})

minetest.register_craft({
    output = "intersecting:light 8",
    recipe = {
        {"default:obsidian_glass", "default:obsidian_glass", "default:obsidian_glass"},
        {"default:obsidian_glass", "intersecting:luxore", "default:obsidian_glass"},
        {"default:obsidian_glass", "default:obsidian_glass", "default:obsidian_glass"},
    },
})

-- ABM spread luxore light

minetest.register_abm({
	nodenames = {"intersecting:luxoff"},
	interval = 7,
	chance = 1,
	action = function(pos, node)
		minetest.remove_node(pos)
		minetest.place_node(pos, {name="intersecting:luxore"})
	end,
})

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
	
	print ("[intersecting] chunk minp ("..x0.." "..y0.." "..z0..")")
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_air = minetest.get_content_id("air")
	local c_water = minetest.get_content_id("default:water_source")
	local c_dirt = minetest.get_content_id("default:dirt")
	local c_grass = minetest.get_content_id("default:dirt_with_grass")
	local c_tree = minetest.get_content_id("default:tree")
	local c_jtree = minetest.get_content_id("default:jungletree")
	local c_stone = minetest.get_content_id("default:stone")
	local c_desertstone = minetest.get_content_id("default:desert_stone")
	
	local c_sand = minetest.get_content_id("intersecting:sand")
	local c_luxore = minetest.get_content_id("intersecting:luxoff")

	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxyz = {x=x0, y=y0, z=z0}
	
	local nvals_weba = minetest.get_perlin_map(np_weba, chulens):get3dMap_flat(minposxyz)
	local nvals_webb = minetest.get_perlin_map(np_webb, chulens):get3dMap_flat(minposxyz)
	local nvals_webc = minetest.get_perlin_map(np_webc, chulens):get3dMap_flat(minposxyz)
	local nvals_biome = minetest.get_perlin_map(np_biome, chulens):get3dMap_flat(minposxyz)
	
	local cavbel = {}
	local stobel = {}
	local nixyz = 1
	for z = z0, z1 do -- for each xy plane progressing northwards
		for y = y0, y1 do -- for each x row progressing upwards
			local vi = area:index(x0, y, z)
			local via = area:index(x0, y+1, z)
			local vin = area:index(x0, y, z+1)
			local vis = area:index(x0, y, z-1)
			local vie = vi + 1
			local viw = vi - 1
			for x = x0, x1 do -- for each node do
				local ti = x - x0 + 1
				local nodid = data[vi]
				local nodida = data[via]
				local nodide = data[vie]
				local nodidw = data[viw]
				local nodidn = data[vin]
				local nodids = data[vis]
				local watadj = nodida == c_water or nodidw == c_water or nodide == c_water or nodidn == c_water or nodids == c_water
				if nodid ~= c_air and nodid ~= c_water and not watadj
				and not ((nodid == c_sand or nodid == c_dirt or nodid == c_grass) and y <= 2) then
					local weba = math.abs(nvals_weba[nixyz]) < TFIS
					local webb = math.abs(nvals_webb[nixyz]) < TFIS
					local webc = math.abs(nvals_webc[nixyz]) < TFIS
					local n_biome = nvals_biome[nixyz]
					local void
					if n_biome < -0.65 then -- 2 tun ac ab
						void = (weba and webc) or (weba and webb) 
					elseif n_biome < -0.4 then -- 2 tun bc ab
						void = (webb and webc) or (weba and webb)
					elseif n_biome < -0.15 then -- 2 tun bc ac
						void = (webb and webc) or (weba and webc)
					elseif n_biome < -0.05 then -- 1 fis 1 tun
						void = webb or (weba and webc)
					elseif n_biome < 0.05 then -- 2 fis
						void = weba or webb
					elseif n_biome < 0.15 then -- 1 fis 1 tun
						void = weba or (webb and webc)
					elseif n_biome < 0.4 then -- 2 tun 
						void = (weba and webc) or (webb and webc)
					elseif n_biome < 0.65 then -- 2 tun 
						void = (weba and webc) or (webb and webc)
					else -- 2 tun bc ac
						void = (webb and webc) or (weba and webc)
					end
					if void then
						data[vi] = c_air
						cavbel[ti] = 1
						stobel[ti] = 0
						if nodid == c_tree or nodid == c_jtree then
							for j = -12, 12 do
								local vit = area:index(x, y+j, z)
								if data[vit] == c_tree or data[vit] == c_jtree then
									data[vit] = c_air
								end
							end
						end
					else
						cavbel[ti] = 0
						if LUX and nodid == c_stone or nodid == c_desertstone then
							if math.random() < LUXCHA and stobel[ti] == 1 and y > y0 then
								data[vi] = c_luxore
							end
							stobel[ti] = 1
						end
					end
				else
					if (nodid == c_water or watadj) and cavbel[ti] == 1 then
						for j = -1, -16, -1 do
							local vip = area:index(x, y+j, z)
							if data[vip] == c_air then
								data[vip] = c_sand
							end
						end
					end
					cavbel[ti] = 0
					stobel[ti] = 0
				end
				nixyz = nixyz + 1
				vi = vi + 1
				via = via + 1
				vin = vin + 1
				vis = vis + 1
				vie = vie + 1
				viw = viw + 1
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
