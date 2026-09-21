import numpy as np
import pandas as pd
import pytest

from disability_labour.statistics import difference_in_means, fit_probit


def test_difference_in_means_reports_group_sizes_and_direction():
    frame = pd.DataFrame(
        {
            "disability": [0, 0, 0, 1, 1, 1],
            "employment": [1.0, 0.8, 0.6, 0.2, 0.4, 0.6],
        }
    )
    result = difference_in_means(frame, "disability", ["employment"])

    assert result.loc["employment", "difference"] == pytest.approx(-0.4)
    assert result.loc["employment", "n_without_disability"] == 3
    assert result.loc["employment", "n_with_disability"] == 3


def test_probit_adds_intercept_and_drops_incomplete_rows():
    rng = np.random.default_rng(7)
    x = rng.normal(size=250)
    probability = 1 / (1 + np.exp(-(-0.3 + 0.9 * x)))
    outcome = rng.binomial(1, probability)
    frame = pd.DataFrame({"employed": outcome, "x": x})
    frame.loc[0, "x"] = np.nan

    model = fit_probit(frame, "employed", ["x"])

    assert "const" in model.params.index
    assert model.nobs == 249
