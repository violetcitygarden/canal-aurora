extends Control
## Handmade station mark: painted lettering, offset ink and a striped roof.

var lettering: FontVariation

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		var y := float(i*7)
		draw_polyline(PackedVector2Array([Vector2(10,35+y),Vector2(115,5+y),Vector2(230,31+y)]), colors[i], 5, true)
	word("PENSÃO", Vector2(27,65), 29, Color("efb84e"))
	word("da", Vector2(16,98), 19, Color("58b8ad"))
	word("NAIR", Vector2(51,113), 53, Color("e77179"))
	draw_line(Vector2(54,125), Vector2(219,117), Color("58b8ad"), 5, true)
	draw_line(Vector2(60,131), Vector2(225,123), Color("efb84e"), 3, true)
	# Little off-register star, like a printed television title from the eighties.
	draw_colored_polygon(PackedVector2Array([Vector2(231,69),Vector2(235,79),Vector2(246,82),Vector2(235,86),Vector2(231,97),Vector2(227,86),Vector2(216,82),Vector2(227,79)]), Color("fff0c5"))
