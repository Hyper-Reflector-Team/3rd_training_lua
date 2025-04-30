GLOBAL_isHyperReflectorOnline = true
-- BEFORE BUILDING COPY THIS FILE TO lua/3rd_training_lua/ in order for the scripts to use the same root directories.
local third_training = require("3rd_training")
local util_draw = require("src/utils/draw");
local util_colors = require("src/utils/colors")
require("src/tools") -- TODO: refactor tools to export;
-- local command_file = "../../hyper_write_commands.txt"
local ext_command_file = "../../hyper_read_commands.txt" -- this is for sending back commands to electron.
local match_track_file = "../../hyper_track_match.txt"
local module_character_select = require("src/modules/character_select")

-- game state 
require("src/gamestate")

-- state
local game_name = ""

local match_count = 0;
local stat_file
-- match related
local match_just_ended = false
local p1_char
local p2_char
local p1_super
local p2_super
-- local wasInMatch = false

-- match state
local match_initialized = false
---- meter
local p1_previous_meter = 0; -- for some reason meter set to 70 on character select 
local p1_match_total_meter_gained = 0;
local p2_previous_meter = 0; -- for some reason meter set to 70 on character select 
local p2_match_total_meter_gained = 0;
----
---- hits
local p2_hits_landed_normals = 0
local p2_hits_landed_specials = 0
local p2_hits_landed_supers = 0
local p2_hits_landed_supers_ext = 0
local p1_hits_landed_normals = 0
local p1_hits_landed_specials = 0
local p1_hits_landed_supers = 0
local p1_hits_landed_supers_ext = 0
----
local player_1_win_count = 0;
local player_2_win_count = 0;
local player_1_total_wins = 0; -- just used for display for now.
local player_2_total_wins = 0;
local data_reset = false; -- this is used to track when we should reset data for wins
-- local frameTimer = 0;
-- local pressedStart = 0;
-- local inputs = joypad.get();
-- local previousMatchState = 9;
-- local down_inputs -- used for checking if we reset in the 0 or 9  match state

-- start=Start,Main RAM,eq,0x2867a,99,8
-- player1=P1 Win,Main RAM,gts,0x16cd6,0,8
-- player2=P2 Win,Main RAM,gts,0x16cd4,0,8
-- char1=P1 Char,Main RAM,char,0x11384,0,8
-- char2=P2 Char,Main RAM,char,0x1138b,0,8
-- char=1,Alex
-- char=2,Ryu
-- char=3,Yun
-- char=4,Dudley
-- char=5,Necro
-- char=6,Hugo
-- char=7,Ibuki
-- char=8,Elena
-- char=9,Oro
-- char=10,Yang
-- char=11,Ken
-- char=12,Sean
-- char=13,Urien
-- char=14,Akuma
-- char=16,Chun-Li
-- char=17,Makoto
-- char=18,Q
-- char=19,Twelve
-- char=20,Remy
-- wow we can character lock the menu!
-- p1
-- memory.writebyte(0x020154CF, 0x04) -- 0 to 6 -- character row
-- memory.writebyte(0x0201566B, 0x01) -- 0 to 2 -- character column
-- -- p2
-- memory.writebyte(0x020154D1, 0x06) -- 0 to 6 -- character row
-- memory.writebyte(0x0201566D, 0x01) -- 0 to 2 -- character column
-- 

-- print(match_state)
-- 6 is post last hit
-- 8 is transition from win to black screen
-- 1 is pre match freeze state
-- 2 is in fight

-- memory addresses 
-- 0x2867a == start ? maybe timer?
-- working player win count memory
-- local p1_win = memory.readdword(0x02016cd6)
-- local p2_win = memory.readdword(0x02016cd4)
-- if either are the value 65536 i believe this means the other lost a streak
-- print(p1_win)
-- local start = memory.readbyte(0x0202867a) -- doesnt work, came from the the detectors code

-- character_select_row = 0x020154D1,
-- character_select_col = 0x0201566D,
-- character_select_sa = 0x020154D5,
-- character_select_color = 0x02015684,
-- character_select_state = 0x02015545,
-- character_select_id = 0x02011388,

