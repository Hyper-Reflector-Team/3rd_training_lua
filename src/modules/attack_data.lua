-- @module attack_data - util
-- this is used for displaying information such as damage, stun and combo count on screen.

local util_draw = require("src/utils/draw")

local attack_data = {}

local function attack_data_update(attacker, defender)
  attack_data.player_id = attacker.id

  if attacker.combo == nil then
    attacker.combo = 0
  end

  if attacker.combo == 0 then
    attack_data.last_hit_combo = 0
  end

  if attacker.damage_of_next_hit ~= 0 then
    attack_data.damage = attacker.damage_of_next_hit
    attack_data.stun = attacker.stun_of_next_hit

    if attacker.combo > attack_data.last_hit_combo and attack_data.last_hit_combo ~= 0 then
      attack_data.total_damage = attack_data.total_damage + attacker.damage_of_next_hit
      attack_data.total_stun = attack_data.total_stun + attacker.stun_of_next_hit
    elseif attacker.combo == attack_data.last_hit_combo then
      -- Repeated hit, skip
    else
      attack_data.total_damage = attacker.damage_of_next_hit
      attack_data.total_stun = attacker.stun_of_next_hit
    end

    attack_data.last_hit_combo = attacker.combo
  end

  if attacker.combo ~= 0 then
    attack_data.combo = attacker.combo
  end
  if attacker.combo > attack_data.max_combo then
    attack_data.max_combo = attacker.combo
  end
end

local function attack_data_display()
  local text_width1 = util_draw.get_text_width("damage: ")
  local text_width2 = util_draw.get_text_width("stun: ")
  local text_width3 = util_draw.get_text_width("combo: ")
  local text_width4 = util_draw.get_text_width("total damage: ")
  local text_width5 = util_draw.get_text_width("total stun: ")
  local text_width6 = util_draw.get_text_width("max combo: ")

  local x1 = 0
  local x2 = 0
  local x3 = 0
  local x4 = 0
  local x5 = 0
  local x6 = 0
  local y = 49

  local x_spacing = 80

  if attack_data.player_id == 1 then
    local _base = util_draw.screen_width - 138
    x1 = _base - text_width1
    x2 = _base - text_width2
    x3 = _base - text_width3
    local _base2 = _base + x_spacing
    x4 = _base2 - text_width4
    x5 = _base2 - text_width5
    x6 = _base2 - text_width6
  elseif attack_data.player_id == 2 then
    local _base = 82
    x1 = _base - text_width1
    x2 = _base - text_width2
    x3 = _base - text_width3
    local _base2 = _base + x_spacing
    x4 = _base2 - text_width4
    x5 = _base2 - text_width5
    x6 = _base2 - text_width6
  end

  gui.text(x1, y, string.format("damage: "))
  gui.text(x1 + text_width1, y, string.format("%d", attack_data.damage))

  gui.text(x2, y + 10, string.format("stun: "))
  gui.text(x2 + text_width2, y + 10, string.format("%d", attack_data.stun))

  gui.text(x3, y + 20, string.format("combo: "))
  gui.text(x3 + text_width3, y + 20, string.format("%d", attack_data.combo))

  gui.text(x4, y, string.format("total damage: "))
  gui.text(x4 + text_width4, y, string.format("%d", attack_data.total_damage))

  gui.text(x5, y + 10, string.format("total stun: "))
  gui.text(x5 + text_width5, y + 10, string.format("%d", attack_data.total_stun))

  gui.text(x6, y + 20, string.format("max combo: "))
  gui.text(x6 + text_width6, y + 20, string.format("%d", attack_data.max_combo))
end

local function attack_data_reset()
  attack_data = {
    player_id = nil,
    last_hit_combo = 0,
    damage = 0,
    stun = 0,
    combo = 0,
    total_damage = 0,
    total_stun = 0,
    max_combo = 0,
  }
end

attack_data_reset()

return {
  attack_data = attack_data,
  attack_data_update = attack_data_update,
  attack_data_display = attack_data_display,
  attack_data_reset = attack_data_reset,
}
