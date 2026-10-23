;; Modelo SIR por agentes (APE 4: comparación de herramientas).
;; Regla de contacto común a todas las herramientas de la práctica: mezcla homogénea.
;; Cada infectado (estado al inicio del tick) elige UN contacto al azar entre
;; los demás individuos; si es susceptible y random < beta, se infecta;
;; luego el infectado se recupera si random < gamma. Actualización síncrona.

extensions [ csv ]

globals [
  ;; Serie de la simulación propia de NetLogo (un valor por tick, 0..max-ticks)
  net-t net-s net-i net-r
  ;; Series importadas desde resultados_python.csv
  py-t py-s py-i py-r
  ;; Mensaje de estado que se muestra en el monitor "Estado"
  status
]

turtles-own [
  state       ;; estado actual: 0 = susceptible, 1 = infectado, 2 = recuperado
  next-state  ;; copia del estado para la actualización síncrona
]

;; ---------------------------------------------------------------------
;; Simulación propia de NetLogo
;; ---------------------------------------------------------------------

to setup
  ;; No se usa clear-all para conservar las serie importada de Python
  clear-turtles
  clear-patches
  clear-drawing
  clear-ticks
  clear-all-plots
  init-imported-if-needed
  random-seed seed
  set net-t []
  set net-s []
  set net-i []
  set net-r []
  create-turtles population [
    setxy random-xcor random-ycor
    set shape "circle"
    set size 1.2
    set state 0
    set next-state 0
  ]
  ;; Los infectados iniciales no pueden superar la población
  ask n-of (min list initial-infected population) turtles [ set state 1 ]
  paint-turtles
  reset-ticks
  record-state
  set status "Simulación NetLogo lista (tick 0)"
  redraw-plots
end

to go
  if ticks >= max-ticks [ stop ]
  step
  tick
  record-state
  paint-turtles
  redraw-plots
  if ticks >= max-ticks [
    set status (word "Simulación NetLogo terminada en el tick " ticks)
    stop
  ]
end

;; Un paso de tiempo: lee el estado actual y escribe en next-state
to step
  ask turtles [ set next-state state ]
  ask turtles with [ state = 1 ] [
    let contact one-of other turtles
    if contact != nobody [
      if [ state ] of contact = 0 and random-float 1 < beta [
        ask contact [ set next-state 1 ]
      ]
    ]
    if random-float 1 < gamma [ set next-state 2 ]
  ]
  ask turtles [ set state next-state ]
  ;; El movimiento es solo visual: el contagio no depende de la posición
  if wander? [
    ask turtles [
      rt random 360
      fd 0.5
    ]
  ]
end

to paint-turtles
  ask turtles [
    set color ifelse-value (state = 0) [ green ] [ ifelse-value (state = 1) [ red ] [ gray ] ]
  ]
end

;; Guarda S, I y R del tick actual
to record-state
  set net-t lput ticks net-t
  set net-s lput count turtles with [ state = 0 ] net-s
  set net-i lput count turtles with [ state = 1 ] net-i
  set net-r lput count turtles with [ state = 2 ] net-r
end

;; ---------------------------------------------------------------------
;; Exportación: escribe resultados_netlogo.csv (contrato S3)
;; ---------------------------------------------------------------------

to export-netlogo
  if empty? net-t [
    set status "Nada que exportar: ejecuta SETUP y GO primero"
    stop
  ]
  let file-name "resultados_netlogo.csv"
  if file-exists? file-name [ file-delete file-name ]
  file-open file-name
  ;; file-type con "\n" explícito garantiza fin de línea LF en cualquier sistema
  file-type "tiempo,susceptibles,infectados,recuperados\n"
  (foreach net-t net-s net-i net-r [ [ t s i r ] ->
    file-type (word t "," s "," i "," r "\n")
  ])
  file-close
  set status (word "Exportado " file-name " (" length net-t " filas)")
end

;; ---------------------------------------------------------------------
;; Importación de resultados de Python (NetLogo solo los lee)
;; ---------------------------------------------------------------------

to load-python
  let data read-series "resultados_python.csv"
  if not empty? data [
    set py-t item 0 data
    set py-s item 1 data
    set py-i item 2 data
    set py-r item 3 data
  ]
  redraw-plots
end

to load-all
  load-python
end

