import subprocess
import sys
from dataclasses import replace
from pathlib import Path

import numpy as np

from simulacion_ape.model.config import CSV_HEADER, SirConfig
from simulacion_ape.model.csv_io import read_csv, write_csv
from simulacion_ape.model.ode import euler, rk4
from simulacion_ape.model.replications import run_replications
from simulacion_ape.model.sir_model import run_sir


def test_csv_has_exact_header_and_101_rows(tmp_path):
    path = tmp_path / "resultados.csv"
    write_csv(run_sir(SirConfig()), path)
    raw = path.read_bytes()
    assert not raw.startswith(b"\xef\xbb\xbf") and b"\r" not in raw and raw.endswith(b"\n")
    lines = raw.decode("utf-8").splitlines()
    assert lines[0] == CSV_HEADER
    assert len(lines) == 102
    assert [line.split(",")[0] for line in lines[1:]] == [str(t) for t in range(101)]


def test_csv_round_trip(tmp_path):
    result = run_sir(SirConfig())
    write_csv(result, tmp_path / "r.csv")
    loaded = read_csv(tmp_path / "r.csv")
    assert np.array_equal(loaded.infected, result.infected)
    assert np.array_equal(loaded.recovered, result.recovered)


def test_population_is_conserved_and_initial_state():
    result = run_sir(SirConfig())
    assert np.all(result.susceptible + result.infected + result.recovered == 100)
    assert (result.susceptible[0], result.infected[0], result.recovered[0]) == (95, 5, 0)


def test_same_seed_is_identical_and_different_seed_differs():
    a, b = run_sir(SirConfig(seed=7)), run_sir(SirConfig(seed=7))
    c = run_sir(SirConfig(seed=8))
    assert np.array_equal(a.infected, b.infected) and np.array_equal(a.susceptible, b.susceptible)
    assert not np.array_equal(a.infected, c.infected)


def test_susceptible_never_increases_and_recovered_never_decreases():
    for seed in range(5):
        result = run_sir(SirConfig(seed=seed))
        assert np.all(np.diff(result.susceptible) <= 0)
        assert np.all(np.diff(result.recovered) >= 0)


def test_zero_beta_produces_no_new_infections():
    result = run_sir(replace(SirConfig(), beta=0.0))
    assert np.all(result.susceptible == 95)
    assert np.all(result.infected <= 5)


def test_ode_reference_conserves_population_and_euler_is_close_to_rk4():
    config = SirConfig()
    for ode in (euler(config), rk4(config)):
        assert np.allclose(ode.susceptible + ode.infected + ode.recovered, 100)
    assert abs(euler(config).recovered[-1] - rk4(config).recovered[-1]) < 10


def test_replications_summary_shapes_and_seeds():
    summary = run_replications(SirConfig(), replications=5)
    assert summary.infected_matrix.shape == (5, 101)
    assert np.array_equal(summary.infected_matrix[2], run_sir(replace(SirConfig(), seed=2)).infected)
    assert np.all(summary.infected_lower <= summary.infected_mean + 1e-9)
    assert np.all(summary.infected_mean <= summary.infected_upper + 1e-9)


def test_entry_point_runs_when_executed_by_file_path(tmp_path):
    # El botón "Run" del editor ejecuta el archivo por ruta, no con python -m.
    main_file = Path(__file__).resolve().parents[1] / "simulacion_ape" / "__main__.py"
    output = tmp_path / "resultados_python.csv"
    result = subprocess.run(
        [sys.executable, str(main_file), "--output", str(output), "--figures-dir", str(tmp_path / "figuras")],
        cwd=tmp_path, capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stderr
    assert len(output.read_text(encoding="utf-8").splitlines()) == 102
    assert (tmp_path / "figuras" / "sir_python.png").exists()
