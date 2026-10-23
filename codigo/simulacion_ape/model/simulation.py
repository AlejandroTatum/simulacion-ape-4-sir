"""Orquestación de corridas: una corrida cronometrada con su CSV y sus métricas."""

import time
from dataclasses import dataclass
from pathlib import Path

from .analysis import RunMetrics, compute_metrics
from .config import SirConfig
from .csv_io import write_csv
from .sir_model import SirResult, run_sir


@dataclass(frozen=True)
class SingleRun:
    result: SirResult
    metrics: RunMetrics
    elapsed_seconds: float


def run_single(config: SirConfig, csv_path: Path | None = None) -> SingleRun:
    """Corre la simulación midiendo solo el tiempo del modelo y, si se indica, escribe el CSV."""
    start = time.perf_counter()
    result = run_sir(config)
    elapsed = time.perf_counter() - start
    if csv_path is not None:
        write_csv(result, csv_path)
    return SingleRun(result=result, metrics=compute_metrics(result), elapsed_seconds=elapsed)
