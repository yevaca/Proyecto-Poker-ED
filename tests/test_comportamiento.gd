extends SceneTree
## Pruebas de la logica del juego. Se ejecutan sin abrir el editor:
##   godot --headless --path . --script res://tests/test_comportamiento.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla.

var fallos := 0
var pruebas := 0


func _init() -> void:
	test_cola_circular()
	test_cola_prioridad()
	test_evaluador()
	test_ciegas_y_turnos()
	test_opcion_ciega_grande()
	test_dealer_rota()
	test_botes_laterales()
	test_simulacion_aleatoria()
	print("")
	print("Pruebas: %d, fallos: %d" % [pruebas, fallos])
	quit(1 if fallos > 0 else 0)


func check(condicion: bool, mensaje: String) -> void:
	pruebas += 1
	if not condicion:
		fallos += 1
		print("FALLO: ", mensaje)


func c(valor: int, palo: String) -> Carta:
	return Carta.new(valor, palo)


# ----------------------------------------------------------------------------
func test_cola_circular() -> void:
	var q := ColaCircular.new(3)
	check(q.esta_vacia(), "cola nueva vacia")
	check(q.desencolar() == null, "desencolar vacia devuelve null")
	q.encolar("a"); q.encolar("b"); q.encolar("c")
	check(q.esta_llena(), "cola llena")
	check(not q.encolar("d"), "no se puede encolar en cola llena")
	check(q.desencolar() == "a", "FIFO: sale a")
	check(q.encolar("d"), "reutiliza el hueco (da la vuelta)")
	check(q.a_arreglo() == ["b", "c", "d"], "orden tras dar la vuelta")
	q.rotar()
	check(q.a_arreglo() == ["c", "d", "b"], "rotar manda el frente al final")
	check(q.ver_frente() == "c", "ver_frente")
	check(q.tamano() == 3, "tamano tras rotar")
	for i in range(10):
		q.rotar()
	check(q.a_arreglo() == ["d", "b", "c"], "muchas rotaciones siguen coherentes")


func test_cola_prioridad() -> void:
	var q := ColaPrioridad.new(true)
	q.insertar("x", 5); q.insertar("y", 9); q.insertar("z", 5); q.insertar("w", 1)
	check(q.ver_prioridad_frente() == 9, "mayor primero")
	var salida: Array = []
	while not q.esta_vacia():
		salida.append(q.desencolar())
	check(salida == ["y", "x", "z", "w"], "orden por prioridad, empates por llegada: %s" % [salida])
	var m := ColaPrioridad.new(false)
	m.insertar("a", 50); m.insertar("b", 150); m.insertar("c", 150); m.insertar("d", 20)
	salida = []
	while not m.esta_vacia():
		salida.append(m.desencolar())
	check(salida == ["d", "a", "b", "c"], "menor primero: %s" % [salida])
	check(m.desencolar() == null, "desencolar vacia devuelve null")


