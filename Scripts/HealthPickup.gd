extends Area2D

@export var heal_amount: int = 20  # how much health it restores

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):  # Make sure only the player picks it up
		if body.has_method("heal"):  # Player must have a heal() function
			body.heal(heal_amount)
		queue_free()  # remove the pickup after use
