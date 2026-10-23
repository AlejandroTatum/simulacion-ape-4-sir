"""Réplicas independientes del modelo (semillas first_seed..first_seed+n-1) y su resumen estadístico."""

from dataclasses import dataclass, replace

import numpy as np

from .config import SirConfig
from .sir_model import run_sir


@dataclass(frozen=True)
class ReplicationSummary:
    time: np.ndarray
    infected_matrix: np.ndarray  # forma (réplicas, t_max + 1)
    infected_mean: np.ndarray
    infected_lower: np.ndarray  # percentil 2.5 entre réplicas
    infected_upper: np.ndarray  # percentil 97.5 entre réplicas
    peak_values: np.ndarray
    peak_times: np.ndarray
    final_recovered: np.ndarray

    @property
    def replications(self) -> int:
        return self.infected_matrix.shape[0]


def run_replications(config: SirConfig, replications: int = 30, first_seed: int = 0) -> ReplicationSummary:
    results = [run_sir(replace(config, seed=first_seed + k)) for k in range(replications)]
    infected = np.array([result.infected for result in results])
    return ReplicationSummary(
        time=results[0].time,
        infected_matrix=infected,
        infected_mean=infected.mean(axis=0),
        infected_lower=np.percentile(infected, 2.5, axis=0),
        infected_upper=np.percentile(infected, 97.5, axis=0),
        peak_values=infected.max(axis=1),
        peak_times=infected.argmax(axis=1),
        final_recovered=np.array([result.recovered[-1] for result in results]),
    )