func test_evaluador() -> void:
	var esc_color := Evaluador.evaluar([c(9, "corazones"), c(8, "corazones"), c(7, "corazones"), c(6, "corazones"), c(5, "corazones"), c(2, "treboles"), c(3, "picas")])
	var poker := Evaluador.evaluar([c(10, "picas"), c(10, "corazones"), c(10, "treboles"), c(10, "diamantes"), c(14, "picas"), c(3, "picas"), c(2, "treboles")])
	var full := Evaluador.evaluar([c(3, "picas"), c(3, "corazones"), c(3, "treboles"), c(2, "diamantes"), c(2, "picas"), c(13, "picas"), c(9, "treboles")])
	var color := Evaluador.evaluar([c(14, "picas"), c(10, "picas"), c(8, "picas"), c(5, "picas"), c(3, "picas"), c(13, "corazones"), c(13, "treboles")])
	var escalera := Evaluador.evaluar([c(5, "picas"), c(6, "corazones"), c(7, "treboles"), c(8, "diamantes"), c(9, "picas"), c(9, "corazones"), c(13, "treboles")])
	var trio := Evaluador.evaluar([c(7, "picas"), c(7, "corazones"), c(7, "treboles"), c(2, "diamantes"), c(9, "picas"), c(12, "corazones"), c(13, "treboles")])
	var doble := Evaluador.evaluar([c(7, "picas"), c(7, "corazones"), c(5, "treboles"), c(5, "diamantes"), c(9, "picas"), c(9, "corazones"), c(13, "treboles")])
	var par := Evaluador.evaluar([c(7, "picas"), c(7, "corazones"), c(5, "treboles"), c(2, "diamantes"), c(9, "picas"), c(11, "corazones"), c(13, "treboles")])
	var alta := Evaluador.evaluar([c(14, "picas"), c(7, "corazones"), c(5, "treboles"), c(2, "diamantes"), c(9, "picas"), c(11, "corazones"), c(13, "treboles")])
	check(Evaluador.categoria(esc_color) == Evaluador.ESCALERA_COLOR, "escalera de color")
	check(Evaluador.categoria(poker) == Evaluador.POKER, "poker")
	check(Evaluador.categoria(full) == Evaluador.FULL, "full house")
	check(Evaluador.categoria(color) == Evaluador.COLOR, "color")
	check(Evaluador.categoria(escalera) == Evaluador.ESCALERA, "escalera con carta repetida")
	check(Evaluador.categoria(trio) == Evaluador.TRIO, "trio")
	check(Evaluador.categoria(doble) == Evaluador.DOBLE_PAR, "doble par (con tres pares)")
	check(Evaluador.categoria(par) == Evaluador.PAR, "par")
	check(Evaluador.categoria(alta) == Evaluador.ALTA, "carta alta")
	check(esc_color > poker and poker > full and full > color and color > escalera and escalera > trio and trio > doble and doble > par and par > alta, "orden de categorias")

	# Escalera con As bajo (rueda) pierde contra escalera a 6.
	var rueda := Evaluador.evaluar([c(14, "picas"), c(2, "corazones"), c(3, "treboles"), c(4, "diamantes"), c(5, "picas"), c(13, "corazones"), c(9, "treboles")])
	var seis := Evaluador.evaluar([c(2, "picas"), c(3, "corazones"), c(4, "treboles"), c(5, "diamantes"), c(6, "picas"), c(13, "corazones"), c(9, "treboles")])
	check(Evaluador.categoria(rueda) == Evaluador.ESCALERA, "rueda es escalera")
	check(seis > rueda, "escalera a 6 gana a la rueda")

	# Desempates por kicker y empates reales.
	var aa_k := Evaluador.evaluar([c(14, "picas"), c(14, "corazones"), c(13, "treboles"), c(9, "diamantes"), c(7, "picas"), c(4, "corazones"), c(2, "treboles")])
	var aa_q := Evaluador.evaluar([c(14, "treboles"), c(14, "diamantes"), c(12, "treboles"), c(9, "picas"), c(7, "corazones"), c(4, "diamantes"), c(2, "picas")])
	check(aa_k > aa_q, "mismo par, gana el mejor kicker")
	var t1 := Evaluador.evaluar([c(14, "picas"), c(13, "corazones"), c(10, "treboles"), c(9, "diamantes"), c(7, "picas")])
	var t2 := Evaluador.evaluar([c(14, "corazones"), c(13, "picas"), c(10, "diamantes"), c(9, "treboles"), c(7, "corazones")])
	check(t1 == t2, "empate real con palos distintos")
	var full_alto := Evaluador.evaluar([c(5, "picas"), c(5, "corazones"), c(5, "treboles"), c(4, "diamantes"), c(4, "picas"), c(4, "corazones"), c(2, "treboles")])
	check(Evaluador.categoria(full_alto) == Evaluador.FULL, "dos tercias forman full")


# ----------------------------------------------------------------------------
func test_ciegas_y_turnos() -> void:
	var p := Partida.new(["A", "B", "C", "D"], 1000, 10, 20)
	p.iniciar_mano()
	var j: Array = p.jugadores
	check(p.dealer == j[0], "primer dealer es el primer jugador")
	check(j[1].apuesta_actual == 10 and j[2].apuesta_actual == 20, "ciegas: B pequena, C grande")
	check(p.jugador_actual() == j[3], "empieza el siguiente a la ciega grande")
	check(p.bote.total == 30, "bote con ciegas")
	for x in j:
		check(x.mano.cantidad == 2, "cada jugador tiene 2 cartas")
	check(p.baraja.cantidad() == 52 - 8, "la pila perdio 8 cartas")
	p.accion_fold()
	check(p.jugador_actual() == j[0], "tras D sigue A")
	check(not j[3].en_mano and j[3].en_partida, "fold: sale de la mano pero sigue en la partida")
	p.accion_igualar()
	check(p.jugador_actual() == j[1], "sigue B")
	check(p.turnos.tamano() == 4, "nadie sale de la cola")

	# Heads-up: el dealer es la ciega pequena y actua primero.
	var h := Partida.new(["X", "Y"], 500, 10, 20)
	h.iniciar_mano()
	check(h.jugadores[0].apuesta_actual == 10 and h.jugadores[1].apuesta_actual == 20, "heads-up: dealer pone la ciega pequena")
	check(h.jugador_actual() == h.jugadores[0], "heads-up: el dealer actua primero")


