extends Control
## Handmade station mark: painted lettering, offset ink and a striped roof.

var lettering: FontVariation

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	scale = Vector2(0.55, 0.55) / 3.0
	position = Vector2(804, 630) / 3.0
	rotation = deg_to_rad(-3)
	lettering = FontVariation.new()
	lettering.base_font = ThemeDB.fallback_font
	lettering.variation_embolden = 1.2
	queue_redraw()

func word(text: String, baseline: Vector2, size_px: int, color: Color) -> void:
	draw_string_outline(lettering, baseline + Vector2(3,4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, 7, Color("432d51"))
	draw_string_outline(lettering, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, 5, Color("fff0c5"))
	draw_string(lettering, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func _draw() -> void:
	if lettering == null: return
	# Three-color eaves suggest the boarding house without a literal illustration.
	var colors := [Color("e77179"), Color("efb84e"), Color("58b8ad")]
	for i in range(3):
		var y := float(i*5)
		var half_width := lettering.get_string_size("PENSÃO DA", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x/2.0 + 5.0
		draw_polyline(PackedVector2Array([Vector2(120-half_width,36+y),Vector2(120,21+y),Vector2(120+half_width,36+y)]), colors[i], 3, true)
	centered_word("PENSÃO DA", 65, 24, Color("efb84e"))
	centered_word("NAIR", 113, 53, Color("e77179"))
	draw_line(Vector2(37,125), Vector2(203,119), Color("58b8ad"), 5, true)
	draw_line(Vector2(37,131), Vector2(203,125), Color("efb84e"), 3, true)

func centered_word(text: String, baseline_y: float, size_px: int, color: Color) -> void:
	var width := lettering.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	word(text, Vector2(120.0 - width/2.0, baseline_y), size_px, color)
