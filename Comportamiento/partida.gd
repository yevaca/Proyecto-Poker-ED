class_name Partida
extends RefCounted
## Logica completa de una partida de Texas Hold'em. No depende de nodos ni de
## la interfaz: el GameManager solo llama a sus metodos y escucha sus senales.
##
## ESTRUCTURAS LINEALES:
##   - ColaCircular   -> `turnos`: orden de los jugadores en la mesa. El jugador
##                       actual es el del frente; al actuar se rota (desencolar +
##                       encolar). Nadie sale de la cola: fold y eliminacion se
##                       manejan con las banderas del Jugador.
##   - Baraja (pila)  -> `baraja`: se reparte con pop(), solo se toca la cima.
##   - ColaPrioridad  -> showdown (mejor mano primero) y botes laterales
##                       (menor aporte primero).
##
## FLUJO DE UNA MANO:
##   iniciar_mano() -> acciones de los jugadores (accion_fold, accion_igualar,
##   accion_subir, accion_all_in) hasta que la fase llega a FIN_MANO.

signal turno_cambiado(jugador: Jugador)
signal fase_cambiada(fase: int)
signal mano_terminada(resultados: Array)

enum Fase { PREFLOP, FLOP, TURN, RIVER, SHOWDOWN, FIN_MANO }

const MAX_JUGADORES := 9

var jugadores: Array = []       # todos los jugadores (para mostrarlos en la UI)
var turnos: ColaCircular
var baraja: Baraja
var mesa: Cartas_mesa
var bote: Bote
var fase: int = Fase.FIN_MANO
var dealer: Jugador = null
var ciega_pequena: int
var ciega_grande: int
var incremento_minimo: int      # minimo que se debe subir sobre la apuesta actual

## Resultado de la ultima mano: un diccionario por bote repartido:
## {"monto": int, "ganadores": Array[Jugador], "categoria": String}
var resultados: Array = []

var _puntajes := {}             # Jugador -> puntaje de su mano (solo en showdown)


func _init(nombres: Array, fichas_iniciales: int, c_pequena: int = 10, c_grande: int = 20) -> void:
	assert(nombres.size() >= 2 and nombres.size() <= MAX_JUGADORES)
	ciega_pequena = c_pequena
	ciega_grande = c_grande
	incremento_minimo = c_grande
	turnos = ColaCircular.new(MAX_JUGADORES)
	for n in nombres:
		var j := Jugador.new(n, fichas_iniciales)
		jugadores.append(j)
		turnos.encolar(j)
	baraja = Baraja.new()
	mesa = Cartas_mesa.new()
	bote = Bote.new()


# ============================================================================
#  Consultas
# ============================================================================

func jugador_actual() -> Jugador:
	if fase == Fase.SHOWDOWN or fase == Fase.FIN_MANO:
		return null
	return turnos.ver_frente()


func monto_para_igualar(j: Jugador) -> int:
	return mini(bote.falta_para_igualar(j), j.fichas)


func puede_hacer_check(j: Jugador) -> bool:
	return bote.falta_para_igualar(j) == 0


## Apuesta total minima (en esta ronda) para que una subida sea valida.
func subida_minima() -> int:
	return bote.apuesta_actual + incremento_minimo


func hay_ganador_partida() -> bool:
	return _contar_en_partida() <= 1


func ganador_partida() -> Jugador:
	for j in jugadores:
		if j.en_partida:
			return j
	return null


func nombre_fase() -> String:
	match fase:
		Fase.PREFLOP: return "preflop"
		Fase.FLOP: return "flop"
		Fase.TURN: return "turn"
		Fase.RIVER: return "river"
		Fase.SHOWDOWN: return "showdown"
	return "fin de la mano"


# ============================================================================
#  Inicio de la mano
# ============================================================================

## Devuelve false si no quedan al menos 2 jugadores en la partida.
func iniciar_mano() -> bool:
	if _contar_en_partida() < 2:
		return false
	resultados = []
	_puntajes = {}
	mesa.limpiar()
	bote.reiniciar()
	for j in jugadores:
		j.nueva_mano()

	baraja = Baraja.new()
	baraja.llenar()
	baraja.barajar()

	_mover_dealer()
	_repartir_cartas()
	_poner_ciegas()

	fase = Fase.PREFLOP
	fase_cambiada.emit(fase)
	_continuar()
	return true


## El boton del dealer avanza un asiento (rotar la cola) hasta el siguiente
## jugador que sigue en la partida.
func _mover_dealer() -> void:
	if dealer != null:
		_rotar_hasta(dealer)
		turnos.rotar()
	for i in range(turnos.tamano()):
		var f: Jugador = turnos.ver_frente()
		if f.en_partida:
			break
		turnos.rotar()
	dealer = turnos.ver_frente()


## Jugadores que siguen en la partida, empezando por el de la izquierda del
## dealer. Deja el frente de la cola en ese primer jugador.
func _orden_desde_dealer() -> Array:
	_rotar_hasta(dealer)
	turnos.rotar()
	var orden: Array = []
	for j in turnos.a_arreglo():
		if j.en_partida:
			orden.append(j)
	return orden


