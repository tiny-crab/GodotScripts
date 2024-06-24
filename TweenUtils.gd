extends Node
## Use by adding to Autoload scripts
## I like naming it as `t` so that the final function call is `t.ween().tween_property(...)`

func ween():
    return get_tree().create_tween()
