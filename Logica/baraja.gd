class_name baraja
extends RefCounted

const capacidad := 52

var mazo: Array = []
var ultima_pos := -1

func _init() -> void:
	mazo.resize(capacidad)

func esta_vacia() -> bool:
	return ultima_pos == -1

func esta_llena() -> bool:
	return ultima_pos == capacidad - 1

func cantidad() -> int:
	return ultima_pos + 1

func push(c: Carta) -> bool:
	if esta_llena():
		return false
	ultima_pos += 1
	mazo[ultima_pos] = c
	return true	

func pop() -> Carta:
	if esta_vacia():
		return null
	var c: Carta = mazo[ultima_pos]
	ultima_pos -= 1
	return c

func llenar() -> void:
	var palos := ["picas", "corazones", "diamantes", "treboles"]
	for p in palos:
		for v in range(2,15):
			push(Carta.new(v ,p))
			

func barajar() -> void:
	for i in range(ultima_pos, 0, -1):
		var j := randi_range(0, i)
		var tmp = mazo[i]
		mazo[i] = mazo[j]
		mazo[j] = tmp