## Dos cartas a cada jugador, de a una por vuelta, sacadas de la pila.
func _repartir_cartas() -> void:
	var orden := _orden_desde_dealer()
	for vuelta in range(2):
		for j in orden:
			j.mano.agregar(baraja.pop())


func _poner_ciegas() -> void:
	var orden := _orden_desde_dealer()
	var sb: Jugador
	var bb: Jugador
	if orden.size() == 2:
		# Cara a cara: el dealer pone la ciega pequena.
		sb = dealer
		bb = orden[0]
	else:
		sb = orden[0]
		bb = orden[1]
	bote.recibir(sb, mini(ciega_pequena, sb.fichas))
	bote.recibir(bb, mini(ciega_grande, bb.fichas))
	incremento_minimo = ciega_grande
	# Empieza a actuar el siguiente a la ciega grande.
	_rotar_hasta(bb)
	turnos.rotar()


# ============================================================================
#  Acciones de los jugadores (las llama la interfaz)
# ============================================================================

func accion_fold() -> bool:
	var j := jugador_actual()
	if j == null:
		return false
	j.retirarse()
	j.ha_actuado = true
	_cerrar_turno()
	return true


## Check si no hay nada que igualar, o call en caso contrario (si no alcanzan
## las fichas, queda all-in por lo que tenga).
func accion_igualar() -> bool:
	var j := jugador_actual()
	if j == null:
		return false
	bote.igualar(j)
	j.ha_actuado = true
	_cerrar_turno()
	return true


## Sube la apuesta de la ronda a `total` (apuesta total del jugador en esta
## ronda, no lo que agrega). Debe ser al menos subida_minima(), salvo que sea
## todas sus fichas.
func accion_subir(total: int) -> bool:
	var j := jugador_actual()
	if j == null:
		return false
	var maximo := j.apuesta_actual + j.fichas
	if total > maximo or total <= bote.apuesta_actual:
		return false
	if total < subida_minima() and total != maximo:
		return false
	_aplicar_apuesta(j, total - j.apuesta_actual)
	_cerrar_turno()
	return true


func accion_all_in() -> bool:
	var j := jugador_actual()
	if j == null:
		return false
	_aplicar_apuesta(j, j.fichas)
	_cerrar_turno()
	return true


func _aplicar_apuesta(j: Jugador, monto: int) -> void:
	var antes := bote.apuesta_actual
	bote.recibir(j, monto)
	j.ha_actuado = true
	if bote.apuesta_actual > antes:
		# Fue una subida: los demas deben volver a responder.
		incremento_minimo = maxi(incremento_minimo, bote.apuesta_actual - antes)
		for otro in jugadores:
			if otro != j:
				otro.ha_actuado = false


## El jugador ya actuo: se desencola y se vuelve a encolar al final (rotar),
## asi el frente pasa al siguiente jugador.
func _cerrar_turno() -> void:
	turnos.rotar()
	_continuar()


# ============================================================================
#  Avance del juego
# ============================================================================

## Decide que sigue: terminar la mano, pasar de fase o esperar al siguiente
## jugador. Es un ciclo porque si todos estan all-in se reparten las cartas
## restantes sin pedir mas acciones.
func _continuar() -> void:
	while true:
		if _contar_en_mano() <= 1:
			_terminar_sin_showdown()
			return
		if not _ronda_completa():
			_saltar_a_quien_actua()
			return
		if fase == Fase.RIVER:
			_showdown()
			return
		_avanzar_fase()


## Deja al frente de la cola al primer jugador que puede actuar, saltando a los
## que hicieron fold, estan all-in o fueron eliminados.
func _saltar_a_quien_actua() -> void:
	for i in range(turnos.tamano()):
		var f: Jugador = turnos.ver_frente()
		if f.en_mano and f.puede_actuar:
			turno_cambiado.emit(f)
			return
		turnos.rotar()


## La ronda de apuestas termina cuando todos los que pueden actuar ya actuaron
## y tienen igualada la apuesta mas alta. Si solo queda uno que pueda actuar
## (los demas all-in o retirados) basta con que haya igualado.
func _ronda_completa() -> bool:
	var activos: Array = []
	for j in jugadores:
		if j.en_mano and j.puede_actuar:
			activos.append(j)
	if activos.is_empty():
		return true
	if activos.size() == 1:
		return activos[0].apuesta_actual >= bote.apuesta_actual
	for j in activos:
		if not j.ha_actuado or j.apuesta_actual < bote.apuesta_actual:
			return false
	return true


