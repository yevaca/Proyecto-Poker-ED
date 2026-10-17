class_name ColaCircular
extends RefCounted
## Cola circular sobre un arreglo de tamano fijo.
##
## Se usa para el ORDEN DE LOS TURNOS: el jugador actual es el que esta al
## frente de la cola. Al terminar su turno se hace desencolar + encolar
## (rotar) y el turno pasa al siguiente, dando la vuelta a la mesa.
##
## El arreglo se redimensiona UNA sola vez en el constructor (se comporta como
## un arreglo estatico). Los indices "dan la vuelta" con el operador modulo.
## Se guardan _frente y _cantidad (en vez de frente y fin) para distinguir sin
## ambiguedad entre cola llena y cola vacia.
##
## Encolar, desencolar, ver_frente y rotar son O(1).

var _datos: Array = []
var _frente := 0
var _cantidad := 0
var _capacidad: int


func _init(capacidad: int = 9) -> void:
	_capacidad = capacidad
	_datos.resize(capacidad)


func esta_vacia() -> bool:
	return _cantidad == 0


func esta_llena() -> bool:
	return _cantidad == _capacidad


func tamano() -> int:
	return _cantidad


## Agrega al final de la fila. Devuelve false si la cola esta llena.
func encolar(elemento) -> bool:
	if esta_llena():
		return false
	var fin := (_frente + _cantidad) % _capacidad
	_datos[fin] = elemento
	_cantidad += 1
	return true


## Saca y devuelve el elemento del frente. Devuelve null si esta vacia.
func desencolar():
	if esta_vacia():
		return null
	var elemento = _datos[_frente]
	_datos[_frente] = null
	_frente = (_frente + 1) % _capacidad
	_cantidad -= 1
	return elemento


## Devuelve el elemento del frente sin sacarlo.
func ver_frente():
	if esta_vacia():
		return null
	return _datos[_frente]


## Pasa el turno: el del frente se va al final de la fila.
func rotar() -> void:
	if esta_vacia():
		return
	encolar(desencolar())


## Copia de los elementos en orden (del frente hacia el final), solo para
## LEER (mostrar la mesa, recorrer asientos). No modifica la cola.
func a_arreglo() -> Array:
	var resultado: Array = []
	for i in range(_cantidad):
		resultado.append(_datos[(_frente + i) % _capacidad])
	return resultado