;; Abre el CSV, lee el encabezado y cada fila, guarda las columnas en listas
;; y cierra el archivo. Reporta [tiempo susceptibles infectados recuperados]
;; o una lista vacía si el archivo no existe o tiene un formato inválido.
to-report read-series [ file-name ]
  if not file-exists? file-name [
    set status (word "No se encontró " file-name " en la carpeta del modelo")
    report []
  ]
  let t []
  let s []
  let i []
  let r []
  file-open file-name
  let header file-read-line
  if header != "tiempo,susceptibles,infectados,recuperados" [
    file-close
    set status (word "Encabezado inválido en " file-name)
    report []
  ]
  while [ not file-at-end? ] [
    let line file-read-line
    if length line > 0 [
      let row csv:from-row line
      if length row = 4 [
        set t lput item 0 row t
        set s lput item 1 row s
        set i lput item 2 row i
        set r lput item 3 row r
      ]
    ]
  ]
  file-close
  set status (word "Cargado " file-name " (" length t " filas)")
  report (list t s i r)
end

to init-imported-if-needed
  if not is-list? py-t [
    set py-t []
    set py-s []
    set py-i []
    set py-r []
  ]
  if not is-list? net-t [
    set net-t []
    set net-s []
    set net-i []
    set net-r []
  ]
end

;; ---------------------------------------------------------------------
;; Gráficos y monitores
;; ---------------------------------------------------------------------

;; Redibuja todos los gráficos a partir de las listas guardadas
to redraw-plots
  init-imported-if-needed
  draw-sir "Simulación NetLogo (S, I, R)" net-t net-s net-i net-r
  draw-sir "Python (S, I, R)" py-t py-s py-i py-r
  draw-comparison "Comparación de infectados" py-t py-i net-t net-i
  draw-comparison "Comparación de susceptibles" py-t py-s net-t net-s
  draw-comparison "Comparación de recuperados" py-t py-r net-t net-r
end

to draw-sir [ plot-title xs susceptibles infected recovered ]
  draw-series plot-title "S" xs susceptibles
  draw-series plot-title "I" xs infected
  draw-series plot-title "R" xs recovered
end

to draw-comparison [ plot-title xs-py ys-py xs-net ys-net ]
  draw-series plot-title "Python" xs-py ys-py
  draw-series plot-title "NetLogo" xs-net ys-net
end

to draw-series [ plot-title pen-name xs ys ]
  set-current-plot plot-title
  set-current-plot-pen pen-name
  plot-pen-reset
  ;; Pluma levantada hasta el primer punto para no trazar desde el origen
  plot-pen-up
  (foreach xs ys [ [ x y ] ->
    plotxy x y
    plot-pen-down
  ])
end

;; Valor máximo de infectados de una serie (0 si no hay datos)
to-report peak-value [ ys ]
  report ifelse-value empty? ys [ 0 ] [ max ys ]
end

;; Tick en que ocurre el pico de infectados ("-" si no hay datos)
to-report peak-tick [ xs ys ]
  report ifelse-value empty? ys [ "-" ] [ item (position max ys ys) xs ]
end
@#$#@#$#@
GRAPHICS-WINDOW
265
10
595
340
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
5
10
85
50
SETUP
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
90
10
170
50
GO
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
175
10
255
50
EXPORTAR NETLOGO
export-netlogo
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
60
255
110
population
population
1
1000
100.0
1
1
NIL
HORIZONTAL

SLIDER
5
110
255
160
initial-infected
initial-infected
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
5
160
255
210
beta
beta
0
1
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
5
210
255
260
gamma
gamma
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
5
260
255
310
max-ticks
max-ticks
1
500
100.0
1
1
ticks
HORIZONTAL

INPUTBOX
5
315
125
375
seed
42.0
1
0
Number

SWITCH
135
320
255
360
wander?
wander?
0
1
-1000

BUTTON
5
385
125
425
CARGAR PYTHON
load-python
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
135
385
255
425
CARGAR TODO
load-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
265
350
425
410
Pico de infectados NetLogo
peak-value net-i
0
1
11

MONITOR
430
350
595
410
Tick del pico NetLogo
peak-tick net-t net-i
0
1
11

MONITOR
265
415
425
475
Pico de infectados Python
peak-value py-i
0
1
11

MONITOR
430
415
595
475
Tick del pico Python
peak-tick py-t py-i
0
1
11

MONITOR
5
435
255
495
Estado
status
0
1
11

PLOT
605
10
935
240
Simulación NetLogo (S, I, R)
tiempo
individuos
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"S" 1.0 0 -10899396 true "" ""
"I" 1.0 0 -2674135 true "" ""
"R" 1.0 0 -7500403 true "" ""

