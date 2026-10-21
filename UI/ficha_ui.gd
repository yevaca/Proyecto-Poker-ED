class_name FichaUI
extends Control
## Ficha de poker dibujada con codigo.

## [valor, color]: se usan de mayor a menor para representar un monto.
const DENOMINACIONES := [
	[1000, Color(0.85, 0.7, 0.1)],
	[500, Color(0.5, 0.2, 0.6)],
	[100, Color(0.12, 0.12, 0.12)],
	[50, Color(0.15, 0.35, 0.75)],
	[20, Color(0.1, 0.55, 0.25)],
	[10, Color(0.75, 0.15, 0.15)],
	[5, Color(0.85, 0.5, 0.15)],
	[1, Color(0.8, 0.8, 0.8)],
]

var color: Color = Color.RED


static func crear(c: Color, tam: float) -> FichaUI:
	var f: FichaUI = FichaUI.new()
	f.color = c
	f.custom_minimum_size = Vector2(tam, tam)
	f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return f


## Fila de fichas (algo encimadas) que representa un monto.
static func pila(monto: int, tam: float = 26.0, max_fichas: int = 6) -> HBoxContainer:
	var fila: HBoxContainer = HBoxContainer.new()
	fila.add_theme_constant_override("separation", int(-tam * 0.45))
	fila.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var restante: int = monto
	var cuantas: int = 0
	for d in DENOMINACIONES:
		while restante >= d[0] and cuantas < max_fichas:
			fila.add_child(crear(d[1], tam))
			restante -= d[0]
			cuantas += 1
	return fila


func _draw() -> void:
	var centro: Vector2 = size / 2
	var r: float = minf(size.x, size.y) / 2 - 1
	draw_circle(centro, r, Color(0, 0, 0, 0.6))                 # borde
	draw_circle(centro, r - 1.5, color)                         # cuerpo
	draw_arc(centro, r * 0.72, 0, TAU, 32, Color(1, 1, 1, 0.85), maxf(1.5, r * 0.12))
	draw_circle(centro, r * 0.45, color.darkened(0.25))         # centro
