extends Control

@onready var spin_jugadores: SpinBox = $CenterContainer/VBoxContainer/FilaJugadores/SpinJugadores
@onready var contenedor_nombres: VBoxContainer = $CenterContainer/VBoxContainer/ContenedorNombres
@onready var spin_fichas: SpinBox = $CenterContainer/VBoxContainer/FilaFichas/SpinFichas
@onready var lbl_error: Label = $CenterContainer/VBoxContainer/LblError
@onready var btn_jugar: Button = $CenterContainer/VBoxContainer/BtnJugar


func _ready() -> void:
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
