"""Punto de entrada delgado: solo llama al controlador.

Funciona con `python -m simulacion_ape` y también ejecutando este archivo por su ruta
(botón "Run" del editor), porque en ese caso agrega la carpeta `codigo/` al path.
"""

import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from simulacion_ape.controller.simulation_controller import main

if __name__ == "__main__":
    main()
