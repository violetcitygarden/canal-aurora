extends CanvasLayer

var material_target: ShaderMaterial
var panel: PanelContainer
var enabled_box: CheckButton
var sliders: Dictionary = {}
const SAVE_PATH := "user://effects.cfg"
const OPTIONS := {"strength":"Força do VHS", "noise_amount":"Ruído da fita", "distortion":"Distorção / tracking", "color_bleed":"Separação das cores", "scanlines":"Linhas de varredura", "vignette":"Bordas escuras", "quantization":"Cores reduzidas"}

func _ready() -> void:
	add_to_group("effects_menu")
	layer = 20
	var button := Button.new()
	button.text = "Configurações · F2"
	button.position = Vector2(738,18)
	add_child(button)
	button.pressed.connect(func(): panel.visible = not panel.visible)
	panel = PanelContainer.new()
	panel.position = Vector2(225,105)
	panel.custom_minimum_size = Vector2(510,470)
	add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	panel.add_child(rows)
	var title := Label.new()
	title.text = "   IMAGEM E EFEITOS"
	rows.add_child(title)
	enabled_box = CheckButton.new()
	enabled_box.text = "VHS ligado"
	rows.add_child(enabled_box)
	var saved := ConfigFile.new()
	saved.load(SAVE_PATH)
	enabled_box.button_pressed = bool(saved.get_value("effects", "enabled", true))
	material_target.set_shader_parameter("enabled", enabled_box.button_pressed)
	enabled_box.toggled.connect(func(value): material_target.set_shader_parameter("enabled", value); save_settings())
	for key in OPTIONS:
		var row := HBoxContainer.new()
		rows.add_child(row)
		var label := Label.new()
		label.text = OPTIONS[key]
		label.custom_minimum_size.x = 230
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.custom_minimum_size.x = 180
		slider.value = clampf(float(saved.get_value("effects", key, 1.0)),0,1)*100
		row.add_child(slider)
		var number := Label.new()
		number.text = "%d%%" % slider.value
		row.add_child(number)
		sliders[key] = slider
		material_target.set_shader_parameter(key, slider.value/100)
		slider.value_changed.connect(func(value):
			material_target.set_shader_parameter(key, value/100)
			number.text = "%d%%" % value
			save_settings())
	var reset := Button.new()
	reset.text = "Restaurar padrão"
	rows.add_child(reset)
	reset.pressed.connect(func():
		enabled_box.button_pressed = true
		for slider in sliders.values(): slider.value = 100
		save_settings())
	var close := Button.new()
	close.text = "Fechar"
	rows.add_child(close)
	close.pressed.connect(func(): panel.hide())
	panel.hide()

func save_settings() -> void:
	var saved := ConfigFile.new()
	saved.set_value("effects", "enabled", enabled_box.button_pressed)
	for key in sliders: saved.set_value("effects", key, sliders[key].value/100)
	saved.save(SAVE_PATH)

func toggle_effects() -> void:
	enabled_box.button_pressed = not enabled_box.button_pressed

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			panel.visible = not panel.visible
			get_viewport().set_input_as_handled()
		elif panel.visible and event.keycode == KEY_ESCAPE:
			panel.hide()
			get_viewport().set_input_as_handled()
		elif panel.visible and event.keycode in [KEY_SPACE, KEY_C, KEY_V, KEY_H]:
			get_viewport().set_input_as_handled()
