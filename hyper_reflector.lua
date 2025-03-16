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
print('test')
print(previous_meter)

local function check_in_match()
    local match_state = memory.readbyte(0x020154A7);
    gamestate_read()

    -- wow we can character lock the menu!
    -- p1
    -- memory.writebyte(0x020154CF, 0x04) -- 0 to 6 -- character row
    -- memory.writebyte(0x0201566B, 0x01) -- 0 to 2 -- character colun
    -- -- p2
    -- memory.writebyte(0x020154D1, 0x06) -- 0 to 6 -- character row
    -- memory.writebyte(0x0201566D, 0x01) -- 0 to 2 -- character colun
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

    -- timers
    -- working match timer
    -- match_timer = memory.readbyte(0x02011377)
    -- working char select timer
    -- local char_select_timer = memory.readbyte(0x020154FB)

    -- parry related

    -- print(match_timer)
    return match_state == 2
end

-- match state
local match_total_meter_gained = 0;

-- Lua writes current stat tracking to a text file here
function GLOBAL_read_stat_memory()
    -- make sure we are in a match before we read / write to the file.
    if not check_in_match() then return end
    -- memory reads
    local current_meter = memory.readbyte(0x020695B5)
    -- test to see match end
    -- local match_state = memory.readbyte(0x020154A7);
    local p1_win = memory.readbyte(0x02016cd6)
    -- print(match_state)

    -- file open to write
    local file = io.open(match_track_file, "a")
    if file then
        if current_meter <= previous_meter then previous_meter = current_meter end
        local meter_gained = current_meter - previous_meter
        if meter_gained > 0 then -- compare our meters
            print(meter_gained)
            print(previous_meter, current_meter)
            
            -- here would could make an api call 
            match_total_meter_gained = match_total_meter_gained + meter_gained
            previous_meter = current_meter
            file:write('\n p1-meter-gained:')
            file:write(match_total_meter_gained)
            file:write('\n p1-total-meter-gained:')
            file:write(match_total_meter_gained)
            file:write('\n did p1 win?:')
            file:write(p1_win)
        end
        file:close()
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
    -- file open to write
    local file = io.open(match_track_file, "a")
    if file then
        file:write('\n -i-game-ended')
        file:close()
    end
end

local function game_starting()
    -- file open to write
    local file = io.open(match_track_file, "a")
    if file then
        file:write('\n -i-game-started')
        file:close()
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
