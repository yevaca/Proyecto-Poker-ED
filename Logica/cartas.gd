class_name Carta
extends RefCounted

var palo: String
var valor: int

func _init(v: int, p: String) -> void:
	valor = v
	palo = p

func nombre_sprite() -> String:
	return str(valor) + "_" + palo
