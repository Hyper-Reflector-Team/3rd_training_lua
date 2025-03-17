-- BEFORE BUILDING COPY THIS FILE TO lua/3rd_training_lua/ in order for the scripts to use the same root directories.
local third_training = require("3rd_training")
local util_draw = require("src/utils/draw");
local util_colors = require("src/utils/colors")
require("src/tools") -- TODO: refactor tools to export;
local command_file = "../../hyper_write_commands.txt"
local ext_command_file = "../../hyper_read_commands.txt" -- this is for sending back commands to electron.
local match_track_file = "../../hyper_track_match.txt"

-- game state 
require("src/gamestate")

-- state
local game_name = ""
local previous_meter = 0; -- for some reason meter set to 70 on character select 

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
local stat_file
-- match related
local p1_char
local p2_char
local p1_super
local p2_super
local function check_in_match()
    local match_state = memory.readbyte(0x020154A7);
    if match_state == 1 and stat_file == nil then
        -- initialize all the values we want to write like character and super are
        p1_char = memory.readbyte(0x02011387)
        p2_char = memory.readbyte(0x02011388)
        p1_super = memory.readbyte(0x020154D3)
        p2_super = memory.readbyte(0x020154D5)
        print(p1_char, '---', p2_char)
        print(p1_super, '---', p2_super)
        stat_file = io.open(match_track_file, "a")
    end
    gamestate_read() -- read game state every frame.
    return match_state == 2
end

-- match state
local match_total_meter_gained = 0;

local player_1_win_count = 0;
local player_2_win_count = 0

local function check_wins()
    local p1_wins = memory.readdword(0x02016cd6)
    local p2_wins = memory.readdword(0x02016cd4)
    if p1_wins > player_1_win_count and p1_wins < 100 then
        -- reset opponent win count
        player_2_win_count = 0
        print('player 1 win')
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
            stat_file:close()
            stat_file = nil
            local front_end_reader = io.open(ext_command_file, "w")
            if front_end_reader then
                front_end_reader:write('read-tracking-file')
                front_end_reader:close()
            end
        end
        player_1_win_count = player_1_win_count + 1
    end
    if p2_wins > player_2_win_count and p2_wins < 100 then
        -- reset opponent win count
        player_1_win_count = 0
        print('player 2 win')
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
            stat_file:close()
            stat_file = nil
            local front_end_reader = io.open(ext_command_file, "w")
            if front_end_reader then
                front_end_reader:write('read-tracking-file')
                front_end_reader:close()
            end
        end
        player_2_win_count = player_2_win_count + 1
    end
end

-- Lua writes current stat tracking to a text file here
function GLOBAL_read_stat_memory()
    check_wins()
    -- make sure we are in a match before we read / write to the file.
    if not check_in_match() then return end
    -- player 1 meter tracking
    local current_meter = memory.readbyte(0x020695B5)
    -- file open to write
    if stat_file then
        if current_meter <= previous_meter then previous_meter = current_meter end
        local meter_gained = current_meter - previous_meter
        if meter_gained > 0 then -- compare our meters
            print(meter_gained)
            print(previous_meter, current_meter)
            match_total_meter_gained = match_total_meter_gained + meter_gained
            previous_meter = current_meter
            stat_file:write('\n p1-meter-gained:')
            stat_file:write(match_total_meter_gained)
            stat_file:write('\n p1-total-meter-gained:')
            stat_file:write(match_total_meter_gained)
        end
    end
end

-- ELECTRON sends commands here, lua reads them and then then sends ifno back via text file
local function check_commands()
    GLOBAL_read_stat_memory()
    local file = io.open(command_file, "r")
    if file then
        local command = file:read("*l") -- Read first line
        file:close()

        if command == "game_name" then
            local value = emu.romname()
            memory.writebyte(0x02011388, 1) -- change p2 to alex
            -- memory.writebyte(0x02011377, 1) -- immediately end round
            memory.writeword(0x0201138B, 0x00) -- select super art 
            -- read from the current lua file and make a return an answer to the ext_command_file maybe better to have another file for commands sent to electron.
            local file2 = io.open(ext_command_file, "w")
            if file2 then
                file2:write(value)
                file2:close()
            end
            print('The game is: ', value)
        elseif command == "resume" then
            local value = emu.sourcename()
            -- read from the current lua file and make a return an answer to the ext_command_file.txt maybe better to have another file for commands sent to electron.
            local file2 = io.open(ext_command_file, "w")
            if file2 then
                file2:write(value)
                file2:close()
            end
        elseif command and string.find(command, "textinput:") then
            game_name = string.sub(command, 11) -- cut the first 11 characters from string
            -- read from the current lua file and make a return an answer to fbneo_commands_commands.txt maybe better to have another file for commands sent to electron.
            local file2 = io.open(ext_command_file, "w")
            if file2 then
                file2:write('we wrote to game')
                file2:close()
            end
        elseif command == "exit" then
            os.exit()
        end
        -- Clear the file after each input. If you want both clients running locally to read this file, without a deletion race condition, disable the below line, but keep in mind that the commands will happen every frame.
        io.open(command_file, "w"):close()
    end
end

-- We write to the stat tracking file here
local function game_closing()
    local stat_file = io.open(match_track_file, "a")
    if stat_file then
        stat_file:write('')
        stat_file:write('\n -i-game-ended:1')
        stat_file:close()
    end
end

local function game_starting()
    local stat_file = io.open(match_track_file, "a")
    if stat_file then
        stat_file:write('')
        stat_file:write('\n -i-game-started:1')
        stat_file:close()
    end

end

-- hyper-reflector commands -- this is actually global state
GLOBAL_isHyperReflectorOnline = true
emu.registerstart(game_starting)
emu.registerexit(game_closing)
emu.registerbefore(check_commands) -- Runs after each frame
-- gui.register(on_gui)

-- UNCOMMENT below lines  for training mode online
-- emu.registerbefore(third_training.before_frame)
-- gui.register(third_training.on_gui)
-- pressing start should not pause the emulator this is not good =0
