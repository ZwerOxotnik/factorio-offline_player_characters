local M = {}


--#region Global data
local __mod_data
--#endregion


--#region Constants
--#endregion


remote.add_interface("offline_player_characters", {
	getSource = function()
		local mod_name = script.mod_name
		rcon.print(mod_name) -- Returns "level" if it's a scenario, otherwise "offline_player_characters" as a mod.
		return mod_name
	end
})


function M.on_player_joined_game(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	local player_data = __mod_data.offline_player_characters_data[player_index]
	if player_data == nil then return end

	local character = player_data[1]
	if character.valid then
		player.set_controller({
			type = defines.controllers.character,
			character = character
		})
		player_data[2].destroy()
		__mod_data.offline_player_characters_data[player_index] = nil
		return
	end

	surface = game.get_surface(player_data[3]) or game.get_surface() -- TODO: improve

	local character_name
	if prototypes.entity[player_data[5]] then
		character_name = player_data[5]
	else
		character_name = next(prototypes.get_entity_filtered({{filter = "type", type = "character"}}))
	end

	local new_character = surface.create_entity({
		name = character_name, position = player_data[4],
		force = player.force,  move_stuck_players = true
	})

	if new_character and new_character.valid then
		player.set_controller({
			type = defines.controllers.character, character = new_character,
		})
		if new_character.valid then
			new_character.die()
		end
	end
	__mod_data.offline_player_characters_data[player_index] = nil
end


local __draw_nickname_param = {
	target = {entity = nil, offset = {0,-3}},
	only_in_alt_mode = false,
	color = {0.3, 0.3, 0.3},
	alignment = "center",
	visible = true,
	surface = nil,
	scale = 4,
	text = "",
}
function M.on_pre_player_left_game(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end
	local character = player.character
	if not (character and character.valid) then return end

	local surface = character.surface
	__draw_nickname_param.surface = surface
	__draw_nickname_param.text    = player.name
	__draw_nickname_param.target.entity = character
	local rendered = rendering.draw_text(__draw_nickname_param)
	__mod_data.offline_player_characters_data[player_index] = {
		character, rendered, surface.name, character.position, character.name
	}
	player.set_controller({
		type = defines.controllers.god
	})
end

--#region Pre-game stage

local function link_data()
	__mod_data = storage.offline_player_characters_mod_data
end

local function update_global_data()
	storage.offline_player_characters_mod_data = storage.offline_player_characters_mod_data or {}
	__mod_data = storage.offline_player_characters_mod_data

	__mod_data.offline_player_characters_data = __mod_data.offline_player_characters_data or {}

	link_data()
end


M.on_init = update_global_data
M.on_configuration_changed = update_global_data
M.on_load = link_data


--#endregion

M.events = {
	[defines.events.on_player_joined_game]   = M.on_player_joined_game,
	[defines.events.on_pre_player_left_game] = M.on_pre_player_left_game
}


return M
