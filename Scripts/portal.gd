extends Node3D

@onready var ring: MeshInstance3D = $Ring
@onready var portalplane: MeshInstance3D = $Ring/portalplane
@onready var area_3d: Area3D = $Area3D
@onready var spot_light_3d: SpotLight3D = $SpotLight3D
var material: Material


signal player_entered

var _entered: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material = portalplane.get_surface_override_material(0) if portalplane.get_surface_override_material(0) else portalplane.material
	disable_portal()
	if get_parent().is_in_group("Main Menu 3D"):
		enable_portal()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not material:
		material = portalplane.get_surface_override_material(0) if portalplane.get_surface_override_material(0) else portalplane.material

func enable_portal() -> void:
	_entered = false
	portalplane.show()
	spot_light_3d.show()
	area_3d.set_deferred("monitorable", true)
	area_3d.set_deferred("monitoring", true)

func disable_portal() -> void:
	portalplane.hide()
	spot_light_3d.hide()
	area_3d.set_deferred("monitorable", false)
	area_3d.set_deferred("monitoring", false)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if _entered: return
	if not body.is_in_group("Player"): return
	_entered = true
	disable_portal()
	player_entered.emit()
