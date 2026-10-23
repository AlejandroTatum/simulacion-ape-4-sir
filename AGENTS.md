# Instrucciones para agentes de IA

Repositorio grupal de la APE 4 de Simulación (UNL, Ing. José Guamán): comparación de herramientas con un modelo SIR
implementado en Python (SimPy), Java y NetLogo. Python y Java generan los datos (CSV); NetLogo simula por agentes e
importa esos CSV para visualizarlos y compararlos.
Reglas obligatorias:

- La APE entrega: `README.md` (integrantes y proceso con IA), `documento/` (PDF + editable), `referencias.bib`,
  `codigo/` (Python), `java/` y `netlogo/`.
- Parámetros iguales en las tres herramientas: población 100, infectados iniciales 5, β = 0.30, γ = 0.10, tiempo 100.
- Regla de contagio común: cada infectado elige un contacto al azar entre los demás; si es susceptible y
  `aleatorio < β` se contagia; luego el infectado se recupera si `aleatorio < γ`. Actualización síncrona (copia del estado).
- Contrato CSV: `resultados_python.csv`, `resultados_java.csv` y `resultados_netlogo.csv` en `netlogo/`, encabezado
  exacto `tiempo,susceptibles,infectados,recuperados`, 101 filas (t = 0..100).
- Python: arquitectura MVC (`model/`, `view/`, `controller/`), `__main__.py` delgado, pruebas en `tests/`,
  `requirements.txt` con versiones fijadas, `codigo/.venv` sin subir. `__main__.py` funciona con `python -m simulacion_ape`
  y ejecutado por su ruta.
- Java: sin Maven ni librerías externas; se ejecuta con el lanzador de código fuente (`java Archivo.java`), sin `javac`.
- Usar semilla configurable en toda simulación aleatoria.
- Comentarios y docstrings en español; identificadores (funciones y variables) en inglés.
- El informe y los README van en español.
- Bibliografía: solo las diapositivas de la semana, sin citas en el texto (indicación del docente).

## Trabajo en grupo

- Cada integrante trabaja en su propia rama (`<nombre>/<tema>`) y abre un pull request hacia `main`; no se hace push directo a `main`.
- Antes de empezar a trabajar: `git pull` para traer los cambios de los demás.
- Mantener actualizada la tabla "Integrantes" del `README.md` con la parte a cargo de cada uno.
