"""Small, testable statistical routines used by the command-line analysis."""

from collections.abc import Sequence

import pandas as pd
import statsmodels.api as sm
from scipy import stats

from .features import require_columns


def difference_in_means(
    frame: pd.DataFrame, group: str, variables: Sequence[str]
) -> pd.DataFrame:
    """Compare binary groups with Welch's unequal-variance t test."""
    require_columns(frame, [group, *variables])
    group_values = pd.to_numeric(frame[group], errors="coerce")
    if not set(group_values.dropna().unique()).issubset({0, 1}):
        raise ValueError(f"{group} must contain only 0, 1, or missing values")

    rows: list[dict[str, float | str | int]] = []
    for variable in variables:
        values = pd.to_numeric(frame[variable], errors="coerce")
        group_zero = values[group_values.eq(0)].dropna()
        group_one = values[group_values.eq(1)].dropna()
        test = stats.ttest_ind(group_one, group_zero, equal_var=False)
        rows.append(
            {
                "variable": variable,
                "mean_without_disability": group_zero.mean(),
                "mean_with_disability": group_one.mean(),
                "difference": group_one.mean() - group_zero.mean(),
                "t_statistic": test.statistic,
                "p_value": test.pvalue,
                "n_without_disability": len(group_zero),
                "n_with_disability": len(group_one),
            }
        )
    return pd.DataFrame(rows).set_index("variable")


def fit_probit(frame: pd.DataFrame, outcome: str, predictors: Sequence[str]):
    """Fit a complete-case probit model with an explicit intercept."""
    require_columns(frame, [outcome, *predictors])
    model_data = frame.loc[:, [outcome, *predictors]].apply(
        pd.to_numeric, errors="coerce"
    ).dropna()
    if model_data.empty:
        raise ValueError("No complete observations remain for the probit model")
    if not set(model_data[outcome].unique()).issubset({0, 1}):
        raise ValueError(f"{outcome} must be binary")

    design = sm.add_constant(model_data.loc[:, predictors], has_constant="add")
    return sm.Probit(model_data[outcome], design).fit(disp=False)
