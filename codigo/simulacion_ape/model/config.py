"""Parámetros del modelo SIR (guía 5.1) y rutas por defecto, separados de la lógica que los usa."""

from dataclasses import dataclass
from pathlib import Path

# simulacion_ape/model/config.py -> parents[2] es la carpeta codigo/ y parents[3] la carpeta de la APE.
CODE_DIR = Path(__file__).resolve().parents[2]
APE_DIR = CODE_DIR.parent

DEFAULT_CSV_PATH = APE_DIR / "netlogo" / "resultados_python.csv"
NETLOGO_CSV_PATH = APE_DIR / "netlogo" / "resultados_netlogo.csv"
FIGURES_DIR = CODE_DIR / "figuras"

CSV_HEADER = "tiempo,susceptibles,infectados,recuperados"


@dataclass(frozen=True)
class SirConfig:
    population: int = 100
    initial_infected: int = 5
    beta: float = 0.30
    gamma: float = 0.10
    t_max: int = 100
    seed: int = 42

    @property
    def initial_susceptible(self) -> int:
        return self.population - self.initial_infected
