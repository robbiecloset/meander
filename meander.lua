--
-- meander ->
--      <--
--     ->
--       --->
--           ->
-- by robbbiecloset
--

-- engine.name = 'OutputTutorial'

local midi_vel = 100
local midi_out
local midi_out_channel
local viewport = { width = 128, height = 64, frame = 0 }

local play_triggers = { "O", "X", "O", "O", "X" }
local play_head = 1

local meander_triggers = {}
local meander_head = 1

local durations = { 2, 1, 1, 4, 1, 3, 1 }
local duration_head = 1
local duration_count = 0

local notes = { "a4", "d3", "C4", "F3", "C3", "b4" }
local note_head = 1
local notes_on = {}

local line_height = 10

local play_state = { ON = 1, OFF = 0 }
local playing = play_state.OFF

local clock_id

local middle_C = 60
local note_to_int = {
  C = 0,
  d = 1,
  D = 2,
  e = 3,
  E = 4,
  f = 4,
  F = 5,
  g = 6,
  G = 7,
  a = 8,
  A = 9,
  b = 10,
  B = 11,
  c = 11
}

-- Main

function init()
  -- params:add{
  --   type = "number", 
  --   id = "midi_out_channel", 
  --   name = "MIDI out channel", 
  --   min = 1, 
  --   max = 16, 
  --   default = 1
  -- }
  -- midi_out_channel = params:get("midi_out_channel")
  midi_out_channel = 1
  midi_out = midi.connect(1)
  
  clock_connect()
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  -- Render
  redraw()
end

-- Interactions

function key(id, state)
  if id == 3 and state == 0 then
    if playing == play_state.ON then
      kill_playing_notes()
      playing = play_state.OFF
      clock.cancel(clock_id)
      clock_id = nil
    else 
      playing = play_state.ON
      clock_id = clock.run(tick)
    end
  end
end

function enc(id, delta)
end

-- Clock stuff

function tick()
  while true do
    clock.sync(1/4)
    iterate()
  end
end

function iterate()
  print("iterate")
  
  if durations[duration_head] > duration_count then
    duration_count = duration_count + 1
    return
  end
  duration_count = 1
  
  if duration_head == #durations then
    duration_head = 1
  else
    duration_head = duration_head + 1
  end
  
  if play_head == #play_triggers then
    play_head = 1
  else
    play_head = play_head + 1
  end
  
  kill_playing_notes()
  
  -- Only advance the note head if the trigger is "on".
  if play_triggers[play_head] == "X" then
    if note_head == #notes then
      note_head = 1
    else
      note_head = note_head + 1
    end
    print("midi out channel" .. midi_out_channel)
    local note_name = string.sub(notes[note_head], 1, 1)
    local note_octave = string.sub(notes[note_head], 2)
    local midi_num = ((note_octave + 1) * 12) + note_to_int[note_name]
    table.insert(notes_on, midi_num)
    midi_out:note_on(midi_num, midi_vel)
  end
  
  redraw()
end

function kill_playing_notes()
  for i = 1, #notes_on do
    midi_out:note_off(notes_on[i], nil, midi_out_channel)
  end
  notes_on = {}
end

function clock_connect()
  params:set("clock_tempo", 90)
end

-- Render

function draw_triggers()
  local trigger_width = 6
  for i=1, #play_triggers do
    if i == play_head then
      screen.level(8)
    else
      screen.level(4)
    end
    screen.move(trigger_width * (i - 1), line_height)
    screen.text(play_triggers[i])
  end
end

function draw_durations()
  local duration_width = 8
  for i=1, #durations do
    if i == duration_head then
      screen.level(8)
    else
      screen.level(4)
    end
    screen.move(duration_width * (i - 1), line_height * 2)
    screen.text(durations[i])
  end
end

function draw_notes()
  local note_width = 12
  for i=1, #notes do
    if i == note_head then
      screen.level(8)
    else
      screen.level(4)
    end
    screen.move(note_width * (i - 1), (viewport.height - line_height))
    screen.text(notes[i])
  end
end

function redraw()
  screen.clear()
  draw_triggers()
  draw_durations()
  draw_notes()

  screen.level(4)
  screen.move(96, line_height)
  screen.text("triggers")
  
  screen.move(90, line_height * 2)
  screen.text("durations")

  screen.move(90, line_height * 3)
  screen.text("meanders")

  screen.move(105, (viewport.height - line_height))
  screen.text("notes")

  screen.stroke()
  screen.update()
end

-- Utils

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end