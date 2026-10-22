# Proyecto Poker ED

Juego de póker Texas Hold'em hecho en Godot 4 con GDScript, como proyecto del curso de Estructuras de Datos (Universidad Nacional de Colombia). Pueden jugar de 2 a 9 personas en un mismo computador.

## Autores

- David Santiago Montiel Rodríguez
- David Santiago Toro Arias
- Jean Carlo Triana Guzmán

Docente: Jonatan Gómez Perdomo

## Cómo abrir el juego

Necesitas Godot 4.7, que es gratis y no se instala: se descarga en <https://godotengine.org/download> y se abre directamente.

1. Descarga el proyecto. Con Git: `git clone https://github.com/yevaca/Proyecto-Poker-ED.git`. O en GitHub, botón **Code → Download ZIP**, y descomprime la carpeta.
2. Abre Godot, haz clic en **Importar**, luego en **Examinar**, y elige el archivo `project.godot` de la carpeta del proyecto.
3. Haz clic en **Importar y editar**. La primera vez tarda un poco.
4. Pulsa **F5**. Se abre la pantalla de inicio del juego.

## Manual de usuario

### Pantalla de inicio

Antes de empezar se configura la partida:

- **Jugadores:** de 2 a 9.
- **Nombre de cada jugador:** deben tener nombre y no pueden repetirse.
- **Fichas iniciales:** de 100 a 100000.

Luego se pulsa **JUGAR**.

### La mesa

- Arriba aparece la **fase** de la mano (preflop, flop, turn o river) y el botón **Volver al menú**.
- En el centro está el **bote** y las cartas comunes de la mesa.
- A los lados están las **tarjetas de los jugadores**, con sus fichas y lo que han apostado en la ronda. El jugador al que le toca está resaltado en amarillo, y el dealer está marcado con (D). Los jugadores retirados o eliminados aparecen atenuados.

### Cómo se juega un turno

El juego se hace en un solo computador, así que las cartas de cada jugador están ocultas hasta que le toca.

1. Quien tenga el turno pulsa **Ver mis cartas**, y los demás no deben mirar.
2. Elige una acción:

| Botón | Qué hace |
|---|---|
| Retirarse | Abandona la mano. |
| Pasar (check) o Igualar | Pasa si nadie ha subido, o iguala la apuesta (el botón muestra cuánto cuesta). |
| Subir | Sube la apuesta al monto escrito en el campo de al lado. |
| ALL-IN | Apuesta todas sus fichas. |

3. El turno pasa al siguiente jugador, que debe pulsar **Ver mis cartas**.

Si se intenta una jugada no permitida, aparece el aviso "Jugada no válida" y se puede elegir otra.

### Fin de la mano y de la partida

Cuando termina una mano aparece un cuadro con el resultado: quién ganó, cuánto y con qué combinación. Se pulsa **Siguiente mano** para continuar.

Quien se queda sin fichas queda eliminado. La partida termina cuando solo queda un jugador, y aparece el campeón. Ahí se pulsa **Volver al menú** para empezar otra.

### Reglas básicas

Se juega con las reglas de Texas Hold'em: cada jugador recibe dos cartas privadas, hay cinco cartas comunes y gana la mejor combinación de cinco cartas. Las ciegas son de 10 y 20 fichas. Si un jugador hace all-in con menos fichas que los demás, solo puede ganar hasta lo que aportó, y el resto se juega en un bote aparte entre los demás.

## Estructuras de datos usadas

El proyecto usa tres estructuras lineales, cada una en la parte del juego donde resuelve un problema real:

| Estructura | Para qué se usa | Archivo |
|---|---|---|
| Cola circular | El orden de los turnos: cuando juega el último jugador, vuelve a empezar el primero | `Comportamiento/cola_circular.gd` |
| Pila | El mazo de cartas: solo se puede tomar la carta de arriba | `Logica/baraja.gd` |
| Cola con prioridad | Decidir quién gana en el showdown y repartir los botes laterales, ordenando por fuerza de mano o por lo aportado | `Comportamiento/cola_prioridad.gd` |

La explicación detallada de por qué y cómo se usó cada una está en el documento de la entrega.

## Estructura del proyecto

```
Logica/            Clases base: carta, baraja (pila), mano, jugador, bote, cartas de la mesa
Comportamiento/    Reglas del juego: cola circular, cola con prioridad, evaluador de manos, partida
UI/                Interfaz: pantalla de inicio y mesa
tests/             Pruebas de la lógica del juego
```

## Pruebas

La lógica del juego tiene pruebas automáticas que se ejecutan sin abrir el editor. Desde la carpeta del proyecto:

```
godot --headless --path . --script res://tests/test_comportamiento.gd
```

Si todo está bien, al final aparece `fallos: 0`. Si `godot` no funciona como comando, usa la ruta completa al ejecutable.

## Uso de inteligencia artificial

Se usó Claude (Anthropic) como asistente en el proyecto. El uso de inteligencia artificial fue de aproximadamente el 80 %.