func test_opcion_ciega_grande() -> void:
	var p := Partida.new(["A", "B", "C"], 1000, 10, 20)
	p.iniciar_mano()
	p.accion_igualar() # A (UTG) iguala 20
	p.accion_igualar() # B (ciega pequena) completa
	check(p.fase == Partida.Fase.PREFLOP, "la ciega grande aun tiene su opcion")
	check(p.jugador_actual() == p.jugadores[2], "le toca a la ciega grande")
	p.accion_igualar() # check
	check(p.fase == Partida.Fase.FLOP, "pasa al flop")
	check(p.mesa.cantidad == 3, "3 cartas en el flop")
	check(p.jugador_actual() == p.jugadores[1], "post-flop empieza la izquierda del dealer")
	check(p.bote.total == 60, "bote tras preflop")
	check(not p.accion_subir(10), "subida menor que la minima es invalida")
	check(p.accion_subir(40), "subida valida")
	check(p.jugador_actual() == p.jugadores[2], "turno al siguiente tras subir")


func test_dealer_rota() -> void:
	var p := Partida.new(["A", "B", "C", "D"], 1000, 10, 20)
	for esperado in [0, 1, 2, 3, 0]:
		p.iniciar_mano()
		check(p.dealer == p.jugadores[esperado], "dealer en la mano esperada %d" % esperado)
		while p.fase != Partida.Fase.FIN_MANO:
			p.accion_fold()
	var total := 0
	for j in p.jugadores:
		total += j.fichas
	check(total == 4000, "fichas conservadas")


func _preparar_showdown(p: Partida, datos: Array) -> void:
	# datos: [[aporte, en_mano, carta1, carta2], ...] por jugador
	p.dealer = p.jugadores[0]
	p.fase = Partida.Fase.RIVER
	p.mesa.limpiar()
	for carta in [c(2, "treboles"), c(7, "diamantes"), c(9, "corazones"), c(11, "picas"), c(3, "treboles")]:
		p.mesa.agregar(carta)
	var total := 0
	for i in range(datos.size()):
		var j: Jugador = p.jugadores[i]
		j.mano.limpiar()
		j.fichas = 0
		j.aporte_total = datos[i][0]
		j.en_mano = datos[i][1]
		j.en_partida = true
		j.mano.agregar(datos[i][2])
		j.mano.agregar(datos[i][3])
		total += datos[i][0]
	p.bote.reiniciar()
	p.bote.total = total


func test_botes_laterales() -> void:
	# A (50, mejor mano), B (150, segunda), C (150, tercera).
	var p := Partida.new(["A", "B", "C"], 0, 10, 20)
	_preparar_showdown(p, [
		[50, true, c(14, "picas"), c(14, "diamantes")],
		[150, true, c(13, "picas"), c(13, "diamantes")],
		[150, true, c(12, "picas"), c(12, "diamantes")]])
	p._showdown()
	check(p.jugadores[0].fichas == 150, "A gana el bote principal (150), tiene %d" % p.jugadores[0].fichas)
	check(p.jugadores[1].fichas == 200, "B gana el bote lateral (200), tiene %d" % p.jugadores[1].fichas)
	check(p.jugadores[2].fichas == 0, "C no gana nada")
	check(p.bote.total == 0, "bote vacio")
	check(p.resultados.size() == 2, "dos botes repartidos")

	# Empate en el bote lateral entre B y C (mismo par, mismo kicker).
	var q := Partida.new(["A", "B", "C"], 0, 10, 20)
	_preparar_showdown(q, [
		[50, true, c(14, "picas"), c(14, "diamantes")],
		[150, true, c(13, "picas"), c(5, "diamantes")],
		[150, true, c(13, "corazones"), c(5, "treboles")]])
	q._showdown()
	check(q.jugadores[0].fichas == 150, "empate: A gana el principal")
	check(q.jugadores[1].fichas == 100 and q.jugadores[2].fichas == 100, "empate: B y C se dividen el lateral")

	# Un jugador que hizo fold deja sus fichas en el bote pero no puede ganar.
	var r := Partida.new(["A", "B", "C", "D"], 0, 10, 20)
	_preparar_showdown(r, [
		[100, true, c(12, "picas"), c(12, "diamantes")],
		[100, true, c(13, "picas"), c(13, "diamantes")],
		[100, true, c(5, "picas"), c(5, "diamantes")],
		[60, false, c(14, "picas"), c(14, "diamantes")]])
	r._showdown()
	check(r.jugadores[1].fichas == 360, "el mejor entre los que siguen gana todo, incluido lo del fold (%d)" % r.jugadores[1].fichas)
	check(r.jugadores[3].fichas == 0, "el que hizo fold no recibe nada aunque tuviera la mejor mano")

	# Tres botes: A 30, B 80, C 200, D 200.
	var s := Partida.new(["A", "B", "C", "D"], 0, 10, 20)
	_preparar_showdown(s, [
		[30, true, c(14, "picas"), c(14, "diamantes")],
		[80, true, c(13, "picas"), c(13, "diamantes")],
		[200, true, c(12, "picas"), c(12, "diamantes")],
		[200, true, c(5, "picas"), c(5, "diamantes")]])
	s._showdown()
	check(s.jugadores[0].fichas == 120, "A: principal 30x4=120 (%d)" % s.jugadores[0].fichas)
	check(s.jugadores[1].fichas == 150, "B: lateral 50x3=150 (%d)" % s.jugadores[1].fichas)
	check(s.jugadores[2].fichas == 240, "C: lateral 120x2=240 (%d)" % s.jugadores[2].fichas)
	check(s.jugadores[3].fichas == 0, "D no gana")


