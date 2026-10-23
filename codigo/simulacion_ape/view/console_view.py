"""Vista de consola: formato y salida del resumen de la corrida."""

from pathlib import Path

from ..model.replications import ReplicationSummary
from ..model.simulation import SingleRun


def format_summary(
    run: SingleRun, seed: int, csv_path: Path | None, replications: ReplicationSummary | None = None
) -> str:
    metrics = run.metrics
    lines = [
        f"Modelo SIR (Python/SimPy), semilla {seed}",
        f"Pico de infectados: {metrics.peak_infected:.0f} en t = {metrics.peak_time}",
        f"Susceptibles finales: {metrics.final_susceptible:.0f}",
        f"Recuperados finales: {metrics.final_recovered:.0f}",
        f"Tiempo de ejecución: {run.elapsed_seconds * 1000:.2f} ms",
    ]
    if csv_path is not None:
        lines.append(f"CSV escrito en: {csv_path}")
    if replications is not None:
        lines += [
            f"Réplicas ({replications.replications}, semillas 0..{replications.replications - 1}):",
            f"  Pico medio de infectados: {replications.peak_values.mean():.2f} "
            f"(desv. {replications.peak_values.std(ddof=1):.2f})",
            f"  Instante medio del pico: {replications.peak_times.mean():.2f}",
            f"  Recuperados finales medios: {replications.final_recovered.mean():.2f}",
        ]
    return "\n".join(lines)


def show_summary(
    run: SingleRun, seed: int, csv_path: Path | None, replications: ReplicationSummary | None = None
) -> None:
    print(format_summary(run, seed, csv_path, replications))


def show_figures(paths: list[Path]) -> None:
    for path in paths:
        print(f"Figura: {path}")