-- timers
-- working match timer
-- match_timer = memory.readbyte(0x02011377)
-- working char select timer
-- local char_select_timer = memory.readbyte(0x020154FB)

-- parry related

-- print(match_timer)

-- ELECTRON sends commands here, lua reads them and then then sends ifno back via text file
-- local function check_commands()
--     GLOBAL_read_stat_memory()
--     local file = io.open(command_file, "r")
--     if file then
--         local command = file:read("*l") -- Read first line
--         file:close()

--         if command == "game_name" then
--             local value = emu.romname()
--             memory.writebyte(0x02011388, 1) -- change p2 to alex
--             -- memory.writebyte(0x02011377, 1) -- immediately end round
--             memory.writeword(0x0201138B, 0x00) -- select super art 
--             -- read from the current lua file and make a return an answer to the ext_command_file maybe better to have another file for commands sent to electron.
--             local file2 = io.open(ext_command_file, "w")
--             if file2 then
--                 file2:write(value)
--                 file2:close()
--             end
--             print('The game is: ', value)
--         elseif command == "resume" then
--             local value = emu.sourcename()
--             -- read from the current lua file and make a return an answer to the ext_command_file.txt maybe better to have another file for commands sent to electron.
--             local file2 = io.open(ext_command_file, "w")
--             if file2 then
--                 file2:write(value)
--                 file2:close()
--             end
--         elseif command and string.find(command, "textinput:") then
--             game_name = string.sub(command, 11) -- cut the first 11 characters from string
--             -- read from the current lua file and make a return an answer to fbneo_commands_commands.txt maybe better to have another file for commands sent to electron.
--             local file2 = io.open(ext_command_file, "w")
--             if file2 then
--                 file2:write('we wrote to game')
--                 file2:close()
--             end
--         elseif command == "exit" then
--             os.exit()
--         end
--         -- Clear the file after each input. If you want both clients running locally to read this file, without a deletion race condition, disable the below line, but keep in mind that the commands will happen every frame.
--         io.open(command_file, "w"):close()
--     end
-- end

-- if character select state = 5 we know p2 has already been selected, so we want both of p2 and p1 to = 1 before we start a match
-- print(character_select_state)
-- print(match_state)
-- print(memory.readbyte(0x020154CF)) -- 0 to 6 -- character row
-- print(memory.readbyte(0x0201566B)) -- 0 to 2 -- character column
-- -- -- p2
-- print('p2', memory.readbyte(0x020154D1)) -- 0 to 6 -- character row
-- print(memory.readbyte(0x0201566D)) -- 0 to 2 -- character column

local function hyper_reflector_rendering()
    if GLOBAL_isHyperReflectorOnline then
        gui.text(160, 4, player_1_total_wins, util_colors.input_history.unknown1)
        gui.text(221, 4, player_2_total_wins, util_colors.input_history.unknown1)
        gui.text(2, 2, 'HYPER-REFLECTOR v030a', util_colors.gui.empty)

    end
    -- if GLOBAL_isHyperReflectorOnline then
    --     gui.text(10, 1, 'memory stuff', util_colors.gui.white, util_colors.input_history.unknown2)
    --     -- current guage int? we can use this to track how much meter the player has spent / gained
    --     gui.text(20, 8, memory.readbyte(0x020695B5), util_colors.gui.white, util_colors.input_history.unknown2)
    --     -- current meter count ie: a full number change on the ui?
    --     gui.text(10, 8, memory.readbyte(0x020286AB), util_colors.gui.white, util_colors.input_history.unknown2)
    --     -- current character p1
    --     gui.text(50, 8, memory.readbyte(0x02011387), util_colors.gui.white, util_colors.input_history.unknown2)
    --     gui.text(58, 8, memory.readbyte(0x02011388), util_colors.gui.white, util_colors.input_history.unknown2)
    --     -- super art selected
    --     gui.text(58, 20, memory.readbyte(0x0201138B), util_colors.gui.white, util_colors.input_history.unknown2)
    --     -- combo count
    --     gui.text(10, 20, memory.readbyte(0x020696C5), util_colors.gui.white, util_colors.input_history.unknown2)
    -- end

    -- gui.text(100, 20, game_name, util_colors.gui.white,
    --          util_colors.input_history.unknown2)
