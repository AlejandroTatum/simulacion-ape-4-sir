# Modelo SIR en NetLogo

Simulación SIR por agentes (NetLogo 7.0.4) con los parámetros comunes de la APE 4: población 100,
5 infectados iniciales, β = 0.30, γ = 0.10, 100 ticks. Además importa `resultados_python.csv`
(generado por Python/SimPy) para graficarlo y compararlo con la corrida de NetLogo. Los agentes se dibujan
como personas que caminan por una plaza y cada contagio se ve como una línea roja.

## Archivos

| Archivo | Descripción |
| --- | --- |
| `modelo_sir_netlogo.nlogox` | Modelo en el formato nativo de NetLogo 7 (XML). Es la fuente principal. |
| `modelo_sir_netlogo.nlogo` | El mismo modelo en formato clásico, con el nombre que usa la guía. NetLogo 7.0.4 también lo abre. |
| `resultados_netlogo.csv` | Salida de NetLogo (contrato de la guía: `tiempo,susceptibles,infectados,recuperados`, 101 filas). |
| `resultados_python.csv` | Entrada que lee el botón CARGAR PYTHON (la genera la parte de Python). |

## Uso en la interfaz

1. Abrir el modelo con NetLogo (el CSV de Python debe estar en esta misma carpeta).
2. **SETUP**, luego **GO** (se detiene sola en `max-ticks`).
3. **EXPORTAR NETLOGO** escribe `resultados_netlogo.csv` (reemplaza el existente).
4. **CARGAR PYTHON** (o **CARGAR TODO**) lee `resultados_python.csv` y lo dibuja; los gráficos de comparación
   muestran las curvas de Python y NetLogo y los monitores el pico de infectados y su tick.

## Aspecto visual

- **Personas:** forma `person` (de pie), `person sick` (infectado detenido) y ciclo de caminata de perfil
  `person-forward-1..9` / `person-backward-1..9`, copiados de los modelos incluidos en NetLogo 7.0.4.
  Azul = susceptible, rojo = infectado, gris = recuperado.
- **Escenario:** césped, caminos en cruz, plaza con fuente, bancas, árboles, tres casas y un estanque. Son zonas
  bloqueadas: nadie camina por ellas y el mundo no da la vuelta en los bordes (rebotan).
- **Animación:** cada tick se divide en `velocidad-animacion` subpasos (8 por defecto) con giros suaves y fotogramas
  de caminata; los infectados caminan a la mitad de velocidad. El interruptor `animacion?` (activo) la enciende o
  apaga (apagada, cada tick es un solo paso y la corrida sin interfaz es más rápida); `wander?` activa el paseo.
- **Contagios:** una línea roja del infectante a la persona recién contagiada (se atenúa y se borra a los 2 ticks) y un
  pulso de tamaño. La regla de contacto sigue siendo la mezcla homogénea: la línea solo hace visible el contacto sorteado.
- **Contador "día"** sobre la vista y leyenda de colores bajo los monitores.

### Los resultados no cambian

Todo el código visual (escenario, caminata, pulso, líneas) corre dentro de `with-local-randomness`, que usa un
generador aparte y restaura el principal al salir. El contagio y la recuperación conservan el mismo orden de llamadas
aleatorias; solo se queda en el flujo principal el sorteo heredado `random 360` (dentro de `if wander?`), que ya no
mueve a nadie y se conserva para que la semilla 42 dé el mismo `resultados_netlogo.csv` que antes. Comprobado con
`cmp`: el CSV es idéntico byte a byte en `.nlogox` y `.nlogo`, con `animacion?` apagado y encendido.

## Ejecución sin interfaz (BehaviorSpace)

El modelo incluye el experimento `ejecucion-completa` (SETUP, GO hasta el tick 100 y exportación del CSV):

```bash
export JAVA_HOME=/opt/netlogo/lib/runtime
/opt/netlogo/netlogo-headless.sh --model modelo_sir_netlogo.nlogox \
  --experiment ejecucion-completa --table /tmp/tabla_netlogo.csv
```

El experimento fija `animacion?` en falso. Con la semilla 42: pico de infectados 31 en el tick 17 y 93 recuperados
finales; el proceso tarda unos 3 a 4 s (casi todo es el arranque de la JVM; la corrida en sí, unos 34 ms).

## Notas

- Mismo modelo en ambos formatos: si se edita uno, hay que volver a guardar el otro desde NetLogo (Archivo → Guardar como)
  o convertirlo con la API (`FileFormat.standardLoader().save`); el `.nlogo` se regeneró así desde el `.nlogox`.
- `export-view` (sin interfaz) permite regenerar las vistas de los ticks 0, 17 y 100 para la figura del informe.
- El fin de línea del CSV exportado es siempre `\n` (se escribe con `file-type` y `"\n"` explícito).
