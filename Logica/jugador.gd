class_name Jugador 
extends RefCounted

var nombre: String
var fichas: int
var mano: Mano
var apuesta_actual := 0
var activo := true

func _init(n:String, f:int) -> void:
	nombre = n
	fichas = f
	mano = mano.new()

func apostar(monto:int) -> bool:
	if monto > fichas: 
		return false
	fichas -= monto
	apuesta_actual += monto
	return true

func reiniciar_apuesta() -> void:
	apuesta_actual = 0

func retirarse() -> void:
	activo = false
