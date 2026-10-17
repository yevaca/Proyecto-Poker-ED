class_name Jugador
extends RefCounted

var nombre: String
var fichas: int
var mano: Mano

## Lo apostado en la ronda de apuestas actual (se reinicia en cada ronda).
var apuesta_actual := 0
## Lo aportado en TODA la mano. Sirve para calcular los botes laterales.
var aporte_total := 0

# --- Estado del jugador ---
## false cuando se queda sin fichas: sale de la PARTIDA para siempre.
var en_partida := true
## false cuando hace fold: sale de la MANO actual (no puede ganar el bote).
var en_mano := true
## false si hizo fold, esta all-in o esta eliminado: no puede tomar acciones
## y se le salta el turno. OJO: un jugador all-in tiene puede_actuar = false
## pero en_mano = true, porque SI participa en el showdown.
var puede_actuar := true
## Ya actuo en la ronda de apuestas actual (para saber cuando termina la ronda).
var ha_actuado := false


func _init(n: String, f: int) -> void:
	nombre = n
	fichas = f
	mano = Mano.new()


func apostar(monto: int) -> bool:
	if monto < 0 or monto > fichas:
		return false
	fichas -= monto
	apuesta_actual += monto
	aporte_total += monto
	if fichas == 0:
		puede_actuar = false # all-in
	return true


func reiniciar_apuesta() -> void:
	apuesta_actual = 0


## Fold: se retira de esta mano, pero sigue sentado en la mesa (en_partida).
func retirarse() -> void:
	en_mano = false
	puede_actuar = false


func esta_all_in() -> bool:
	return en_mano and fichas == 0


## Prepara al jugador para una mano nueva. Los eliminados no juegan.
func nueva_mano() -> void:
	mano.limpiar()
	apuesta_actual = 0
	aporte_total = 0
	ha_actuado = false
	en_mano = en_partida
	puede_actuar = en_partida