PLOT
945
10
1275
240
Python (S, I, R)
tiempo
individuos
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"S" 1.0 0 -10899396 true "" ""
"I" 1.0 0 -2674135 true "" ""
"R" 1.0 0 -7500403 true "" ""

PLOT
605
250
935
480
Comparación de infectados
tiempo
individuos
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Python" 1.0 0 -13345367 true "" ""
"NetLogo" 1.0 0 -8630108 true "" ""

PLOT
945
250
1275
480
Comparación de susceptibles
tiempo
individuos
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Python" 1.0 0 -13345367 true "" ""
"NetLogo" 1.0 0 -8630108 true "" ""

PLOT
605
490
935
720
Comparación de recuperados
tiempo
individuos
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Python" 1.0 0 -13345367 true "" ""
"NetLogo" 1.0 0 -8630108 true "" ""

@#$#@#$#@
## ¿QUÉ ES?

Modelo epidemiológico SIR (Susceptible – Infectado – Recuperado) por agentes, parte de la APE 4 de Simulación (UNL). NetLogo ejecuta su **propia** simulación y además **importa** el CSV generado por Python/SimPy para visualizarlo y compararlo con la corrida de NetLogo. NetLogo no genera los datos de Python.

## CÓMO FUNCIONA

- 100 agentes (tortugas): verde = susceptible, rojo = infectado, gris = recuperado.
- Parámetros comunes de la práctica: población 100, infectados iniciales 5, β = 0.30, γ = 0.10, tiempo de simulación 100 (R₀ = β/γ = 3).
- Regla de contacto (mezcla homogénea): en cada tick, cada infectado (estado al inicio del tick) elige **un** contacto al azar entre los demás individuos. Si el contacto es susceptible y un número aleatorio en [0, 1) es menor que β, pasa a infectado. Luego el infectado se recupera si otro número aleatorio es menor que γ.
- La actualización es síncrona: todos leen el estado actual y las decisiones se escriben en `next-state`; al final del tick se copian a `state`.
- Los agentes se mueven al azar solo como efecto visual (interruptor `wander?`); el contagio no depende de la posición.
- Se registran S, I y R en los ticks 0..100 y la simulación se detiene en `max-ticks`.

## CÓMO USARLO

1. Ajusta los controles: `population`, `initial-infected`, `beta`, `gamma`, `max-ticks` y `seed` (semilla de `random-seed`; la misma semilla repite la misma corrida).
2. **SETUP** crea la población e inicia los gráficos. **GO** avanza hasta `max-ticks` y se detiene sola.
3. **EXPORTAR NETLOGO** escribe `resultados_netlogo.csv` en la carpeta del modelo (reemplaza el archivo si existe).
4. **CARGAR PYTHON** lee `resultados_python.csv` de la carpeta del modelo y lo dibuja. **CARGAR TODO** carga los archivos externos disponibles (por ahora, el de Python).
5. Los monitores muestran el pico de infectados y el tick en que ocurre, para NetLogo y para Python.

El modelo debe estar guardado en la misma carpeta que los CSV; las rutas son relativas a esa carpeta.

## FORMATO DEL CSV

Encabezado exacto `tiempo,susceptibles,infectados,recuperados`, seguido de 101 filas (t = 0..100) con enteros separados por coma, codificación UTF-8 y fin de línea `\n`.

## GRÁFICOS

- Simulación NetLogo (S, I, R) y Python (S, I, R).
- Comparación de infectados, de susceptibles y de recuperados, con una curva por herramienta (Python y NetLogo).

## COSAS PARA NOTAR

Dos implementaciones del mismo modelo con los mismos parámetros dan curvas parecidas pero no idénticas, porque cada herramienta usa su propio generador de números aleatorios. Prueba distintas semillas y observa cuánto varía el pico de infectados.

## EXPERIMENTO (BehaviorSpace)

El experimento `ejecucion-completa` ejecuta SETUP, GO y EXPORTAR NETLOGO sin interfaz gráfica.

## CRÉDITOS

Modelo elaborado para la asignatura Simulación (UNL). NetLogo: Wilensky, U. (1999). NetLogo. Center for Connected Learning and Computer-Based Modeling, Northwestern University.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 7.0.4
@#$#@#$#@
setup repeat 20 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="ejecucion-completa" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <postRun>export-netlogo</postRun>
    <metric>peak-value net-i</metric>
    <metric>peak-tick net-t net-i</metric>
    <metric>last net-r</metric>
    <enumeratedValueSet variable="population">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-infected">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gamma">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wander?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
