class_name jugador 
extends RefCounted

var nombre: String
var fichas: int
var mano: mano
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

func retirarse() -> void:
	activo = false
