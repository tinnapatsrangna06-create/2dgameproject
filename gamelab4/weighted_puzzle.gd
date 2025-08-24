extends Area2D

@export var door : Sprite2D

var press: bool = false:
	set(value):
		press = value
		%Up.set_deferred("visible",not value)
		%Down.set_deferred("visible",value)
		

func pressed():
	press = true
	door.open_door()
	
func unpressed():
	press = false
	door.close_door()

func _on_body_entered(body: Node2D) -> void:
	pressed()


func _on_body_exited(body: Node2D) -> void:
	unpressed()
