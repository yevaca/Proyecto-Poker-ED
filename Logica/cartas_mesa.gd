class_name Cartas_mesa
extends RefCounted

const capacidad := 5

var cartas: Array = []
var cantidad = 0

func _init() -> void:
	cartas.resize(capacidad)

func esta_llena() -> bool: 
	return cantidad == capacidad

func agregar(c: Carta) -> bool:
	if esta_llena():
		return false
	cartas[cantidad] = c
	cantidad += 1
	return true

func obtener_cartas() -> Array:
	var resultado: Array = []
	for i in range(cantidad):
		resultado.append(cartas[i])
	return resultado

func etapa() -> String:
	match cantidad:
		0: return "preflop"
		3: return "flop"
		4: return "turn"
		5: return "river"
	return "invalida"

func limpiar() -> void:
	cantidad = 0
