extends Control

## Tamanos de las cartas. Si algo no cabe en pantalla, baja estos numeros.
const TAM_MESA := Vector2(70, 98)
const TAM_MANO := Vector2(60, 84)
const TAM_MINI := Vector2(28, 40)

var partida: Partida
## true = el jugador en turno ya pulso "Ver mis cartas".
var viendo := false

## Jugadores que ganaron algun bote en la ultima mano (para resaltarlos).
var ganadores: Array = []
## true cuando ya hay campeon de la partida completa.
var fin_partida: bool = false

# Panel de resultado (se crea por codigo)
var panel_resultado: PanelContainer
var lbl_res_titulo: Label
var lbl_res_texto: Label
var btn_res: Button

@onready var lbl_fase: Label = $VBoxContainer/BarraSuperior/LblFase
@onready var btn_menu: Button = $VBoxContainer/BarraSuperior/BtnMenu
@onready var col_izq: VBoxContainer = $VBoxContainer/Centro/ColIzq
@onready var col_der: VBoxContainer = $VBoxContainer/Centro/ColDer
@onready var panel_mesa: PanelContainer = $VBoxContainer/Centro/ColCentro/PanelMesa
@onready var lbl_bote: Label = $VBoxContainer/Centro/ColCentro/PanelMesa/ContenidoMesa/LblBote
@onready var cartas_mesa: HBoxContainer = $VBoxContainer/Centro/ColCentro/PanelMesa/ContenidoMesa/CartasMesa
@onready var lbl_mano: Label = $VBoxContainer/Centro/ColCentro/LblMano
@onready var cartas_mano: HBoxContainer = $VBoxContainer/Centro/ColCentro/CartasMano
@onready var btn_ver: Button = $VBoxContainer/Centro/ColCentro/BtnVer
@onready var lbl_mensaje: Label = $VBoxContainer/Centro/ColCentro/LblMensaje
@onready var fila_botones: HBoxContainer = $VBoxContainer/Centro/ColCentro/HBoxContainer
@onready var btn_fold: Button = $VBoxContainer/Centro/ColCentro/HBoxContainer/BtnFold
@onready var btn_igualar: Button = $VBoxContainer/Centro/ColCentro/HBoxContainer/BtnIgualar
@onready var spin_subir: SpinBox = $VBoxContainer/Centro/ColCentro/HBoxContainer/SpinSubir
@onready var btn_subir: Button = $VBoxContainer/Centro/ColCentro/HBoxContainer/BtnSubir
@onready var btn_all_in: Button = $VBoxContainer/Centro/ColCentro/HBoxContainer/BtnAllIn
@onready var dialogo_salir: ConfirmationDialog = $DialogoSalir


func _ready() -> void:
	_aplicar_estilo()
	_crear_panel_resultado()

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
	btn_ver.pressed.connect(_on_ver_pressed)
	btn_menu.pressed.connect(func(): dialogo_salir.popup_centered())
	dialogo_salir.confirmed.connect(_volver_al_menu)

	_nueva_mano()


# ---------------------------------------------------------------------------
#  Estilo visual (se aplica una sola vez)
# ---------------------------------------------------------------------------
func _aplicar_estilo() -> void:
	# La mesa: panel ovalado verde con borde de madera, centrado
	var estilo_mesa: StyleBoxFlat = StyleBoxFlat.new()
	estilo_mesa.bg_color = Color(0.07, 0.36, 0.2)
	estilo_mesa.set_corner_radius_all(70)
	estilo_mesa.set_border_width_all(8)
	estilo_mesa.border_color = Color(0.36, 0.2, 0.08)
	estilo_mesa.set_content_margin_all(24)
	estilo_mesa.content_margin_left = 50
	estilo_mesa.content_margin_right = 50
	panel_mesa.add_theme_stylebox_override("panel", estilo_mesa)
	panel_mesa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	$VBoxContainer/Centro/ColCentro.alignment = BoxContainer.ALIGNMENT_CENTER
	col_izq.alignment = BoxContainer.ALIGNMENT_CENTER
	col_der.alignment = BoxContainer.ALIGNMENT_CENTER

	# Textos
	lbl_fase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_fase.add_theme_font_size_override("font_size", 22)
	lbl_bote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_bote.add_theme_font_size_override("font_size", 26)
	lbl_bote.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	lbl_mano.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mensaje.add_theme_font_size_override("font_size", 18)
	lbl_mensaje.add_theme_color_override("font_color", Color(1, 0.85, 0.3))

	# Centrado de las filas de cartas y botones
	cartas_mesa.alignment = BoxContainer.ALIGNMENT_CENTER
	cartas_mesa.add_theme_constant_override("separation", 12)
	cartas_mano.alignment = BoxContainer.ALIGNMENT_CENTER
	cartas_mano.add_theme_constant_override("separation", 10)
	cartas_mano.custom_minimum_size.y = TAM_MANO.y # evita que la pantalla "salte"
	fila_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_botones.add_theme_constant_override("separation", 15)


	# Botones con color
	_estilizar_boton(btn_fold, Color(0.7, 0.2, 0.2))
	_estilizar_boton(btn_igualar, Color(0.2, 0.5, 0.3))
	_estilizar_boton(btn_subir, Color(0.2, 0.4, 0.7))
	_estilizar_boton(btn_all_in, Color(0.8, 0.5, 0.1))
	_estilizar_boton(btn_ver, Color(0.3, 0.3, 0.65))
	_estilizar_boton(btn_menu, Color(0.3, 0.3, 0.3))
	btn_ver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_ver.custom_minimum_size.x = 220
	lbl_fase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_izq.add_theme_constant_override("separation", 6)
	col_der.add_theme_constant_override("separation", 6)


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
	b.add_theme_font_size_override("font_size", 18)
	b.custom_minimum_size = Vector2(120, 44)


