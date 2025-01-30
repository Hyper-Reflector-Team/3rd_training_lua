-- @module character_select
-- this is run when the player is on the character select screen allowing for various options, like selecting gill.

local character_select_coroutine = nil

-- 0 is out
-- 1 is waiting for input release for p1
-- 2 is selecting p1
-- 3 is waiting for input release for p2
-- 4 is selecting p2
local character_select_sequence_state = 0

local function start_character_select_sequence()
  savestate.load(savestate.create("data/" .. rom_name .. "/savestates/character_select.fs"))
  character_select_sequence_state = 1
end

local function coroutine_select_gill(input)
  local player_id = 0

  local p1_character_select_state = memory.readbyte(adresses.players[1].character_select_state)
  local p2_character_select_state = memory.readbyte(adresses.players[2].character_select_state)

  if p1_character_select_state > 2 and p2_character_select_state > 2 then
    return
  end

  if p1_character_select_state <= 2 then
    player_id = 1
  else
    player_id = 2
  end

  memory.writebyte(adresses.players[player_id].character_select_col, 3)
  memory.writebyte(adresses.players[player_id].character_select_row, 1)

  make_input_empty(input)
  input[player_objects[player_id].prefix .. " Weak Punch"] = true
end

local function select_gill()
  character_select_coroutine = coroutine.create(coroutine_select_gill)
end

local function coroutine_wait_x_frames(frame_count)
  local start_frame = frame_number
  while frame_number < start_frame + frame_count do
    coroutine.yield()
  end
end

local function coroutine_select_shingouki(input)
  local player_id = 0

  local p1_character_select_state = memory.readbyte(adresses.players[1].character_select_state)
  local p2_character_select_state = memory.readbyte(adresses.players[2].character_select_state)

  if p1_character_select_state > 2 and p2_character_select_state > 2 then
    return
  end

  if p1_character_select_state <= 2 then
    player_id = 1
  else
    player_id = 2
  end

  memory.writebyte(adresses.players[player_id].character_select_col, 0)
  memory.writebyte(adresses.players[player_id].character_select_row, 6)

  make_input_empty(input)
  input[player_objects[player_id].prefix .. " Weak Punch"] = true

  coroutine_wait_x_frames(20)

  memory.writebyte(adresses.players[player_id].character_select_id, 0x0F)
end

local function select_shingouki()
  character_select_coroutine = coroutine.create(coroutine_select_shingouki)
end

local function update_character_select(input, do_fast_forward)
  if not character_select_sequence_state == 0 then
    return
  end

  -- Infinite select time
  --memory.writebyte(adresses.global.character_select_timer, 0x30)

  if (character_select_coroutine ~= nil) then
    make_input_empty(input)
    local _status = coroutine.status(character_select_coroutine)
    if _status == "suspended" then
      local _r, _error = coroutine.resume(character_select_coroutine, input)
      if not _r then
        print(_error)
      end
    elseif _status == "dead" then
      character_select_coroutine = nil
    end
    return
  end

  local p1_character_select_state = memory.readbyte(adresses.players[1].character_select_state)
  local p2_character_select_state = memory.readbyte(adresses.players[2].character_select_state)

  --print(string.format("%d, %d, %d", character_select_sequence_state, p1_character_select_state, p2_character_select_state))

  if p1_character_select_state > 4 and not is_in_match then
    if character_select_sequence_state == 2 then
      character_select_sequence_state = 3
    end
    swap_inputs(input)
  end

  -- wait for all inputs to be released
  if character_select_sequence_state == 1 or character_select_sequence_state == 3 then
    for _key, _state in pairs(input) do
      if _state == true then
        makeinput_empty(input)
        return
      end
    end
    character_select_sequence_state = character_select_sequence_state + 1
  end

  if has_match_just_started then
    emu.speedmode("normal")
    character_select_sequence_state = 0
  elseif not is_in_match then
    if do_fast_forward and p1_character_select_state > 4 and p2_character_select_state > 4 then
      emu.speedmode("turbo")
    elseif character_select_sequence_state == 0 and (p1_character_select_state < 5 or p2_character_select_state < 5) then
      emu.speedmode("normal")
      character_select_sequence_state = 1
    end
  else
    character_select_sequence_state = 0
  end
end

local function draw_character_select()
  local p1_character_select_state = memory.readbyte(adresses.players[1].character_select_state)
  local p2_character_select_state = memory.readbyte(adresses.players[2].character_select_state)

  if p1_character_select_state <= 2 or p2_character_select_state <= 2 then
    gui.text(10, 10, "Alt+1 -> Return To Character Select Screen", text_default_color, text_default_border_color)
    if rom_name == "sfiii3nr1" then
      gui.text(10, 20, "Alt+2 -> Gill", text_default_color, text_default_border_color)
      gui.text(10, 30, "Alt+3 -> Shin Gouki", text_default_color, text_default_border_color)
    end
  end
end

return {
  character_select_sequence_state = character_select_sequence_state,
  start_character_select_sequence = start_character_select_sequence,
  select_gill = select_gill,
  select_shingouki = select_shingouki,
  update_character_select = update_character_select,
  draw_character_select = draw_character_select,
}
