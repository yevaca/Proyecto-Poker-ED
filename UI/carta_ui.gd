class_name CartaUI
extends PanelContainer
## Dibuja una carta con codigo (sin imagenes).

static func crear(c: Carta, boca_arriba: bool = true) -> CartaUI:
	var ui := CartaUI.new()
	ui._configurar(c, boca_arriba)
	return ui


func _configurar(c: Carta, boca_arriba: bool) -> void:
	custom_minimum_size = Vector2(70, 100)

	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(8)
	estilo.set_border_width_all(2)
	estilo.border_color = Color.BLACK
	if boca_arriba:
		estilo.bg_color = Color.WHITE
	else:
		estilo.bg_color = Color(0.15, 0.25, 0.6) # reverso azul
	add_theme_stylebox_override("panel", estilo)

	if not boca_arriba:
		return

	var simbolo := "?"
	var color := Color.BLACK
	match c.palo:
		"picas": simbolo = "♠"
		"corazones":
			simbolo = "♥"
			color = Color(0.8, 0.1, 0.1)
		"diamantes":
			simbolo = "♦"
			color = Color(0.8, 0.1, 0.1)
		"treboles": simbolo = "♣"

	var valor := str(c.valor)
	match c.valor:
		11: valor = "J"
		12: valor = "Q"
		13: valor = "K"
		14: valor = "A"

	var lbl := Label.new()
	lbl.text = valor + "\n" + simbolo
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