# ---------------------------------------------------------------------------
#  Flujo del juego
# ---------------------------------------------------------------------------
func _nueva_mano() -> void:
	lbl_mensaje.text = ""
	viendo = false
	ganadores = []
	if partida.iniciar_mano():
		panel_resultado.visible = false
	else:
		_mostrar_resultado("")
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
	ganadores = []
	var lineas: Array = []
	for r in resultados:
		var nombres: Array = []
		for g in r["ganadores"]:
			nombres.append(g.nombre)
			if not ganadores.has(g):
				ganadores.append(g)
		var verbo: String = "gana" if nombres.size() == 1 else "ganan"
		var linea: String = "%s %s %d" % [", ".join(nombres), verbo, r["monto"]]
		if r["categoria"] != "":
			linea += " con %s" % r["categoria"]
		lineas.append(linea)
	viendo = false
	_mostrar_resultado("\n".join(lineas))
	_actualizar()

func _crear_panel_resultado() -> void:
	panel_resultado = PanelContainer.new()
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(0.04, 0.04, 0.07, 0.94)
	estilo.set_corner_radius_all(16)
	estilo.set_border_width_all(3)
	estilo.border_color = Color(1, 0.85, 0.3)
	estilo.set_content_margin_all(18)
	panel_resultado.add_theme_stylebox_override("panel", estilo)
	panel_resultado.custom_minimum_size.x = 420

	# Anclado abajo al centro de la pantalla; crece hacia arriba y hacia los lados.
	# Si tapa algo, cambia el -20 (mas negativo = mas arriba).
	panel_resultado.anchor_left = 0.5
	panel_resultado.anchor_right = 0.5
	panel_resultado.anchor_top = 1.0
	panel_resultado.anchor_bottom = 1.0
	panel_resultado.offset_left = 0
	panel_resultado.offset_right = 0
	panel_resultado.offset_top = -250
	panel_resultado.offset_bottom = -250
	panel_resultado.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_resultado.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var caja: VBoxContainer = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	panel_resultado.add_child(caja)

	lbl_res_titulo = Label.new()
	lbl_res_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_res_titulo.add_theme_font_size_override("font_size", 24)
	lbl_res_titulo.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	caja.add_child(lbl_res_titulo)

	lbl_res_texto = Label.new()
	lbl_res_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_res_texto.add_theme_font_size_override("font_size", 18)
	caja.add_child(lbl_res_texto)

	btn_res = Button.new()
	btn_res.text = "Siguiente mano"
	_estilizar_boton(btn_res, Color(0.2, 0.5, 0.3))
	btn_res.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_res.custom_minimum_size.x = 200
	btn_res.pressed.connect(_on_res_boton)
	caja.add_child(btn_res)

	panel_resultado.visible = false
	add_child(panel_resultado) # al final, para que se dibuje encima de todo


func _mostrar_resultado(texto: String) -> void:
	if partida.hay_ganador_partida():
		var campeon: Jugador = partida.ganador_partida()
		var extra: String = "Campeón: %s" % campeon.nombre
		lbl_res_titulo.text = "¡Fin de la partida!"
		lbl_res_texto.text = extra if texto == "" else texto + "\n\n" + extra
		btn_res.text = "Volver al menú"
		fin_partida = true
	else:
		lbl_res_titulo.text = "Resultado de la mano"
		lbl_res_texto.text = texto
		btn_res.text = "Siguiente mano"
		fin_partida = false
	panel_resultado.visible = true


func _on_res_boton() -> void:
	if fin_partida:
		_volver_al_menu()
	else:
		_nueva_mano()


