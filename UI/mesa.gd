extends Control

var partida: Partida
## true = el jugador en turno ya pulso "Ver mis cartas".
var viendo := false

@onready var lbl_fase: Label = $VBoxContainer/LblFase
@onready var lbl_bote: Label = $VBoxContainer/LblBote
@onready var lbl_mesa: Label = $VBoxContainer/LblMesa
@onready var cartas_mesa: HBoxContainer = $VBoxContainer/CartasMesa
@onready var grid_jugadores: GridContainer = $VBoxContainer/GridJugadores
@onready var lbl_mano: Label = $VBoxContainer/LblMano
@onready var cartas_mano: HBoxContainer = $VBoxContainer/CartasMano
@onready var btn_ver: Button = $VBoxContainer/BtnVer
@onready var lbl_mensaje: Label = $VBoxContainer/LblMensaje
@onready var btn_fold: Button = $VBoxContainer/HBoxContainer/BtnFold
@onready var btn_igualar: Button = $VBoxContainer/HBoxContainer/BtnIgualar
@onready var spin_subir: SpinBox = $VBoxContainer/HBoxContainer/SpinSubir
@onready var btn_subir: Button = $VBoxContainer/HBoxContainer/BtnSubir
@onready var btn_all_in: Button = $VBoxContainer/HBoxContainer/BtnAllIn
@onready var btn_nueva: Button = $VBoxContainer/BtnNueva
@onready var btn_menu: Button = $VBoxContainer/BtnMenu
@onready var dialogo_salir: ConfirmationDialog = $DialogoSalir


func _ready() -> void:
	var nombres: Array = Config.nombres
	if nombres.is_empty():
		nombres = ["Ana", "Luis", "Sofia", "Pedro"] # por si se abre la mesa sola
	partida = Partida.new(nombres, Config.fichas)

	partida.turno_cambiado.connect(func(_j): _actualizar())
	partida.fase_cambiada.connect(func(_f): _actualizar())
	partida.mano_terminada.connect(_on_mano_terminada)

	btn_fold.pressed.connect(func(): _ejecutar(partida.accion_fold()))
	btn_igualar.pressed.connect(func(): _ejecutar(partida.accion_igualar()))
	btn_all_in.pressed.connect(func(): _ejecutar(partida.accion_all_in()))
	btn_subir.pressed.connect(func(): _ejecutar(partida.accion_subir(int(spin_subir.value))))
	btn_nueva.pressed.connect(_nueva_mano)
	btn_ver.pressed.connect(_on_ver_pressed)
	btn_menu.pressed.connect(func(): dialogo_salir.popup_centered())
	dialogo_salir.confirmed.connect(_volver_al_menu)

	_nueva_mano()


func _nueva_mano() -> void:
	lbl_mensaje.text = ""
	viendo = false
	if not partida.iniciar_mano():
		var g: Jugador = partida.ganador_partida()
		lbl_mensaje.text = "¡Partida terminada! Ganador: %s" % g.nombre
		_actualizar()


func _on_ver_pressed() -> void:
	viendo = true
	_actualizar()


func _ejecutar(ok: bool) -> void:
	if ok:
		lbl_mensaje.text = ""
		viendo = false # el siguiente jugador debe pulsar "Ver mis cartas"
	else:
		lbl_mensaje.text = "Jugada no válida"
	_actualizar()


func _on_mano_terminada(resultados: Array) -> void:
	var texto: String = ""
	for r in resultados:
		var nombres: Array = []
		for g in r["ganadores"]:
			nombres.append(g.nombre)
		texto += "%s gana %d" % [", ".join(nombres), r["monto"]]
		if r["categoria"] != "":
			texto += " con %s" % r["categoria"]
		texto += "\n"
	lbl_mensaje.text = texto
	viendo = false
	_actualizar()


# ---------------------------------------------------------------------------
#  Dibujar todo (se llama despues de cada cambio)
# ---------------------------------------------------------------------------
func _actualizar() -> void:
	var actual: Jugador = partida.jugador_actual()
	var fin: bool = partida.fase == Partida.Fase.FIN_MANO
	var hay_turno: bool = actual != null

	lbl_fase.text = "Fase: " + partida.nombre_fase()
	lbl_bote.text = "Bote: %d" % partida.bote.total

	# Cartas comunitarias (siempre visibles)
	lbl_mesa.text = "Mesa:"
	_limpiar(cartas_mesa)
	for c in partida.mesa.obtener_cartas():
		cartas_mesa.add_child(CartaUI.crear(c, true))

	# Lista de jugadores (una etiqueta por jugador, en dos columnas)
	_limpiar(grid_jugadores)
	for j in partida.jugadores:
		var linea: String = j.nombre
		if j == partida.dealer: linea += " (D)"
		linea += " | fichas: %d | apuesta: %d" % [j.fichas, j.apuesta_actual]
		if not j.en_partida: linea += " | ELIMINADO"
		elif not j.en_mano: linea += " | retirado"
		elif j.esta_all_in(): linea += " | ALL-IN"
		# Al terminar la mano se muestran las cartas de los que siguen en juego
		if fin and j.en_mano:
			linea += " | " + _texto_mano(j)

		var lbl: Label = Label.new()
		lbl.text = linea
		if j == actual:
			lbl.text = "▶ " + linea
			lbl.add_theme_color_override("font_color", Color.YELLOW)
		elif not j.en_partida or not j.en_mano:
			lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		grid_jugadores.add_child(lbl)

	# Cartas del jugador en turno: ocultas hasta que pulse "Ver mis cartas"
	_limpiar(cartas_mano)
	if hay_turno:
		if viendo:
			lbl_mano.text = "Cartas de %s:" % actual.nombre
		else:
			lbl_mano.text = "Turno de %s. Pasa el computador a %s y pulsa «Ver mis cartas»." % [actual.nombre, actual.nombre]
		for c in actual.mano.obtener_cartas():
			cartas_mano.add_child(CartaUI.crear(c, viendo))
	else:
		lbl_mano.text = ""

	# Botones: solo se puede actuar despues de ver las cartas
	btn_ver.visible = hay_turno and not viendo
	var puede: bool = hay_turno and viendo
	btn_fold.disabled = not puede
	btn_igualar.disabled = not puede
	btn_all_in.disabled = not puede
	btn_subir.disabled = not puede
	spin_subir.editable = puede
	btn_nueva.disabled = not fin

	if hay_turno:
		if partida.puede_hacer_check(actual):
			btn_igualar.text = "Pasar (check)"
		else:
			btn_igualar.text = "Igualar (%d)" % partida.monto_para_igualar(actual)
		spin_subir.min_value = partida.subida_minima()
		spin_subir.max_value = max(actual.apuesta_actual + actual.fichas, partida.subida_minima())
		spin_subir.value = spin_subir.min_value


# ---------------------------------------------------------------------------
#  Ayudas
# ---------------------------------------------------------------------------
func _limpiar(contenedor: Control) -> void:
	for h in contenedor.get_children():
		contenedor.remove_child(h)
		h.queue_free()


func _texto_mano(j: Jugador) -> String:
	var t: Array = []
	for c in j.mano.obtener_cartas():
		t.append(_texto_carta(c))
	return "  ".join(t)


func _texto_carta(c: Carta) -> String:
	var v: String = str(c.valor)
	match c.valor:
		11: v = "J"
		12: v = "Q"
		13: v = "K"
		14: v = "A"
	return v + " " + c.palo


func _volver_al_menu() -> void:
	get_tree().change_scene_to_file("res://UI/inicio.tscn")