## Pasa a la siguiente fase: quema una carta y destapa las de la mesa.
func _avanzar_fase() -> void:
	for j in jugadores:
		j.ha_actuado = false
	bote.nueva_ronda(jugadores)
	incremento_minimo = ciega_grande
	baraja.pop() # carta quemada
	var cantidad := 1
	match fase:
		Fase.PREFLOP:
			cantidad = 3
			fase = Fase.FLOP
		Fase.FLOP:
			fase = Fase.TURN
		Fase.TURN:
			fase = Fase.RIVER
	for i in range(cantidad):
		mesa.agregar(baraja.pop())
	fase_cambiada.emit(fase)
	# Despues del flop empieza el primero a la izquierda del dealer.
	_rotar_hasta(dealer)
	turnos.rotar()


## Deja al jugador `j` al frente de la cola.
func _rotar_hasta(j: Jugador) -> void:
	for i in range(turnos.tamano()):
		if turnos.ver_frente() == j:
			return
		turnos.rotar()


# ============================================================================
#  Fin de la mano: showdown y botes
# ============================================================================

## Todos menos uno se retiraron: el que queda se lleva todo sin mostrar cartas.
func _terminar_sin_showdown() -> void:
	var ganador: Jugador = null
	for j in jugadores:
		if j.en_mano:
			ganador = j
	var monto := bote.total
	bote.repartir(monto, [ganador])
	resultados = [{"monto": monto, "ganadores": [ganador], "categoria": ""}]
	_finalizar_mano()


func _showdown() -> void:
	fase = Fase.SHOWDOWN
	fase_cambiada.emit(fase)
	var comunitarias := mesa.obtener_cartas()
	for j in jugadores:
		if j.en_mano:
			_puntajes[j] = Evaluador.evaluar(j.mano.obtener_cartas() + comunitarias)
	_repartir_botes()
	_finalizar_mano()


## Botes laterales con una cola con prioridad: se encolan los jugadores con su
## aporte total (sale primero el que menos puso). Cada vez que sale uno se
## cierra un bote: (aporte - nivel anterior) por cada jugador que aun no habia
## salido. Pueden ganarlo solo los que siguen en la mano y aportaron al menos
## ese nivel.
##
## Ejemplo: A puso 50 (all-in), B 150 (all-in), C 150.
##   sale A (50): bote principal 50 x 3 = 150  -> compiten A, B, C
##   sale B (150): bote lateral 100 x 2 = 200  -> compiten B, C
##   sale C (150): mismo nivel, bote de 0, se ignora.
func _repartir_botes() -> void:
	var orden := _orden_desde_dealer()
	var por_aporte := ColaPrioridad.new(false) # sale primero el menor
	for j in orden:
		if j.aporte_total > 0:
			por_aporte.insertar(j, j.aporte_total)

	var nivel_previo := 0
	var acarreo := 0 # dinero de un nivel sin ningun jugador con derecho a el
	while not por_aporte.esta_vacia():
		var contribuyentes := por_aporte.tamano()
		var nivel: int = por_aporte.ver_prioridad_frente()
		por_aporte.desencolar()
		var base := (nivel - nivel_previo) * contribuyentes
		nivel_previo = nivel
		if base == 0:
			continue
		var monto := base + acarreo

		var elegibles: Array = []
		for j in orden:
			if j.en_mano and j.aporte_total >= nivel:
				elegibles.append(j)
		if elegibles.is_empty():
			acarreo = monto
			continue
		acarreo = 0

		var ganadores := _ganadores_de(elegibles)
		bote.repartir(monto, ganadores)
		resultados.append({
			"monto": monto,
			"ganadores": ganadores,
			"categoria": Evaluador.nombre_categoria(_puntajes[ganadores[0]]),
		})

	if acarreo > 0 and not resultados.is_empty():
		var ultimo: Dictionary = resultados.back()
		bote.repartir(acarreo, ultimo["ganadores"])
		ultimo["monto"] += acarreo


## Showdown con una cola con prioridad: se encolan los jugadores con el puntaje
## de su mano (sale primero el mejor). Se sacan mientras tengan el mismo
## puntaje que el primero: ese es el empate y se reparte el bote.
func _ganadores_de(elegibles: Array) -> Array:
	var por_mano := ColaPrioridad.new(true) # sale primero el mayor
	for j in elegibles:
		por_mano.insertar(j, _puntajes[j])
	var mejor := por_mano.ver_prioridad_frente()
	var ganadores: Array = []
	while not por_mano.esta_vacia() and por_mano.ver_prioridad_frente() == mejor:
		ganadores.append(por_mano.desencolar())
	return ganadores


func _finalizar_mano() -> void:
	fase = Fase.FIN_MANO
	for j in jugadores:
		if j.en_partida and j.fichas == 0:
			j.en_partida = false # eliminado de la partida
			j.puede_actuar = false
	fase_cambiada.emit(fase)
	mano_terminada.emit(resultados)


# ============================================================================
#  Conteos
# ============================================================================

func _contar_en_partida() -> int:
	var n := 0
	for j in jugadores:
		if j.en_partida:
			n += 1
	return n


func _contar_en_mano() -> int:
	var n := 0
	for j in jugadores:
		if j.en_mano:
			n += 1
	return n
