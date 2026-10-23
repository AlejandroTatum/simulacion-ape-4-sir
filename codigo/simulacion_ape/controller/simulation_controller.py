"""Controlador: lee los argumentos, ejecuta el modelo y pide a la vista las figuras y el resumen."""

import argparse
from dataclasses import replace
from pathlib import Path

from ..model.config import DEFAULT_CSV_PATH, FIGURES_DIR, NETLOGO_CSV_PATH, SirConfig
from ..model.csv_io import read_csv
from ..model.ode import euler
from ..model.replications import run_replications
from ..model.simulation import run_single
from ..view import figures
from ..view.console_view import show_figures, show_summary


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    defaults = SirConfig()
    parser = argparse.ArgumentParser(prog="simulacion_ape", description="Modelo SIR en Python con SimPy.")
    parser.add_argument("--seed", type=int, default=defaults.seed, help="semilla de la corrida (por defecto 42)")
    parser.add_argument("--output", type=Path, default=DEFAULT_CSV_PATH, help="ruta del CSV de resultados")
    parser.add_argument("--figures-dir", type=Path, default=FIGURES_DIR, help="carpeta de las figuras")
    parser.add_argument("--replications", type=int, default=30, help="número de réplicas (semillas 0..n-1)")
    parser.add_argument("--no-figures", action="store_true", help="no generar figuras")
    return parser.parse_args(argv)


def build_figures(run, config: SirConfig, summary, figures_dir: Path) -> list[Path]:
    paths = [
        figures.plot_run(run.result, figures_dir / "sir_python.png"),
        figures.plot_vs_ode(run.result, euler(config), figures_dir / "sir_python_vs_edo.png"),
        figures.plot_replications(summary, figures_dir / "sir_replicas.png"),
    ]
    # La comparación entre herramientas solo se dibuja con los CSV que ya existan.
    results = {"Python": run.result}
    for tool, csv_path in (("NetLogo", NETLOGO_CSV_PATH),):
        if csv_path.exists():
            results[tool] = read_csv(csv_path)
    if len(results) > 1:
        paths.append(figures.plot_tool_comparison(results, figures_dir / "comparacion_herramientas.png"))
    return paths


def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    config = replace(SirConfig(), seed=args.seed)
    run = run_single(config, args.output)
    summary = run_replications(config, args.replications)
    show_summary(run, config.seed, args.output, summary)
    if not args.no_figures:
        show_figures(build_figures(run, config, summary, args.figures_dir))
