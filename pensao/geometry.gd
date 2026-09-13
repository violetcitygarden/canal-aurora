extends Node3D
var materials: Dictionary = {}
func mat(color: String) -> Material:
	if not materials.has(color):
		var m := ShaderMaterial.new()
		m.shader = preload("res://psx.gdshader")
		m.set_shader_parameter("tint", Color(color))
		materials[color] = m
	return materials[color]
func box(at: Vector3, size: Vector3, color: String, parent: Node3D = self) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return add_mesh(mesh, at, color, parent)
func sphere(at: Vector3, size: Vector3, color: String, parent: Node3D = self) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.radius = 1
	mesh.height = 2
	var item := add_mesh(mesh, at, color, parent)
	item.scale = size
	return item
func cylinder(at: Vector3, radius: float, height: float, color: String, parent: Node3D = self) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return add_mesh(mesh, at, color, parent)
func add_mesh(mesh: Mesh, at: Vector3, color: String, parent: Node3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat(color)
	node.position = at
	parent.add_child(node)
	return node
func beam(a: Vector3, b: Vector3, width: float, color: String, parent: Node3D = self) -> void:
	var item := box((a + b) / 2, Vector3(width, a.distance_to(b), width), color, parent)
	item.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
func label(words: String, at: Vector3, pixel := 0.004) -> void:
	var node := Label3D.new()
	node.text = words
	node.font_size = 32
	node.pixel_size = pixel
	node.position = at
	node.modulate = Color("#403d34")
	node.outline_size = 0
	add_child(node)

func textured_box(at: Vector3, size: Vector3, color: String, texture: Texture2D, repeat_uv := Vector2.ONE) -> void:
	var item := box(at,size,color)
	var material := mat(color).duplicate() as ShaderMaterial
	material.set_shader_parameter("textured",true)
	material.set_shader_parameter("albedo_tex",texture)
	material.set_shader_parameter("repeat_uv",repeat_uv)
	item.material_override = material
