extends Button

## Signals that the button was held down. Emitted once the button is released
signal released_from_hold
## Signals that the button was only pressed. Emitted once the button is released
signal released_from_press

## How long the button can be down to be counted as a "press"
## Any longer, and the interaction is interpreted as a "hold"
@export var press_time = 0.25
@onready var press_timer = $PressTimer

var held_down = false

func _ready():
    press_timer.wait_time = press_time
    press_timer.timeout.connect(_on_press_timer_timeout)
    self.button_up.connect(_on_button_release)
    self.button_down.connect(_on_button_down)

func _on_press_timer_timeout():
    held_down = true

func _on_button_down():
    press_timer.start()

func _on_button_release():
    if held_down:
        emit_signal('released_from_hold')
    else:
        emit_signal('released_from_press')
    held_down = false
    press_timer.stop()
