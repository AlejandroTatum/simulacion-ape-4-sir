;; Modelo SIR por agentes (APE 4: comparación de herramientas).
;; Regla de contacto común a todas las herramientas de la práctica: mezcla homogénea.
;; Cada infectado (estado al inicio del tick) elige UN contacto al azar entre
;; los demás individuos; si es susceptible y random < beta, se infecta;
;; luego el infectado se recupera si random < gamma. Actualización síncrona.
;;
;; Parte visual (personas que caminan por una plaza): todo el código de dibujo y
;; animación se ejecuta dentro de with-local-randomness, de modo que no consume el
;; generador aleatorio principal y la epidemia (y el CSV) es idéntica con o sin animación.

extensions [ csv ]

;; Vínculo breve que muestra quién contagió a quién
directed-link-breed [ contagios contagio ]

globals [
  ;; Serie de la simulación propia de NetLogo (un valor por tick, 0..max-ticks)
  net-t net-s net-i net-r
  ;; Series importadas desde resultados_python.csv
  py-t py-s py-i py-r
  ;; Mensaje de estado que se muestra en el monitor "Estado"
  status
  ;; Contagios del tick actual: lista de pares [infectante infectado] (solo para dibujar)
  infections-tick
  ;; Personas recién infectadas en el tick actual (efecto visual de pulso)
  new-infected
]

turtles-own [
  state       ;; estado actual: 0 = susceptible, 1 = infectado, 2 = recuperado
  next-state  ;; copia del estado para la actualización síncrona
  frame       ;; fotograma (1..9) del ciclo de caminata; solo visual
]

patches-own [
  blocked?    ;; true en edificios, fuente, bancas y árboles: nadie camina por ahí
]

