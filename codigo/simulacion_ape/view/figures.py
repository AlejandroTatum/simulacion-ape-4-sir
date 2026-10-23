"""Figuras de matplotlib (PNG a 150 dpi, etiquetas en español)."""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from ..model.replications import ReplicationSummary
from ..model.sir_model import SirResult

DPI = 150
COLORS = {"S": "#1f77b4", "I": "#d62728", "R": "#2ca02c"}


def _save(fig, path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(path, dpi=DPI)
    plt.close(fig)
    return path


def plot_run(result: SirResult, path: Path) -> Path:
    fig, ax = plt.subplots(figsize=(7, 4.5))
    ax.plot(result.time, result.susceptible, color=COLORS["S"], label="Susceptibles")
    ax.plot(result.time, result.infected, color=COLORS["I"], label="Infectados")
    ax.plot(result.time, result.recovered, color=COLORS["R"], label="Recuperados")
    ax.set_xlabel("Tiempo")
    ax.set_ylabel("Número de individuos")
    ax.set_title("Modelo SIR en Python (SimPy)")
    ax.legend()
    ax.grid(alpha=0.3)
    return _save(fig, path)


def plot_vs_ode(result: SirResult, ode: SirResult, path: Path) -> Path:
    fig, ax = plt.subplots(figsize=(7, 4.5))
    for key, name, series, reference in (
        ("S", "Susceptibles", result.susceptible, ode.susceptible),
        ("I", "Infectados", result.infected, ode.infected),
        ("R", "Recuperados", result.recovered, ode.recovered),
    ):
        ax.plot(result.time, series, color=COLORS[key], label=f"{name} (simulación)")
        ax.plot(ode.time, reference, color=COLORS[key], linestyle="--", label=f"{name} (EDO)")
    ax.set_xlabel("Tiempo")
    ax.set_ylabel("Número de individuos")
    ax.set_title("Simulación estocástica frente a la referencia determinista")
    ax.legend(fontsize=8, ncol=2)
    ax.grid(alpha=0.3)
    return _save(fig, path)


def plot_replications(summary: ReplicationSummary, path: Path) -> Path:
    fig, ax = plt.subplots(figsize=(7, 4.5))
    for row in summary.infected_matrix:
        ax.plot(summary.time, row, color=COLORS["I"], alpha=0.12, linewidth=0.8)
    ax.fill_between(
        summary.time, summary.infected_lower, summary.infected_upper,
        color=COLORS["I"], alpha=0.25, label="Banda del 95 % entre réplicas",
    )
    ax.plot(summary.time, summary.infected_mean, color=COLORS["I"], linewidth=2, label="Media de infectados")
    ax.set_xlabel("Tiempo")
    ax.set_ylabel("Infectados")
    ax.set_title(f"Infectados en {summary.replications} réplicas")
    ax.legend()
    ax.grid(alpha=0.3)
    return _save(fig, path)


def plot_tool_comparison(results: dict[str, SirResult], path: Path) -> Path:
    """Superpone S, I y R de cada herramienta disponible en tres subgráficas."""
    fig, axes = plt.subplots(3, 1, figsize=(7, 9), sharex=True)
    styles = {"Python": "-", "NetLogo": "--"}
    for ax, (title, attribute) in zip(
        axes, (("Susceptibles", "susceptible"), ("Infectados", "infected"), ("Recuperados", "recovered"))
    ):
        for tool, result in results.items():
            ax.plot(result.time, getattr(result, attribute), linestyle=styles.get(tool, "-"), linewidth=2, label=tool)
        ax.set_ylabel(title)
        ax.grid(alpha=0.3)
        ax.legend()
    axes[-1].set_xlabel("Tiempo")
    axes[0].set_title("Comparación de herramientas")
    return _save(fig, path)
