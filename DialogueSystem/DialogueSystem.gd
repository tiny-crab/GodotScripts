extends Node2D
class_name DialogueSystem

@onready var print_char_timer = $CharTimer
@onready var end_line_timer = $LineTimer
@onready var hold_timer = $HoldTimer

## Timespan between printing one [b]char[/b] and the next - in seconds
@export var time_between_chars = 0.1
## Timespan between printing one [b]char[/b] and the next when sped up - in seconds
@export var time_between_chars_speed_up = 0.01
## Timespan between printing one [b]line[/b] and the next - in seconds
@export var time_between_lines = 4.0
## Timespan between `hold()` and `interrupt()` to interpret the button as held
@export var time_hold = 0.1

signal display_line(line: String)
signal state_changed(state: States)

var lines_to_print: Array[String] = []
var line_being_printed: String = ""
var char_index = 0
var was_held = false

## State of the DialogueSystem
## [br]READY - awaiting new lines to be pushed into queue with `print_line` or `print_lines`
## [br]PRINTING - printing a single line
## [br]WAITING - paused between printing one line and the next
enum States {READY, PRINTING, WAITING}
var state: States = States.READY:
    set(value):
        emit_signal('state_changed', value)
        state = value

func _ready() -> void:
    print_char_timer.wait_time = time_between_chars
    end_line_timer.wait_time = time_between_lines
    hold_timer.wait_time = time_hold
    print_char_timer.timeout.connect(_print_char)
    end_line_timer.timeout.connect(_finish_printing)
    hold_timer.timeout.connect(_on_hold_timer_timeout)

## Queues a single line to be printed into the dialogue box.
func print_line(line: String) -> void:
    lines_to_print.push_back(line)

## Queues multiple lines to be printed into the dialogue box.
func print_lines(lines) -> void:
    for line in lines:
        lines_to_print.push_back(line)

## Should be called by parent node when a "skip" button is pressed.
## Will immediately reduce the amount of time between chars
## Will not interrupt the line if interpreted as "player is holding down button"
func hold() -> void:
    print("pressed down")
    speed_up(true)
    hold_timer.start()

func _on_hold_timer_timeout():
    print("button is being held")
    was_held = true

## Interrupts the dialogue box.
## If during a line being printed, prints the rest of the line.
## If waiting between one line and the next, starts the next line immediately
func interrupt() -> void:
    # if the button was held, don't do anything
    # the player wanted to speed up the text, not skip ahead
    speed_up(false)
    if was_held:
        print("button was held")
        was_held = false
    else:
        print("button was not held")
        hold_timer.stop()
        if state == States.PRINTING:
            _print_remaining_text()
        elif state == States.WAITING:
            _skip_to_next_line()

func speed_up(value) -> void:
    print_char_timer.wait_time = time_between_chars_speed_up if value else time_between_chars

## Prints the next character of the currently queued line to the dialogue box.
## Expects that `line_being_printed` has already been set with the queued line
func _print_char() -> void:
    emit_signal('display_line', line_being_printed.substr(0, char_index + 1))
    char_index += 1
    var reached_end_of_line = char_index == line_being_printed.length()
    if not reached_end_of_line:
        print_char_timer.start()
    else:
        state = States.WAITING
        end_line_timer.start()

## Prints the remainder of the queued line to the dialogue box.
## Called if the user "interrupts" or skips during the dialogue
func _print_remaining_text() -> void:
    emit_signal('display_line', line_being_printed)
    # interrupt the print char timer since we want to print the rest
    print_char_timer.stop()
    state = States.WAITING
    end_line_timer.start()

## Skips to the next line that's currently queued up
## Called if the user "interrupts" while waiting between lines.
func _skip_to_next_line() -> void:
    end_line_timer.stop()
    emit_signal('display_line', '')
    state = States.READY

## Resets the class to start printing.
func _start_printing():
    line_being_printed = lines_to_print.pop_front()
    char_index = 0
    emit_signal('display_line', '')
    state = States.PRINTING
    _print_char()

## Resets the class once a line has been printed to the dialogue.
func _finish_printing():
    emit_signal('display_line', '')
    state = States.READY

func _process(delta) -> void:
    if state == States.READY and lines_to_print.size() > 0:
        _start_printing()
