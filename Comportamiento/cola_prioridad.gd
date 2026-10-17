class_name ColaPrioridad
extends RefCounted
## Cola con prioridad implementada como LISTA ENLAZADA ORDENADA.
##
## Se usa en el SHOWDOWN y en los BOTES LATERALES:
##   - Showdown: prioridad = puntaje de la mano, sale primero el MEJOR.
##   - Botes laterales: prioridad = lo aportado a la mano, sale primero el MENOR.
##
## insertar() es O(n) (recorre hasta su posicion), desencolar() y
## ver_frente() son O(1): el mejor siempre esta en la cabeza. Con maximo 9
## jugadores el O(n) es irrelevante.
## Los empates conservan el orden de llegada (es estable).

class Nodo:
	var dato
	var prioridad: int
	var siguiente: Nodo = null

	func _init(d, p: int) -> void:
		dato = d
		prioridad = p


var _cabeza: Nodo = null
var _cantidad := 0
var _mayor_primero: bool


## mayor_primero = true: sale primero la prioridad mas ALTA.
## mayor_primero = false: sale primero la prioridad mas BAJA.
func _init(mayor_primero: bool = true) -> void:
	_mayor_primero = mayor_primero


func esta_vacia() -> bool:
	return _cantidad == 0


func tamano() -> int:
	return _cantidad


## `a` va estrictamente antes que `b`.
func _va_antes(a: int, b: int) -> bool:
	if _mayor_primero:
		return a > b
	return a < b


func insertar(dato, prioridad: int) -> void:
	var nuevo := Nodo.new(dato, prioridad)
	if _cabeza == null or _va_antes(prioridad, _cabeza.prioridad):
		nuevo.siguiente = _cabeza
		_cabeza = nuevo
	else:
		var actual: Nodo = _cabeza
		while actual.siguiente != null and not _va_antes(prioridad, actual.siguiente.prioridad):
			actual = actual.siguiente
		nuevo.siguiente = actual.siguiente
		actual.siguiente = nuevo
	_cantidad += 1


func ver_frente():
	if _cabeza == null:
		return null
	return _cabeza.dato


func ver_prioridad_frente() -> int:
	if _cabeza == null:
		return -1
	return _cabeza.prioridad


func desencolar():
	if _cabeza == null:
		return null
	var dato = _cabeza.dato
	_cabeza = _cabeza.siguiente
	_cantidad -= 1
	return dato