contagios-own [
  age         ;; ticks transcurridos desde el contagio (el vínculo se borra a los 2)
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
  set infections-tick []
  set new-infected no-turtles
  create-turtles population [
    setxy random-xcor random-ycor
    set shape "person"
    set size person-size
    set state 0
    set next-state 0
    set frame 1
  ]
  ;; Los infectados iniciales no pueden superar la población
  ask n-of (min list initial-infected population) turtles [ set state 1 ]
  paint-turtles
  ;; Escenario y reubicación de personas: solo visual, con aleatoriedad local
  with-local-randomness [
    build-scene
    place-people
  ]
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
  ;; Dibuja los contagios y camina un día; no toca el generador principal
  with-local-randomness [ animate-day ]
  redraw-plots
  if ticks >= max-ticks [
    set status (word "Simulación NetLogo terminada en el tick " ticks)
    stop
  ]
end

;; Un paso de tiempo: lee el estado actual y escribe en next-state
to step
  set infections-tick []
  ask turtles [ set next-state state ]
  ask turtles with [ state = 1 ] [
    let contact one-of other turtles
    if contact != nobody [
      if [ state ] of contact = 0 and random-float 1 < beta [
        ask contact [ set next-state 1 ]
        ;; Solo se anota el par para dibujarlo; no consume números aleatorios
        set infections-tick lput (list self contact) infections-tick
      ]
    ]
    if random-float 1 < gamma [ set next-state 2 ]
  ]
  ask turtles [ set state next-state ]
  ;; Las personas caminan en animate-day (aleatoriedad local). Este sorteo se conserva
  ;; para que el flujo aleatorio principal sea el mismo que tenía la versión anterior
  ;; (rt random 360) y la corrida con la misma semilla dé exactamente el mismo CSV.
  if wander? [
    ask turtles [ let legacy-draw random 360 ]
  ]
end

;; Color y forma según el estado: azul = susceptible, rojo = infectado, gris = recuperado
to paint-turtles
  ask turtles [
    set color ifelse-value (state = 0) [ blue ] [ ifelse-value (state = 1) [ red ] [ gray ] ]
    set shape standing-shape
    set size person-size
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
;; Visual: personas, escenario y animación (todo bajo with-local-randomness)
;; ---------------------------------------------------------------------

to-report person-size
  report 1.8
end

;; Forma de la persona detenida (el infectado lleva la marca de enfermo)
to-report standing-shape
  report ifelse-value (state = 1) [ "person sick" ] [ "person" ]
end

;; Fotograma de caminata: de perfil hacia la derecha o hacia la izquierda
to-report walking-shape
  report (word ifelse-value (sin heading >= 0) [ "person-forward-" ] [ "person-backward-" ] frame)
end

;; Distancia que recorre una persona en un tick completo (el infectado va más lento)
to-report distance-per-tick
  report ifelse-value (state = 1) [ 0.6 ] [ 1.2 ]
end

;; Un día: borra contagios viejos, dibuja los nuevos y hace caminar a la gente
to animate-day
  fade-contagios
  show-contagios
  let n-sub ifelse-value animacion? [ max list 1 velocidad-animacion ] [ 1 ]
  let sub 1
  repeat n-sub [
    ask turtles [
      step-walk (distance-per-tick / n-sub)
      ;; Sin animación solo se mueve la posición: no se cambian formas ni fotogramas
      if animacion? [
        set frame (frame mod 9) + 1
        set shape walking-shape
      ]
    ]
    if animacion? [
      ;; Pulso: el recién infectado se agranda y vuelve a su tamaño
      ask new-infected [ set size person-size + 1 * (n-sub - sub) / n-sub ]
      display
    ]
    set sub sub + 1
  ]
  if animacion? [
    ask turtles [
      set shape standing-shape
      set size person-size
    ]
  ]
end

;; Un paso corto: giro suave al azar, esquiva edificios y rebota en los bordes
to step-walk [ dist ]
  rt (random-float 30) - 15
  let attempts 0
  while [ attempts < 10 and not free-ahead? dist ] [
    rt 60 + random 240
    set attempts attempts + 1
  ]
  if free-ahead? dist [ fd dist ]
end

to-report free-ahead? [ dist ]
  report can-move? (dist + 0.6) and not [ blocked? ] of patch-ahead (dist + 0.6)
end

;; Los vínculos de contagio duran 2 ticks: el primero en rojo y el segundo atenuado
to fade-contagios
  ask contagios [
    set age age + 1
    ifelse age >= 2 [ die ] [ set color red + 3 ]
  ]
end

;; Dibuja un vínculo rojo del infectante al recién infectado
to show-contagios
  foreach infections-tick [ pair ->
    ask first pair [
      create-contagio-to last pair [
        set color red
        set thickness 0.3
        set age 0
      ]
    ]
  ]
  set new-infected turtle-set map [ pair -> last pair ] infections-tick
end

;; Pone a cada persona en un lugar libre del escenario
to place-people
  ask turtles [
    set heading random 360
    set frame 1 + random 9
    if [ blocked? ] of patch-here or abs xcor > 15.4 or abs ycor > 15.4 [
      move-to one-of patches with [ not blocked? and abs pxcor < 16 and abs pycor < 16 ]
    ]
  ]
end

;; Escenario: plaza con césped, caminos, fuente, bancas, árboles, casas y estanque
to build-scene
  ask patches [
    set blocked? false
    set pcolor 57 + random-float 0.6 - 0.3
  ]
  ;; Caminos en cruz y plaza circular
  ask patches with [ abs pxcor <= 1 or abs pycor <= 1 ] [
    set pcolor 37 + random-float 0.4 - 0.2
  ]
  ask patches with [ distancexy 0 0 <= 6 ] [
    set pcolor 8.5 + random-float 0.4 - 0.2
  ]
  ;; Fuente central
  ask patches with [ distancexy 0 0 <= 2.2 ] [
    set pcolor 97 + random-float 0.4 - 0.2
    set blocked? true
  ]
  ask patches with [ distancexy 0 0 > 2.2 and distancexy 0 0 <= 3 ] [
    set pcolor 6.5
  ]
  ;; Estanque
  ask patches with [ distancexy 10.5 -10.5 <= 3.2 ] [
    set pcolor 95 + random-float 0.6 - 0.3
    set blocked? true
  ]
  ;; Casas (techo, pared frontal y puerta)
  build-house -14 -9 9 13 13
  build-house 9 14 8 13 3
  build-house -14 -10 -13 -9 23
  ;; Bancas de la plaza
  foreach [ [ -5 3 ] [ 4 3 ] [ -5 -4 ] [ 4 -4 ] ] [ spot ->
    ask patches with [ pxcor >= item 0 spot and pxcor <= item 0 spot + 1 and pycor = item 1 spot ] [
      set pcolor 33
      set blocked? true
    ]
  ]
  ;; Árboles (se estampan sobre el dibujo)
  foreach [ [ -7 7 ] [ 7 7 ] [ -7 -7 ] [ 6 -7 ] [ -14 2 ] [ 14 -3 ] [ 14 2 ] [ -3 14 ] [ 4 14 ] [ -3 -14 ] [ 3 -14 ] [ -14 -4 ] ] [ spot ->
    plant-tree item 0 spot item 1 spot
  ]
end

;; Casa rectangular: techo de color, pared frontal oscura y puerta
to build-house [ x1 x2 y1 y2 roof ]
  ask patches with [ pxcor >= x1 and pxcor <= x2 and pycor >= y1 and pycor <= y2 ] [
    set pcolor roof + random-float 0.6 - 0.3
    set blocked? true
  ]
  ask patches with [ pxcor >= x1 and pxcor <= x2 and pycor = y1 ] [
    set pcolor roof - 2
  ]
  ask patches with [ pxcor = floor ((x1 + x2) / 2) and pycor = y1 ] [
    set pcolor 32
  ]
end

;; Árbol estampado con una tortuga temporal (no cuenta como persona: muere al instante)
to plant-tree [ x y ]
  ask patch x y [ set blocked? true ]
  create-turtles 1 [
    setxy x y
    set shape "tree"
    set color 54
    set size 2.6
    stamp
    die
  ]
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
0
0
1
-16
16
-16
16
1
1
1
día
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

SWITCH
5
500
125
540
animacion?
animacion?
0
1
-1000

SLIDER
5
545
255
595
velocidad-animacion
velocidad-animacion
1
20
8.0
1
1
subpasos
HORIZONTAL

TEXTBOX
265
485
375
509
● Susceptible
11
105.0
1

TEXTBOX
380
485
480
509
● Infectado
11
15.0
1

TEXTBOX
485
485
595
509
● Recuperado
11
5.0
1

TEXTBOX
265
510
595
550
La línea roja une al infectante con la persona recién contagiada (dura 2 ticks).
10
0.0
1

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
"S" 1.0 0 -13345367 true "" ""
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
"S" 1.0 0 -13345367 true "" ""
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

- 100 agentes (tortugas) dibujados como personas en una plaza: azul = susceptible, rojo = infectado (con la marca de enfermo cuando está detenido), gris = recuperado.
- Parámetros comunes de la práctica: población 100, infectados iniciales 5, β = 0.30, γ = 0.10, tiempo de simulación 100 (R₀ = β/γ = 3).
- Regla de contacto (mezcla homogénea): en cada tick, cada infectado (estado al inicio del tick) elige **un** contacto al azar entre los demás individuos. Si el contacto es susceptible y un número aleatorio en [0, 1) es menor que β, pasa a infectado. Luego el infectado se recupera si otro número aleatorio es menor que γ.
- La actualización es síncrona: todos leen el estado actual y las decisiones se escriben en `next-state`; al final del tick se copian a `state`.
- Las personas caminan solo como efecto visual (interruptor `wander?`); el contagio no depende de la posición ni de la animación.
- Se registran S, I y R en los ticks 0..100 y la simulación se detiene en `max-ticks`.

## ESCENARIO Y ANIMACIÓN

- **Escenario**: césped, caminos en cruz, plaza circular con una fuente al centro, bancas, árboles, tres casas y un estanque. Los edificios, la fuente, las bancas, los árboles y el estanque son zonas bloqueadas por donde nadie camina.
- **Personas que caminan**: cada día (tick) se divide en `velocidad-animacion` subpasos (por defecto 8). En cada subpaso la persona avanza un poco con un giro suave al azar, cambia al siguiente fotograma de un ciclo de caminata de perfil (formas `person-forward-1..9` y `person-backward-1..9`, tomadas de los modelos incluidos en NetLogo), esquiva los edificios y rebota en los bordes. Los infectados caminan a la mitad de velocidad; susceptibles y recuperados, a la normal. Al terminar el día las personas quedan de pie (`person`, o `person sick` si están infectadas).
- **Contagios visibles**: cuando alguien se infecta se dibuja una línea roja del infectante a la persona recién contagiada, que además se agranda un momento. La línea dura 2 ticks (el segundo atenuada) y luego se borra. La regla de contacto sigue siendo la mezcla homogénea: la línea solo hace visible el contacto al azar que ya se había sorteado.
- **Interruptor `animacion?`** (activo por defecto): con animación se ve la caminata fluida; sin ella cada día es un solo paso y la corrida es mucho más rápida (la usa el experimento sin interfaz). El deslizador `velocidad-animacion` fija los subpasos por día (1 a 20).
- **Contador "día"** sobre la vista y leyenda de colores bajo los monitores.

## ALEATORIEDAD LOCAL (los resultados no cambian)

Todo el código visual (construcción del escenario, caminata, giros, pulso y vínculos de contagio) se ejecuta dentro de `with-local-randomness`. Ese bloque usa un generador aparte y restaura el principal al terminar, por lo que dibujar o no, y con cuántos subpasos, no cambia ningún sorteo de la epidemia. El contagio y la recuperación conservan el mismo orden de llamadas aleatorias. Con la semilla 42 el archivo `resultados_netlogo.csv` es idéntico byte a byte con o sin animación (pico de 31 infectados en el tick 17 y 93 recuperados finales).

El único sorteo "de movimiento" que sigue en el generador principal es `let legacy-draw random 360` dentro de `if wander?`: se conserva a propósito para que la corrida con la misma semilla dé exactamente el mismo CSV que la versión anterior; no mueve a nadie.

## CÓMO USARLO

1. Ajusta los controles: `population`, `initial-infected`, `beta`, `gamma`, `max-ticks`, `seed`, `wander?`, `animacion?` y `velocidad-animacion` (semilla de `random-seed`; la misma semilla repite la misma corrida).
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

El experimento `ejecucion-completa` ejecuta SETUP, GO y EXPORTAR NETLOGO sin interfaz gráfica y con `animacion?` desactivado.

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

person sick
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Circle -2674135 true false 178 163 95

person-backward-1
false
0
Polygon -7500403 true true 180 195 180 105 165 90 105 90 105 105 105 120 120 180
Circle -7500403 true true 95 5 80
Rectangle -7500403 true true 117 73 153 90
Polygon -7500403 true true 135 195 180 180 204 228 240 255 225 300 167 242
Polygon -7500403 true true 120 180 180 180 144 232 141 299 101 299 105 223
Polygon -7500403 true true 165 90 205 125 240 180 210 195 173 137 150 120
Polygon -7500403 true true 120 136 120 151 94 202 66 190 90 136 105 91

person-backward-2
false
0
Polygon -7500403 true true 120 136 135 166 108 203 80 191 98 147 109 98
Circle -7500403 true true 95 5 80
Rectangle -7500403 true true 117 73 153 90
Polygon -7500403 true true 132 176 183 160 195 225 225 255 210 300 165 255
Polygon -7500403 true true 126 164 180 180 150 225 150 300 105 300 105 225
Polygon -7500403 true true 195 180 180 105 165 90 113 89 105 105 105 120 120 180
Polygon -7500403 true true 169 91 204 135 225 180 180 195 165 150 150 120

person-backward-3
false
0
Polygon -7500403 true true 129 123 119 162 135 200 104 201 102 150 106 104
Polygon -7500403 true true 135 180 180 180 180 225 210 285 165 300 135 225
Polygon -7500403 true true 120 180 179 180 142 239 165 300 120 300 120 225
Circle -7500403 true true 95 5 80
Rectangle -7500403 true true 117 73 153 90
Polygon -7500403 true true 184 192 180 105 165 90 120 90 105 105 105 120 120 195
Polygon -7500403 true true 165 90 180 105 207 193 172 199 165 150 150 120

person-backward-4
false
0
Polygon -7500403 true true 120 135 120 165 125 205 114 203 110 135 117 89
Circle -7500403 true true 95 5 80
Rectangle -7500403 true true 117 73 153 90
Polygon -7500403 true true 135 180 180 180 180 225 180 300 135 300 135 225
Polygon -7500403 true true 119 182 149 182 164 227 164 302 119 302 119 212
Polygon -7500403 true true 180 190 180 105 170 90 120 90 105 105 105 120 120 195
Polygon -7500403 true true 155 90 170 102 180 135 180 165 180 210 150 210

person-backward-5
false
0
Circle -7500403 true true 95 5 80
Rectangle -7500403 true true 117 73 153 90
Polygon -7500403 true true 120 180 165 180 165 225 180 300 120 300 120 225
Polygon -7500403 true true 105 180 180 180 165 225 150 300 105 300 99 222
Polygon -7500403 true true 180 195 180 105 165 90 120 90 105 105 105 120 120 195
Polygon -7500403 true true 120 135 120 165 120 195 105 195 105 120 117 89
Polygon -7500403 true true 164 128 164 158 164 203 134 203 135 120 158 95

person-backward-6
false
0
Polygon -7500403 true true 135 180 180 180 178 222 195 300 150 300 135 225
Polygon -7500403 true true 118 174 180 178 135 240 127 298 86 294 90 225
Circle -7500403 true true 95 5 80
Rectangle -7500403 true true 117 73 153 90
Polygon -7500403 true true 184 192 180 105 165 90 120 90 105 105 105 120 120 195
Polygon -7500403 true true 165 90 195 120 207 193 180 195 180 135 150 120
Polygon -7500403 true true 150 124 150 154 139 201 105 199 107 133 117 93

person-backward-7
false
0
Circle -7500403 true true 95 5 80
Rectangle -7500403 true true 117 73 153 90
Polygon -7500403 true true 135 180 180 180 195 240 210 300 165 300 150 240
Polygon -7500403 true true 135 166 180 181 123 229 120 297 79 289 87 210
Polygon -7500403 true true 180 195 180 105 165 90 120 90 105 105 105 120 111 193
Polygon -7500403 true true 178 103 200 133 221 195 189 202 176 165 146 120
Polygon -7500403 true true 120 133 135 163 120 210 90 195 102 146 105 105

person-backward-8
false
0
Polygon -7500403 true true 117 168 162 183 122 239 97 300 60 280 87 226
Circle -7500403 true true 95 5 80
Rectangle -7500403 true true 117 73 153 90
Polygon -7500403 true true 180 180 180 105 165 90 120 90 105 105 105 120 105 180
Polygon -7500403 true true 165 90 201 127 234 183 208 197 182 158 150 120
Polygon -7500403 true true 120 133 135 163 90 195 68 179 97 141 117 87
Polygon -7500403 true true 135 180 180 180 195 240 225 300 180 300 150 240

person-backward-9
false
0
Circle -7500403 true true 95 5 80
Rectangle -7500403 true true 117 73 153 90
Polygon -7500403 true true 135 180 180 180 195 225 232 289 195 300 150 225
Polygon -7500403 true true 112 185 165 180 137 240 129 300 83 301 100 229
Polygon -7500403 true true 179 180 179 105 164 90 119 90 105 97 104 120 113 185
Polygon -7500403 true true 165 90 210 135 240 180 210 195 180 150 150 120
Polygon -7500403 true true 115 137 115 154 78 199 54 179 85 139 115 92

person-forward-1
false
0
Polygon -7500403 true true 120 195 120 105 135 90 195 90 195 105 195 120 180 180
Circle -7500403 true true 125 5 80
Rectangle -7500403 true true 147 73 183 90
Polygon -7500403 true true 165 195 120 180 96 228 60 255 75 300 133 242
Polygon -7500403 true true 180 180 120 180 156 232 159 299 199 299 195 223
Polygon -7500403 true true 135 90 95 125 60 180 90 195 127 137 150 120
Polygon -7500403 true true 180 136 180 151 206 202 234 190 210 136 195 91

person-forward-2
false
0
Polygon -7500403 true true 180 136 165 166 192 203 220 191 202 147 191 98
Circle -7500403 true true 125 5 80
Rectangle -7500403 true true 147 73 183 90
Polygon -7500403 true true 168 176 117 160 105 225 75 255 90 300 135 255
Polygon -7500403 true true 174 164 120 180 150 225 150 300 195 300 195 225
Polygon -7500403 true true 105 180 120 105 135 90 187 89 195 105 195 120 180 180
Polygon -7500403 true true 131 91 96 135 75 180 120 195 135 150 150 120

person-forward-3
false
0
Polygon -7500403 true true 171 123 181 162 165 200 196 201 198 150 194 104
Polygon -7500403 true true 165 180 120 180 120 225 90 285 135 300 165 225
Polygon -7500403 true true 180 180 121 180 158 239 135 300 180 300 180 225
Circle -7500403 true true 125 5 80
Rectangle -7500403 true true 147 73 183 90
Polygon -7500403 true true 116 192 120 105 135 90 180 90 195 105 195 120 180 195
Polygon -7500403 true true 135 90 120 105 93 193 128 199 135 150 150 120

person-forward-4
false
0
Polygon -7500403 true true 180 135 180 165 175 205 186 203 190 135 183 89
Circle -7500403 true true 125 5 80
Rectangle -7500403 true true 147 73 183 90
Polygon -7500403 true true 165 180 120 180 120 225 120 300 165 300 165 225
Polygon -7500403 true true 181 182 151 182 136 227 136 302 181 302 181 212
Polygon -7500403 true true 120 190 120 105 130 90 180 90 195 105 195 120 180 195
Polygon -7500403 true true 145 90 130 102 120 135 120 165 120 210 150 210

person-forward-5
false
0
Circle -7500403 true true 125 5 80
Rectangle -7500403 true true 147 73 183 90
Polygon -7500403 true true 180 180 135 180 135 225 120 300 180 300 180 225
Polygon -7500403 true true 195 180 120 180 135 225 150 300 195 300 201 222
Polygon -7500403 true true 120 195 120 105 135 90 180 90 195 105 195 120 180 195
Polygon -7500403 true true 180 135 180 165 180 195 195 195 195 120 183 89
Polygon -7500403 true true 136 128 136 158 136 203 166 203 165 120 142 95

person-forward-6
false
0
Polygon -7500403 true true 165 180 120 180 122 222 105 300 150 300 165 225
Polygon -7500403 true true 182 174 120 178 165 240 173 298 214 294 210 225
Circle -7500403 true true 125 5 80
Rectangle -7500403 true true 147 73 183 90
Polygon -7500403 true true 116 192 120 105 135 90 180 90 195 105 195 120 180 195
Polygon -7500403 true true 135 90 105 120 93 193 120 195 120 135 150 120
Polygon -7500403 true true 150 124 150 154 161 201 195 199 193 133 183 93

person-forward-7
false
0
Circle -7500403 true true 125 5 80
Rectangle -7500403 true true 147 73 183 90
Polygon -7500403 true true 165 180 120 180 105 240 90 300 135 300 150 240
Polygon -7500403 true true 165 166 120 181 177 229 180 297 221 289 213 210
Polygon -7500403 true true 120 195 120 105 135 90 180 90 195 105 195 120 189 193
Polygon -7500403 true true 122 103 100 133 79 195 111 202 124 165 154 120
Polygon -7500403 true true 180 133 165 163 180 210 210 195 198 146 195 105

person-forward-8
false
0
Polygon -7500403 true true 183 168 138 183 178 239 203 300 240 280 213 226
Circle -7500403 true true 125 5 80
Rectangle -7500403 true true 147 73 183 90
Polygon -7500403 true true 120 180 120 105 135 90 180 90 195 105 195 120 195 180
Polygon -7500403 true true 135 90 99 127 66 183 92 197 118 158 150 120
Polygon -7500403 true true 180 133 165 163 210 195 232 179 203 141 183 87
Polygon -7500403 true true 165 180 120 180 105 240 75 300 120 300 150 240

person-forward-9
false
0
Circle -7500403 true true 125 5 80
Rectangle -7500403 true true 147 73 183 90
Polygon -7500403 true true 165 180 120 180 105 225 68 289 105 300 150 225
Polygon -7500403 true true 188 185 135 180 163 240 171 300 217 301 200 229
Polygon -7500403 true true 121 180 121 105 136 90 181 90 195 97 196 120 187 185
Polygon -7500403 true true 135 90 90 135 60 180 90 195 120 150 150 120
Polygon -7500403 true true 185 137 185 154 222 199 246 179 215 139 185 92

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
    <enumeratedValueSet variable="animacion?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="velocidad-animacion">
      <value value="8"/>
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
