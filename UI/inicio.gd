extends Control

@onready var spin_jugadores: SpinBox = $CenterContainer/VBoxContainer/FilaJugadores/SpinJugadores
@onready var contenedor_nombres: VBoxContainer = $CenterContainer/VBoxContainer/ContenedorNombres
@onready var spin_fichas: SpinBox = $CenterContainer/VBoxContainer/FilaFichas/SpinFichas
@onready var lbl_error: Label = $CenterContainer/VBoxContainer/LblError
@onready var btn_jugar: Button = $CenterContainer/VBoxContainer/BtnJugar
@onready var lbl_titulo: Label = $CenterContainer/VBoxContainer/LblTitulo

func _ready() -> void:
	_estilizar()
	
	spin_jugadores.min_value = 2
	spin_jugadores.max_value = Partida.MAX_JUGADORES
	spin_jugadores.value = 4

	spin_fichas.min_value = 100
	spin_fichas.max_value = 100000
	spin_fichas.step = 100
	spin_fichas.value = 1000

	spin_jugadores.value_changed.connect(_on_cantidad_cambiada)
	btn_jugar.pressed.connect(_on_jugar)

	_on_cantidad_cambiada(spin_jugadores.value)


## Agrega o quita campos de texto para que haya uno por jugador.
func _on_cantidad_cambiada(valor: float) -> void:
	var cantidad: int = int(valor)

	while contenedor_nombres.get_child_count() < cantidad:
		var numero: int = contenedor_nombres.get_child_count() + 1
		var campo: LineEdit = LineEdit.new()
		campo.text = "Jugador %d" % numero
		campo.placeholder_text = "Nombre del jugador %d" % numero
		campo.custom_minimum_size = Vector2(300, 0)
		contenedor_nombres.add_child(campo)

	while contenedor_nombres.get_child_count() > cantidad:
		var ultimo: Node = contenedor_nombres.get_child(contenedor_nombres.get_child_count() - 1)
		contenedor_nombres.remove_child(ultimo)
		ultimo.queue_free()


func _on_jugar() -> void:
	var nombres: Array = []
	for campo in contenedor_nombres.get_children():
		var nombre: String = (campo as LineEdit).text.strip_edges()
		if nombre == "":
			lbl_error.text = "Todos los jugadores deben tener nombre."
			return
		if nombres.has(nombre):
			lbl_error.text = "Hay nombres repetidos: «%s»." % nombre
			return
		nombres.append(nombre)

	Config.nombres = nombres
	Config.fichas = int(spin_fichas.value)
	get_tree().change_scene_to_file("res://UI/mesa.tscn")
	
func _estilizar() -> void:
	# Fondo verde de mesa (queda detras de todo)
	var fondo: ColorRect = ColorRect.new()
	fondo.color = Color(0.11, 0.37, 0.23)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	move_child(fondo, 0)

	# Tarjeta oscura con borde de madera detras del formulario
	var centro: CenterContainer = $CenterContainer
	var caja: VBoxContainer = $CenterContainer/VBoxContainer
	var tarjeta: PanelContainer = PanelContainer.new()
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.35)
	estilo.set_corner_radius_all(20)
	estilo.set_border_width_all(4)
	estilo.border_color = Color(0.36, 0.2, 0.08)
	estilo.set_content_margin_all(30)
	tarjeta.add_theme_stylebox_override("panel", estilo)
	centro.remove_child(caja)
	tarjeta.add_child(caja)
	centro.add_child(tarjeta)

	# Titulo dorado con simbolos de los palos
	lbl_titulo.text = "♠ ♥  Poker Texas Hold'em  ♦ ♣"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 40)
	lbl_titulo.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	lbl_titulo.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.0))
	lbl_titulo.add_theme_constant_override("outline_size", 6)

	# Mensaje de error y boton Jugar
	lbl_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_error.add_theme_color_override("font_color", Color(1, 0.6, 0.5))
	_estilizar_boton(btn_jugar, Color(0.8, 0.5, 0.1))
	btn_jugar.add_theme_font_size_override("font_size", 22)
	btn_jugar.custom_minimum_size.y = 54


func _estilizar_boton(b: Button, color: Color) -> void:
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var s: StyleBoxFlat = StyleBoxFlat.new()
		s.set_corner_radius_all(10)
		s.set_content_margin_all(10)
		match estado:
			"normal": s.bg_color = color
			"hover": s.bg_color = color.lightened(0.2)
			"pressed": s.bg_color = color.darkened(0.2)
			"disabled": s.bg_color = color.darkened(0.5)
		b.add_theme_stylebox_override(estado, s)
