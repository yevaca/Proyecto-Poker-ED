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

## Paga TODO el bote a los ganadores (se divide en partes iguales).
func pagar(ganadores: Array) -> void:
	repartir(total, ganadores)


## Reparte `monto` entre los ganadores y lo descuenta del bote. Si no se
## divide exacto, las fichas sobrantes van al primero de la lista.
## Se usa con cada bote lateral por separado.
func repartir(monto: int, ganadores: Array) -> void:
	if ganadores.is_empty() or monto <= 0:
		return
	var n: int = ganadores.size()
	var parte: int = monto / n
	var resto: int = monto - parte * n
	for g in ganadores:
		g.fichas += parte
	ganadores[0].fichas += resto
	total -= monto

func reiniciar() -> void:
	total = 0
	apuesta_actual = 0