# ----------------------------------------------------------------------------
func _cartas_unicas(p: Partida) -> bool:
	var vistas := {}
	var todas: Array = p.mesa.obtener_cartas()
	for j in p.jugadores:
		if j.en_mano or p.fase == Partida.Fase.FIN_MANO:
			todas.append_array(j.mano.obtener_cartas())
	for carta in todas:
		var k: String = carta.nombre_sprite()
		if vistas.has(k):
			return false
		vistas[k] = true
	return true


func test_simulacion_aleatoria() -> void:
	seed(20261016)
	var manos_jugadas := 0
	var todas_eliminaciones := 0
	for n in range(2, 10):
		for repeticion in range(4):
			var nombres: Array = []
			for i in range(n):
				nombres.append("J%d" % i)
			var p := Partida.new(nombres, 300, 10, 20)
			var total_fichas := 300 * n
			var manos := 0
			while not p.hay_ganador_partida() and manos < 400:
				manos += 1
				manos_jugadas += 1
				check(p.iniciar_mano(), "iniciar mano")
				var pasos := 0
				while p.fase != Partida.Fase.FIN_MANO and pasos < 300:
					pasos += 1
					var j := p.jugador_actual()
					check(j != null and j.en_mano and j.puede_actuar and j.en_partida, "el jugador actual puede actuar")
					if j == null:
						break
					var suma := p.bote.total
					for x in p.jugadores:
						suma += x.fichas
					check(suma == total_fichas, "conservacion de fichas durante la mano (%d vs %d)" % [suma, total_fichas])
					var azar := randf()
					var ok := false
					if azar < 0.12:
						ok = p.accion_fold()
					elif azar < 0.62:
						ok = p.accion_igualar()
					elif azar < 0.92:
						var total := p.subida_minima() + randi_range(0, 3) * p.ciega_grande
						total = mini(total, j.apuesta_actual + j.fichas)
						ok = p.accion_subir(total)
						if not ok:
							ok = p.accion_igualar()
					else:
						ok = p.accion_all_in()
					check(ok, "la accion fue valida")
				check(p.fase == Partida.Fase.FIN_MANO, "la mano termina (pasos=%d, fase=%s)" % [pasos, p.nombre_fase()])
				check(_cartas_unicas(p), "no hay cartas repetidas")
				var suma_fin := 0
				for x in p.jugadores:
					suma_fin += x.fichas
					check(x.fichas >= 0, "fichas nunca negativas")
				check(suma_fin == total_fichas, "fichas conservadas al final (%d vs %d)" % [suma_fin, total_fichas])
				check(p.bote.total == 0, "bote en cero al terminar (%d)" % p.bote.total)
				check(not p.resultados.is_empty(), "hubo al menos un ganador")
				for r in p.resultados:
					check(not r["ganadores"].is_empty() and r["monto"] > 0, "cada bote repartido tiene ganador")
				for x in p.jugadores:
					check(not (x.en_partida and x.fichas == 0), "sin fichas implica eliminado")
			todas_eliminaciones += n - p._contar_en_partida()
	print("Simulacion: %d manos jugadas, %d eliminaciones" % [manos_jugadas, todas_eliminaciones])
	check(todas_eliminaciones > 0, "la simulacion elimina jugadores")
