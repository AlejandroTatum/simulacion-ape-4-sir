"""Lectura y escritura del contrato CSV común a Python y NetLogo."""

from pathlib import Path

import numpy as np

from .config import CSV_HEADER
from .sir_model import SirResult


def write_csv(result: SirResult, path: Path) -> None:
    """Escribe encabezado exacto, enteros, coma, UTF-8 sin BOM y fin de línea \\n."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [CSV_HEADER]
    for t, s, i, r in zip(result.time, result.susceptible, result.infected, result.recovered):
        lines.append(f"{int(t)},{int(s)},{int(i)},{int(r)}")
    with open(path, "w", encoding="utf-8", newline="\n") as file:
        file.write("\n".join(lines) + "\n")


def read_csv(path: Path) -> SirResult:
    """Lee un CSV del contrato; falla si el encabezado no es el esperado."""
    with open(path, encoding="utf-8", newline="") as file:
        lines = [line.strip() for line in file.read().splitlines() if line.strip()]
    if lines[0] != CSV_HEADER:
        raise ValueError(f"Encabezado inesperado en {path}: {lines[0]!r}")
    data = np.array([[int(value) for value in line.split(",")] for line in lines[1:]], dtype=np.int64)
    return SirResult(time=data[:, 0], susceptible=data[:, 1], infected=data[:, 2], recovered=data[:, 3])
