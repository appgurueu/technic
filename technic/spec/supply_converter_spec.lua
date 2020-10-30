dofile("spec/test_helpers.lua")
--[[
	Technic network unit tests.
	Execute busted at technic source directory.
--]]

-- Load fixtures required by tests
fixture("minetest")
fixture("minetest/player")
fixture("minetest/protection")

fixture("pipeworks")
fixture("network")

sourcefile("machines/network")

sourcefile("machines/register/cables")
sourcefile("machines/LV/cables")
sourcefile("machines/MV/cables")
sourcefile("machines/HV/cables")

sourcefile("machines/supply_converter")

function get_network_fixture(sw_pos)
	-- Build network
	local net_id = technic.create_network(sw_pos)
	assert.is_number(net_id)
	local net = technic.networks[net_id]
	assert.is_table(net)
	return net
end

describe("Supply converter", function()

	describe("building", function()

		world.layout({
			{{x=100,y=820,z=100}, "technic:hv_cable"},
			{{x=100,y=821,z=100}, "technic:switching_station"},
			{{x=101,y=820,z=100}, "technic:hv_cable"},
			{{x=101,y=821,z=100}, "technic:supply_converter"},
			{{x=102,y=820,z=100}, "technic:hv_cable"},
			-- {{x=102,y=821,z=100}, "technic:supply_converter"}, -- This machine is built
			{{x=102,y=821,z= 99}, "technic:hv_cable"}, -- This should not be added to network
			{{x=102,y=821,z=101}, "technic:hv_cable"}, -- This should not be added to network
			{{x=103,y=820,z=100}, "technic:hv_cable"},
			-- Second network for overload test
			{{x=100,y=820,z=102}, "technic:hv_cable"},
			{{x=100,y=821,z=102}, "technic:switching_station"},
			-- {{x=100,y=820,z=101}, "technic:supply_converter"}, -- This machine is built, it should overload
		})
		-- Build network
		local net = get_network_fixture({x=100,y=821,z=100})
		local net2 = get_network_fixture({x=100,y=821,z=102})
		local build_pos = {x=102,y=821,z=100}
		local build_pos2 = {x=100,y=820,z=101}

		it("does not crash", function()
			assert.equals(1, #net.PR_nodes)
			assert.equals(1, #net.RE_nodes)
			assert.equals(5, count(net.all_nodes))
			world.set_node(build_pos, {name="technic:supply_converter",param2=0})
			technic.network_node_on_placenode(build_pos, {"HV"}, "technic:supply_converter")
		end)

		it("is added to network without duplicates", function()
			assert.same(build_pos, net.all_nodes[minetest.hash_node_position(build_pos)])
			assert.equals(6, count(net.all_nodes))
			assert.equals(2, #net.PR_nodes)
			assert.equals(2, #net.RE_nodes)
			assert.is_nil(technic.is_overloaded(net.id))
			assert.is_nil(technic.is_overloaded(net2.id))
		end)

		it("does not remove connected machines from network", function()
			assert.same({x=101,y=821,z=100},net.all_nodes[minetest.hash_node_position({x=101,y=821,z=100})])
		end)

		it("does not remove networks", function()
			assert.is_hashed(technic.networks[net.id])
			assert.is_hashed(technic.networks[net2.id])
		end)

		it("does not add cables to network", function()
			assert.is_nil(net.all_nodes[minetest.hash_node_position({x=102,y=821,z=99})])
			assert.is_nil(net.all_nodes[minetest.hash_node_position({x=102,y=821,z=101})])
		end)

		it("overloads network", function()
			pending("overload does not work with supply converter")
			world.set_node(build_pos2, {name="technic:supply_converter",param2=0})
			technic.network_node_on_placenode(build_pos2, {"HV"}, "technic:supply_converter")
			assert.not_nil(technic.is_overloaded(net.id))
			assert.not_nil(technic.is_overloaded(net2.id))
		end)

	end)

	describe("digging", function()

		world.layout({
			{{x=100,y=990,z=100}, "technic:hv_cable"},
			{{x=100,y=991,z=100}, "technic:switching_station"},
			{{x=101,y=990,z=100}, "technic:hv_cable"},
			{{x=102,y=990,z=100}, "technic:hv_cable"},
			{{x=102,y=991,z=100}, "technic:supply_converter"}, -- This machine is digged
		})
		-- Build network
		local net = get_network_fixture({x=100,y=991,z=100})
		local build_pos = {x=102,y=991,z=100}

		it("does not crash", function()
			assert.equals(1, #net.PR_nodes)
			assert.equals(1, #net.RE_nodes)
			assert.equals(4, count(net.all_nodes))
			world.set_node(build_pos, {name="air",param2=0})
			technic.network_node_on_dignode(build_pos, {"HV"}, "technic:supply_converter")
		end)

		it("is removed from network", function()
			assert.is_nil(technic.pos2network(build_pos))
			assert.is_nil(technic.cables[minetest.hash_node_position(build_pos)])
			assert.is_nil(net.all_nodes[minetest.hash_node_position(build_pos)])
		end)

		it("does not remove other nodes from network", function()
			assert.equals(3, count(net.all_nodes))
		end)

		it("does not remove network", function()
			assert.is_hashed(technic.networks[net.id])
		end)

	end)

end)