end

local function check_in_match()
    local character_select_state = memory.readbyte(0x02015545)
    local match_state = memory.readbyte(0x020154A7);
    -- print(match_state)
    -- 
    -- if match_state == 0 then -- this indicates the emulator was restarted in some way
    --     player_1_win_count = 0
    --     player_2_win_count = 0
    --     return
    -- end

    if character_select_state == 4 and not match_initialized and stat_file == nil then -- this is initial char select and the select state has been reset
        match_just_ended = false
        local new_p1_wins = memory.writedword(0x02016cd6, 0)
        local new_p2_wins = memory.writedword(0x02016cd4, 0)
        print(new_p1_wins, new_p2_wins)
        -- print('match was reset correctly')
        io.open(match_track_file, "w"):close()
        stat_file = io.open(match_track_file, "a")
        if stat_file then
            stat_file:write('\n -i-game-match', match_count) -- is not registered until the end of the set
        end
        print('resetting data')
        local p1_wins = memory.readdword(0x02016cd6)
        print(p1_wins)
        local p2_wins = memory.readdword(0x02016cd4)
        if (p1_wins < 100) then -- rolls over at 99 but if not its like 65535 or something
            player_1_win_count = p1_wins
        else
            player_1_win_count = 0
        end
        if (p2_wins < 100) then -- rolls over at 99 but if not its like 65535 or something
            player_2_win_count = p2_wins
        else
            player_2_win_count = 0
        end
        p1_previous_meter = 0
        p2_previous_meter = 0
        match_initialized = true
        return
    end

    if match_state == 2 then
        p1_char = memory.readbyte(0x02011387)
        p2_char = memory.readbyte(0x02011388)
        p1_super = memory.readbyte(0x020154D3)
        p2_super = memory.readbyte(0x020154D5)
        -- print(p1_char, '---', p2_char)
        -- print(p1_super, '---', p2_super)
    end
    -- local byterange = memory.readbyterange(0x02011388, 12)
    -- local test = memory.readdword(0x02011388)
    -- print(byterange)
    if match_state == 7 then return 7 end
    if match_state == 2 then return 2 end
end

local function check_wins()
    local p1_wins = memory.readdword(0x02016cd6)
    local p2_wins = memory.readdword(0x02016cd4)
    print('p1 ', p1_wins, player_1_win_count)
    print('p2 ', p2_wins, player_2_win_count)

    if p1_wins > player_1_win_count and p1_wins < 100 then
        player_1_total_wins = player_1_total_wins + 1
        player_2_win_count = 0
        -- print('player 1 win')
        if stat_file then
            stat_file:write('\n player1:')
            stat_file:write('\n player1-char:')
            stat_file:write(p1_char)
            stat_file:write('\n player1-super:')
            stat_file:write(p1_super)
            stat_file:write('\n player2-char:')
            stat_file:write(p2_char)
            stat_file:write('\n player2-super:')
            stat_file:write(p2_super)
            stat_file:write('\n p1-win:true')
        end
        if (p1_wins < 100) then -- rolls over at 99 but if not its like 65535 or something
            player_1_win_count = p1_wins
        else
            player_1_win_count = 0
        end
        match_just_ended = true
    end

    if p2_wins > player_2_win_count and p2_wins < 100 then
        player_2_total_wins = player_2_total_wins + 1
        -- reset opponent win count
        player_1_win_count = 0
        -- print('player 2 win')
        if stat_file then
            stat_file:write('\n player1-char:')
            stat_file:write(p1_char)
            stat_file:write('\n player1-super:')
            stat_file:write(p1_super)
            stat_file:write('\n player2-char:')
            stat_file:write(p2_char)
            stat_file:write('\n player2-super:')
            stat_file:write(p2_super)
            stat_file:write('\n p2-win:true')
        end
        -- TODO change this back once we can write the score back to memory
        if (p2_wins < 100) then -- rolls over at 99 but if not its like 65535 or something
            player_2_win_count = p2_wins
        else
            player_2_win_count = 0
        end
        match_just_ended = true
    end
