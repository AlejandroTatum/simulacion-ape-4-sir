# Modelo SIR en NetLogo

Simulación SIR por agentes (NetLogo 7.0.4) con los parámetros comunes de la APE 4: población 100,
5 infectados iniciales, β = 0.30, γ = 0.10, 100 ticks. Además importa `resultados_python.csv`
(generado por Python/SimPy) para graficarlo y compararlo con la corrida de NetLogo.

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

## Ejecución sin interfaz (BehaviorSpace)

El modelo incluye el experimento `ejecucion-completa` (SETUP, GO hasta el tick 100 y exportación del CSV):

```bash
export JAVA_HOME=/opt/netlogo/lib/runtime
/opt/netlogo/netlogo-headless.sh --model modelo_sir_netlogo.nlogox \
  --experiment ejecucion-completa --table /tmp/tabla_netlogo.csv
```

Con la semilla 42: pico de infectados 31 en el tick 17 y 93 recuperados finales; una corrida tarda unos 3 s.

## Notas

- Mismo modelo en ambos formatos: si se edita uno, hay que volver a guardar el otro desde NetLogo (Archivo → Guardar como).
- El fin de línea del CSV exportado es siempre `\n` (se escribe con `file-type` y `"\n"` explícito).
