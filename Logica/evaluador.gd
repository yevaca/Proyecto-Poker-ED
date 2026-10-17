class_name Evaluador
extends RefCounted
## Evalua la mejor mano de poker de 5 cartas entre las 5 a 7 recibidas
## (2 de la mano + hasta 5 de la mesa).
##
## Devuelve un PUNTAJE entero: a mayor puntaje, mejor mano. Dos manos con el
## mismo puntaje estan empatadas. El puntaje codifica la categoria y los
## desempates en base 15:  categoria * 15^5 + d1*15^4 + ... + d5.
## Los valores de las cartas van de 2 a 14 (14 = As).

const ALTA := 0
const PAR := 1
const DOBLE_PAR := 2
const TRIO := 3
const ESCALERA := 4
const COLOR := 5
const FULL := 6
const POKER := 7
const ESCALERA_COLOR := 8

const BASE := 15
const DIVISOR_CATEGORIA := 759375 # 15^5

const NOMBRES := [
	"Carta alta", "Par", "Doble par", "Trío", "Escalera",
	"Color", "Full house", "Póker", "Escalera de color"
]


static func evaluar(cartas: Array) -> int:
	var conteo: Array = []
	conteo.resize(15)
	conteo.fill(0)
	var por_palo := {}
	for c in cartas:
		conteo[c.valor] += 1
		if not por_palo.has(c.palo):
			por_palo[c.palo] = []
		por_palo[c.palo].append(c.valor)

	# Valores del palo con 5 o mas cartas (color), de mayor a menor.
	var valores_color: Array = []
	for palo in por_palo:
		if por_palo[palo].size() >= 5:
			valores_color = por_palo[palo].duplicate()
			valores_color.sort()
			valores_color.reverse()

	if valores_color.size() >= 5:
		var alta_ec := _alta_escalera(valores_color)
		if alta_ec > 0:
			return _codificar(ESCALERA_COLOR, [alta_ec])

	var cuatro := _al_menos(conteo, 4)
	if not cuatro.is_empty():
		var kicker := _mejores_excluyendo(conteo, [cuatro[0]], 1)
		return _codificar(POKER, [cuatro[0]] + kicker)

	var tercias := _al_menos(conteo, 3)
	var pares := _al_menos(conteo, 2)
	if not tercias.is_empty():
		var t: int = tercias[0]
		for p in pares:
			if p != t:
				return _codificar(FULL, [t, p])

	if valores_color.size() >= 5:
		return _codificar(COLOR, valores_color.slice(0, 5))

	var alta_e := _alta_escalera(_al_menos(conteo, 1))
	if alta_e > 0:
		return _codificar(ESCALERA, [alta_e])

	if not tercias.is_empty():
		var t2: int = tercias[0]
		return _codificar(TRIO, [t2] + _mejores_excluyendo(conteo, [t2], 2))

	if pares.size() >= 2:
		var kick := _mejores_excluyendo(conteo, [pares[0], pares[1]], 1)
		return _codificar(DOBLE_PAR, [pares[0], pares[1]] + kick)

	if pares.size() == 1:
		return _codificar(PAR, [pares[0]] + _mejores_excluyendo(conteo, [pares[0]], 3))

	return _codificar(ALTA, _mejores_excluyendo(conteo, [], 5))


static func categoria(puntaje: int) -> int:
	return puntaje / DIVISOR_CATEGORIA


static func nombre_categoria(puntaje: int) -> String:
	return NOMBRES[categoria(puntaje)]


## Valores con `n` o mas cartas, de mayor a menor.
static func _al_menos(conteo: Array, n: int) -> Array:
	var resultado: Array = []
	for v in range(14, 1, -1):
		if conteo[v] >= n:
			resultado.append(v)
	return resultado


## Los `n` valores mas altos presentes que no esten en `excluir`.
static func _mejores_excluyendo(conteo: Array, excluir: Array, n: int) -> Array:
	var resultado: Array = []
	for v in range(14, 1, -1):
		if resultado.size() == n:
			break
		if conteo[v] > 0 and not excluir.has(v):
			resultado.append(v)
	return resultado


## Carta mas alta de la mejor escalera entre los valores dados (0 si no hay).
## El As tambien cuenta como 1 (escalera A-2-3-4-5, cuya carta alta es 5).
static func _alta_escalera(valores: Array) -> int:
	var presentes: Array = []
	presentes.resize(15)
	presentes.fill(false)
	for v in valores:
		presentes[v] = true
	if presentes[14]:
		presentes[1] = true
	for alta in range(14, 4, -1):
		var completa := true
		for k in range(5):
			if not presentes[alta - k]:
				completa = false
				break
		if completa:
			return alta
	return 0


static func _codificar(cat: int, desempates: Array) -> int:
	var puntaje := cat
	for i in range(5):
		var d: int = desempates[i] if i < desempates.size() else 0
		puntaje = puntaje * BASE + d
	return puntaje
