class_name Bote
extends RefCounted

var total := 0
var apuesta_actual := 0

func recibir(jugador: Jugador, monto: int) -> bool:
	if not jugador.apostar(monto):
		return false
	total += monto
	if jugador.apuesta_actual > apuesta_actual:
		apuesta_actual = jugador.apuesta_actual
	return true

func falta_para_igualar(jugador: Jugador) -> int:
	return apuesta_actual - jugador.apuesta_actual

func igualar(jugador: Jugador) -> bool:
	var falta: int = falta_para_igualar(jugador)
	if falta > jugador.fichas:
		falta = jugador.fichas
	return recibir(jugador, falta)

func nueva_ronda(jugadores: Array) -> void:
	apuesta_actual = 0
	for j in jugadores:
		j.reiniciar_apuesta()

func pagar(ganadores: Array) -> void:
	if ganadores.is_empty():
		return
	var n: int = ganadores.size()
	var parte: int = int(total / float(n))
	var resto: int = total - parte * n
	for g in ganadores:
		g.fichas += parte
	ganadores[0].fichas += resto
	total = 0

func reiniciar() -> void:
	total = 0
	apuesta_actual = 0
