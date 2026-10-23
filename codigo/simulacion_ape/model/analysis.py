"""Métricas de una corrida: pico de infectados y recuperados finales."""

from dataclasses import dataclass

from .sir_model import SirResult


@dataclass(frozen=True)
class RunMetrics:
    peak_infected: float
    peak_time: int
    final_susceptible: float
    final_recovered: float


def compute_metrics(result: SirResult) -> RunMetrics:
    # argmax devuelve el primer máximo, es decir, el instante más temprano del pico.
    peak_index = int(result.infected.argmax())
    return RunMetrics(
        peak_infected=float(result.infected[peak_index]),
        peak_time=int(result.time[peak_index]),
        final_susceptible=float(result.susceptible[-1]),
        final_recovered=float(result.recovered[-1]),
    )