func _volver_al_menu() -> void:
	get_tree().change_scene_to_file("res://UI/inicio.tscn")


# ---------------------------------------------------------------------------
#  Dibujar todo (se llama despues de cada cambio)
# ---------------------------------------------------------------------------
func _actualizar() -> void:
	var actual: Jugador = partida.jugador_actual()
	var fin: bool = partida.fase == Partida.Fase.FIN_MANO
	var hay_turno: bool = actual != null

	lbl_fase.text = "Fase: " + partida.nombre_fase().capitalize()
	lbl_bote.text = "Bote: %d" % partida.bote.total

	# Cartas comunitarias: siempre 5 posiciones, vacias hasta que salgan
	_limpiar(cartas_mesa)
	var comunitarias: Array = partida.mesa.obtener_cartas()
	for i in range(5):
		if i < comunitarias.size():
			cartas_mesa.add_child(CartaUI.crear(comunitarias[i], true, TAM_MESA))
		else:
			cartas_mesa.add_child(CartaUI.hueco(TAM_MESA))

	# Tarjetas de jugadores: la mitad a cada lado de la mesa
	_limpiar(col_izq)
	_limpiar(col_der)
	var mitad: int = ceili(partida.jugadores.size() / 2.0)
	for i in range(partida.jugadores.size()):
		var tarjeta: PanelContainer = _crear_tarjeta(partida.jugadores[i], actual, fin)
		if i < mitad:
			col_izq.add_child(tarjeta)
		else:
			col_der.add_child(tarjeta)

	# Cartas del jugador en turno: ocultas hasta que pulse "Ver mis cartas"
	_limpiar(cartas_mano)
	if hay_turno:
		if viendo:
			lbl_mano.text = "Cartas de %s" % actual.nombre
		else:
			lbl_mano.text = "Turno de %s: pasa el computador y pulsa «Ver mis cartas»" % actual.nombre
		for c in actual.mano.obtener_cartas():
			cartas_mano.add_child(CartaUI.crear(c, viendo, TAM_MANO))
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

	if hay_turno:
		if partida.puede_hacer_check(actual):
			btn_igualar.text = "Pasar (check)"
		else:
			btn_igualar.text = "Igualar (%d)" % partida.monto_para_igualar(actual)
		spin_subir.min_value = partida.subida_minima()
		spin_subir.max_value = max(actual.apuesta_actual + actual.fichas, partida.subida_minima())
		spin_subir.value = spin_subir.min_value


## Una tarjeta por jugador: resaltada si es su turno, atenuada si ya no juega.
func _crear_tarjeta(j: Jugador, actual: Jugador, fin: bool) -> PanelContainer:
	var es_ganador: bool = ganadores.has(j)
	var tarjeta: PanelContainer = PanelContainer.new()
	tarjeta.custom_minimum_size = Vector2(220, 0)
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(6)
	estilo.set_border_width_all(2)
	estilo.bg_color = Color(0, 0, 0, 0.35)
	estilo.border_color = Color(1, 1, 1, 0.15)
	if j == actual:
		estilo.bg_color = Color(0.45, 0.38, 0.0, 0.55)
		estilo.border_color = Color.YELLOW
	if es_ganador:
		estilo.bg_color = Color(0.55, 0.42, 0.0, 0.8)
		estilo.border_color = Color(1, 0.85, 0.3)
		estilo.set_border_width_all(4)
	tarjeta.add_theme_stylebox_override("panel", estilo)
	if not j.en_partida or not j.en_mano:
		tarjeta.modulate = Color(1, 1, 1, 0.45)

	var fila: HBoxContainer = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	tarjeta.add_child(fila)

	var nombre: String = j.nombre
	if j == partida.dealer:
		nombre += " (D)"
	if es_ganador:
		nombre += " · GANADOR"
	elif not j.en_partida:
		nombre += " · Eliminado"
	elif not j.en_mano:
		nombre += " · Retirado"
	elif j.esta_all_in():
		nombre += " · ALL-IN"

	var lbl: Label = Label.new()
	lbl.text = "%s\nFichas %d · Apuesta %d" % [nombre, j.fichas, j.apuesta_actual]
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if es_ganador:
		lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	elif j == actual:
		lbl.add_theme_color_override("font_color", Color.YELLOW)
	fila.add_child(lbl)

	# Al terminar la mano se ven las cartas de quienes llegaron al final
	if fin and j.en_mano:
		for c in j.mano.obtener_cartas():
			fila.add_child(CartaUI.crear(c, true, TAM_MINI))
	return tarjeta

# ---------------------------------------------------------------------------
#  Ayudas
# ---------------------------------------------------------------------------
func _limpiar(contenedor: Control) -> void:
	for h in contenedor.get_children():
		contenedor.remove_child(h)
		h.queue_free()
