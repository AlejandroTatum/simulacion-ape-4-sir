"""Referencia determinista: ecuaciones diferenciales del SIR resueltas con Euler (dt = 1) y RK4."""

import numpy as np

from .config import SirConfig
from .sir_model import SirResult


def _derivatives(y: np.ndarray, beta: float, gamma: float, population: int) -> np.ndarray:
    s, i, _ = y
    new_infections = beta * s * i / population
    return np.array([-new_infections, new_infections - gamma * i, gamma * i])


def euler(config: SirConfig, dt: float = 1.0) -> SirResult:
    """Integra con Euler y devuelve los valores en los instantes enteros t = 0..t_max (conteos reales, sin redondear)."""
    steps_per_unit = round(1 / dt)
    y = np.array([config.initial_susceptible, config.initial_infected, 0.0])
    rows = [y.copy()]
    for _ in range(config.t_max):
        for _ in range(steps_per_unit):
            y = y + dt * _derivatives(y, config.beta, config.gamma, config.population)
        rows.append(y.copy())
    return _to_result(np.array(rows), config.t_max)


def rk4(config: SirConfig, dt: float = 0.01) -> SirResult:
    """Integra con Runge-Kutta de orden 4 y un paso pequeño; devuelve los instantes enteros."""
    steps_per_unit = round(1 / dt)
    args = (config.beta, config.gamma, config.population)
    y = np.array([config.initial_susceptible, config.initial_infected, 0.0])
    rows = [y.copy()]
    for _ in range(config.t_max):
        for _ in range(steps_per_unit):
            k1 = _derivatives(y, *args)
            k2 = _derivatives(y + dt / 2 * k1, *args)
            k3 = _derivatives(y + dt / 2 * k2, *args)
            k4 = _derivatives(y + dt * k3, *args)
            y = y + dt / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
        rows.append(y.copy())
    return _to_result(np.array(rows), config.t_max)


def _to_result(rows: np.ndarray, t_max: int) -> SirResult:
    # Los arreglos son flotantes: es una referencia continua, no un conteo entero.
    return SirResult(
        time=np.arange(t_max + 1),
        susceptible=rows[:, 0],
        infected=rows[:, 1],
        recovered=rows[:, 2],
    )
