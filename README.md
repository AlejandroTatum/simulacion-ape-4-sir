# APE 4 — Análisis comparativo de herramientas de simulación (modelo SIR)

| | |
| --- | --- |
| **Asignatura** | Simulación — Universidad Nacional de Loja |
| **Docente** | Ing. José Guamán |
| **Unidad** | U1: Introducción a la Simulación |
| **Práctica** | 04 — Análisis comparativo de herramientas de simulación mediante un modelo común |
| **Modalidad** | Grupal |
| **Guía** | [guia/guia-ape-4.pdf](guia/guia-ape-4.pdf) |
| **Informe** | [documento/](documento/) |
| **Bibliografía** | [referencias.bib](referencias.bib) |

## Integrantes

| Integrante | Responsabilidad |
| --- | --- |
| Andrés Tapia | Por definir |
| Ariel González | Por definir |
| Gyna Yupanqui | Por definir |
| Alejandro Padilla | Por definir |

## 1. ¿Qué hacemos en esta práctica?

Programamos **el mismo modelo epidemiológico SIR** en tres herramientas y las comparamos:

- **Python (SimPy)** y **Java** simulan la epidemia y guardan los resultados en un archivo CSV.
- **NetLogo** simula la epidemia con agentes (las "tortugas") y además **importa** los CSV de Python y Java
  para dibujar las tres curvas juntas y compararlas.

La población se divide en tres grupos:

- **S** — susceptibles (sanos que se pueden contagiar), en verde.
- **I** — infectados, en rojo.
- **R** — recuperados, en gris.

Los parámetros son los mismos en las tres herramientas:

| Parámetro | Valor |
| --- | --- |
| Población | 100 |
| Infectados iniciales | 5 |
| Susceptibles iniciales | 95 |
| β (tasa de infección) | 0.30 |
| γ (tasa de recuperación) | 0.10 |
| Tiempo de simulación | 100 |

Con estos valores, R₀ = β / γ = 3: cada infectado contagia en promedio a unas tres personas antes de recuperarse.

**Regla de cada paso de tiempo (igual en las tres herramientas):** cada infectado elige a una persona al azar;
si esa persona es susceptible y sale un número aleatorio menor que β, se contagia. Después, el infectado se recupera
si sale un número aleatorio menor que γ.

## 2. Estructura del repositorio

```text
simulacion-ape-4-sir/
├── codigo/      # Python + SimPy: genera resultados_python.csv y las gráficas
├── java/        # Java: genera resultados_java.csv
├── netlogo/     # Modelo de NetLogo + los tres CSV (python, java, netlogo)
├── documento/   # Informe (PDF y editable)
├── guia/        # Guía de la práctica entregada por el docente
└── referencias.bib
```

Python y Java guardan su CSV directamente dentro de `netlogo/`, en la misma carpeta que el modelo,
como pide la guía. Así NetLogo los encuentra sin copiar nada a mano.

## 3. Cómo levantar el proyecto (paso a paso)

### 3.0 Lo que necesitas instalado

| Programa | Versión | Para qué | Descarga |
| --- | --- | --- | --- |
| Git | cualquiera | Bajar el repositorio | <https://git-scm.com/downloads> |
| Python | 3.11 o superior | Parte de Python | <https://www.python.org/downloads/> |
| Java (JDK) | 22 o superior | Parte de Java | <https://adoptium.net/> |
| NetLogo | 7.0 o superior | Simulación y comparación | <https://ccl.northwestern.edu/netlogo/download.shtml> |

Para comprobar que están instalados, abre una terminal y escribe:

```bash
git --version
python --version     # en algunos equipos es: python3 --version
java --version
```

> En Windows, al instalar Python marca la casilla **"Add Python to PATH"**.

### 3.1 Bajar el repositorio

```bash
git clone https://github.com/AlejandroTatum/simulacion-ape-4-sir.git
cd simulacion-ape-4-sir
```

### 3.2 Python (genera `resultados_python.csv`)

```bash
cd codigo
python -m venv .venv
```

Activar el entorno virtual (solo una vez por terminal):

```bash
# Linux / macOS
source .venv/bin/activate
# Windows (PowerShell)
.venv\Scripts\Activate.ps1
# Windows (CMD)
.venv\Scripts\activate.bat
```

Instalar las librerías y correr:

```bash
pip install -r requirements.txt
python -m simulacion_ape     # corre la simulación, crea el CSV y las gráficas
pytest                       # corre las pruebas
cd ..
```

> Si usas VS Code: selecciona el intérprete `codigo/.venv` (abajo a la derecha) y también puedes darle al botón
> **Run** sobre `codigo/simulacion_ape/__main__.py`.

### 3.3 Java (genera `resultados_java.csv`)

No hace falta compilar ni instalar Maven: Java ejecuta directamente el código fuente.

```bash
cd java
# Linux / macOS
./run.sh
# Windows (o cualquier sistema)
java src/Main.java
cd ..
```

> El comando exacto también está en [java/README.md](java/README.md).

### 3.4 NetLogo (simula y compara)

1. Abre NetLogo.
2. **File → Open** y elige `netlogo/modelo_sir_netlogo.nlogox`.
3. Presiona **SETUP** y luego **GO**: NetLogo corre su propia simulación con las tortugas.
4. Presiona **CARGAR PYTHON** y **CARGAR JAVA**: NetLogo lee los CSV y dibuja las curvas de cada herramienta.
5. Mira las gráficas de **Comparación de infectados, susceptibles y recuperados**.
6. (Opcional) **EXPORTAR NETLOGO** guarda la corrida de NetLogo en `resultados_netlogo.csv`.

> Si NetLogo dice que no encuentra el CSV, primero corre la parte de Python (3.2) y la de Java (3.3).

### 3.5 Formato de los CSV

Los tres archivos tienen el mismo formato, una fila por instante de tiempo (de 0 a 100):

```text
tiempo,susceptibles,infectados,recuperados
0,95,5,0
1,...
```

## 4. Cómo trabajamos en grupo (Git)

Nadie sube cambios directo a `main`. Cada uno trabaja en su rama y abre un pull request:

```bash
git pull                              # traer lo último antes de empezar
git checkout -b tu-nombre/tema        # ejemplo: gyna/informe
# ... haces tus cambios ...
git add .
git commit -m "docs: agrega conclusiones"
git push -u origin tu-nombre/tema     # luego abre el pull request en GitHub
```

## 5. ¿Por qué los resultados no salen idénticos?

Las tres herramientas usan el mismo modelo y los mismos parámetros, pero **cada una tiene su propio generador de
números aleatorios** (NumPy en Python, `java.util.Random` en Java y el generador de NetLogo). Aunque usemos la misma
semilla, la secuencia de números es distinta, así que los contagios ocurren en momentos distintos. Las curvas tienen
la misma forma (sube el pico de infectados y luego baja), pero los valores exactos cambian. Esto se analiza en el informe.

## 6. Herramientas de IA

| Herramienta | Uso |
| --- | --- |
| Agente de programación el Gentleman (Pi) con modelo Claude | Lectura de la guía, modelo SIR en Python, Java y NetLogo, pruebas, gráficas e informe. |

La IA ejecutó; las decisiones de modelo, formato y contenido las tomó el grupo.

## 7. Proceso con IA

1. Entender la guía y fijar una regla de contagio común
2. Modelo SIR en Python con SimPy
3. Modelo SIR en Java
4. Modelo SIR en NetLogo e importación de CSV
5. Comparación de resultados e informe

## 8. Resultados

Pendiente: se completa cuando estén las tres corridas.
