class_name CartaUI
extends PanelContainer
## Dibuja una carta con codigo (sin imagenes).

static func crear(c: Carta, boca_arriba: bool = true, tamano: Vector2 = Vector2(70, 100)) -> CartaUI:
	var ui: CartaUI = CartaUI.new()
	ui._configurar(c, boca_arriba, tamano)
	return ui


## Espacio vacio donde todavia no hay carta.
static func hueco(tamano: Vector2 = Vector2(70, 100)) -> CartaUI:
	var ui: CartaUI = CartaUI.new()
	ui.custom_minimum_size = tamano
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.set_corner_radius_all(8)
	estilo.set_border_width_all(2)
	estilo.border_color = Color(1, 1, 1, 0.25)
	estilo.bg_color = Color(0, 0, 0, 0.2)
	ui.add_theme_stylebox_override("panel", estilo)
	return ui


func _configurar(c: Carta, boca_arriba: bool, tamano: Vector2) -> void:
	custom_minimum_size = tamano

	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.set_corner_radius_all(8)
	estilo.set_border_width_all(2)
	estilo.border_color = Color.BLACK
	estilo.shadow_size = 6
	estilo.shadow_color = Color(0, 0, 0, 0.4)
	if boca_arriba:
		estilo.bg_color = Color.WHITE
	else:
		estilo.bg_color = Color(0.15, 0.25, 0.6) # reverso azul
	add_theme_stylebox_override("panel", estilo)

	if not boca_arriba:
		return

	var simbolo: String = "?"
	var color: Color = Color.BLACK
	match c.palo:
		"picas": simbolo = "♠"
		"corazones":
			simbolo = "♥"
			color = Color(0.8, 0.1, 0.1)
		"diamantes":
			simbolo = "♦"
			color = Color(0.8, 0.1, 0.1)
		"treboles": simbolo = "♣"

	var valor: String = str(c.valor)
	match c.valor:
		11: valor = "J"
		12: valor = "Q"
		13: valor = "K"
		14: valor = "A"

	var lbl: Label = Label.new()
	lbl.text = valor + "\n" + simbolo
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", int(tamano.y * 0.28))
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
