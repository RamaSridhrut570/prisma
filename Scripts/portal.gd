extends Node3D

@onready var ring: MeshInstance3D = $Ring
@onready var portalplane: MeshInstance3D = $Ring/portalplane
@onready var area_3d: Area3D = $Area3D

signal player_entered

var _entered: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	disable_portal()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func enable_portal() -> void:
	_entered = false
	portalplane.show()
	area_3d.monitorable = true
	area_3d.monitoring = true

func disable_portal() -> void:
	portalplane.hide()
	area_3d.monitorable = false
	area_3d.monitoring = false

func _on_area_3d_body_entered(body: Node3D) -> void:
	if _entered: return
	if not body.is_in_group("Player"): return
	_entered = true
	disable_portal()
	player_entered.emit()
