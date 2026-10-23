"""Modelo SIR por individuos con mezcla homogénea y actualización síncrona (guía 5.2 A)."""

from dataclasses import dataclass

import numpy as np
import simpy

from .config import SirConfig

SUSCEPTIBLE = 0
INFECTED = 1
RECOVERED = 2


@dataclass(frozen=True)
class SirResult:
    """Serie temporal de conteos; los cuatro arreglos tienen longitud t_max + 1."""

    time: np.ndarray
    susceptible: np.ndarray
    infected: np.ndarray
    recovered: np.ndarray


class SirModel:
    """Población como arreglo de estados; cada paso lee el estado actual y escribe una copia."""

    def __init__(self, config: SirConfig, rng: np.random.Generator):
        self.config = config
        self.rng = rng
        self.state = np.full(config.population, SUSCEPTIBLE, dtype=np.int8)
        self.state[: config.initial_infected] = INFECTED

    def counts(self) -> tuple[int, int, int]:
        return (
            int(np.sum(self.state == SUSCEPTIBLE)),
            int(np.sum(self.state == INFECTED)),
            int(np.sum(self.state == RECOVERED)),
        )

    def step(self) -> None:
        """Avanza una unidad de tiempo: cada infectado contacta a UNO de los otros n-1 y luego puede recuperarse."""
        n = self.config.population
        current = self.state
        following = current.copy()
        for i in np.flatnonzero(current == INFECTED):
            # Contacto uniforme entre los otros n-1 individuos (se salta el índice propio).
            contact = int(self.rng.integers(0, n - 1))
            if contact >= i:
                contact += 1
            if current[contact] == SUSCEPTIBLE and self.rng.random() < self.config.beta:
                following[contact] = INFECTED
            if self.rng.random() < self.config.gamma:
                following[i] = RECOVERED
        self.state = following


def sir_process(env: simpy.Environment, model: SirModel, records: list[tuple[int, int, int, int]]):
    """Proceso de SimPy: guarda los conteos de cada instante y avanza un paso con env.timeout(1)."""
    t_max = model.config.t_max
    while True:
        s, i, r = model.counts()
        records.append((int(env.now), s, i, r))
        if env.now >= t_max:
            return
        model.step()
        yield env.timeout(1)


def run_sir(config: SirConfig) -> SirResult:
    """Ejecuta una corrida completa con la semilla de la configuración y devuelve t = 0..t_max."""
    rng = np.random.default_rng(config.seed)
    model = SirModel(config, rng)
    env = simpy.Environment()
    records: list[tuple[int, int, int, int]] = []
    env.process(sir_process(env, model, records))
    env.run()
    data = np.array(records, dtype=np.int64)
    return SirResult(time=data[:, 0], susceptible=data[:, 1], infected=data[:, 2], recovered=data[:, 3])