end

local function check_getting_hit()
    local p2_hit_by_normal = memory.readbyte(0x02028861)
    local p2_hit_by_special = memory.readbyte(0x02028863)
    -- local p2_hits_landed_normals = 0
    -- local p2_hits_landed_specials = 0
    -- local p2_hits_landed_supers = 0
    -- local p2_hits_landed_supers_ext = 0
    -- local p1_hits_landed_normals = 0
    -- local p1_hits_landed_specials = 0
    -- local p1_hits_landed_supers = 0
    -- local p1_hits_landed_supers_ext = 0
    -- print('p2 hit n', p2_hit_by_normal)
    -- print('p2 hit s', p2_hit_by_special)
end

-- Lua writes current stat tracking to a text file here
function GLOBAL_read_stat_memory()
    local match_state_key = check_in_match()
    if stat_file then
        if match_state_key == 2 then

            local p1_current_meter = memory.readbyte(0x020695B5)
            local p2_current_meter = memory.readbyte(0x020695E1)

            if p1_current_meter <= p1_previous_meter then p1_previous_meter = p1_current_meter end
            if p2_current_meter <= p2_previous_meter then p2_previous_meter = p2_current_meter end

            local p1_meter_gained = p1_current_meter - p1_previous_meter
            local p2_meter_gained = p2_current_meter - p2_previous_meter
            if p1_meter_gained > 0 then
                p1_match_total_meter_gained = p1_match_total_meter_gained + p1_meter_gained
                p1_previous_meter = p1_current_meter

                stat_file:write('\n p1-meter-gained:')
                stat_file:write(p1_meter_gained)
                stat_file:write('\n p1-total-meter-gained:')
                stat_file:write(p1_match_total_meter_gained)
            end
            if p2_meter_gained > 0 then
                p2_match_total_meter_gained = p2_match_total_meter_gained + p2_meter_gained
                p2_previous_meter = p2_current_meter

                stat_file:write('\n p2-meter-gained:')
                stat_file:write(p2_meter_gained)
                stat_file:write('\n p2-total-meter-gained:')
                stat_file:write(p2_match_total_meter_gained)
            end
        end

        if match_just_ended and match_state_key == 7 then
            -- print('resetting all state')
            p1_match_total_meter_gained = 0
            p1_previous_meter = 0
            p2_match_total_meter_gained = 0
            p2_previous_meter = 0
            match_count = match_count + 1
            match_initialized = false
            print('Closing file one frame late to capture final meter.')
            stat_file:close()
            stat_file = nil
            local front_end_reader = io.open(ext_command_file, "w")
            if front_end_reader then
                front_end_reader:write('read-tracking-file')
                front_end_reader:close()
            end
        end

        if match_state_key == 7 then check_wins() end
    end
end

local function game_closing()
    local stat_file = io.open(match_track_file, "a")
    if stat_file then
        stat_file:write('')
        stat_file:write('\n -i-game-ended:1')
        stat_file:close()
    end
end

local function game_starting()
    -- erase all data on game start, just in case
    io.open(match_track_file, "w"):close()
    -- write game start
    local stat_file = io.open(match_track_file, "a")
    if stat_file then
        stat_file:write('')
        stat_file:write('\n -i-game-started')
        stat_file:close()
    end
    module_character_select.start_character_select_sequence()
end

emu.registerstart(game_starting)
emu.registerexit(game_closing)
emu.registerbefore(GLOBAL_read_stat_memory) -- Runs after each frame
gui.register(hyper_reflector_rendering)

-- UNCOMMENT below lines  for training mode online
-- emu.registerbefore(third_training.before_frame)
-- gui.register(third_training.on_gui)
-- pressing start should not pause the emulator this is not good =0
