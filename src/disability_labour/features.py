"""Deterministic feature construction for the ENIGH analysis."""

from collections.abc import Iterable

import numpy as np
import pandas as pd

DISABILITY_COLUMNS = (
    "dis_walk",
    "dis_see",
    "dis_arm",
    "dis_learn",
    "dis_hear",
    "dis_dress",
    "dis_talk",
    "dis_ment",
)

CAUSE_COLUMNS = (
    "cause_walk",
    "cause_see",
    "cause_arm",
    "cause_learn",
    "cause_hear",
    "cause_dress",
    "cause_talk",
    "cause_ment",
)


def require_columns(frame: pd.DataFrame, columns: Iterable[str]) -> None:
    """Raise a readable error when an input table lacks required variables."""
    missing = sorted(set(columns).difference(frame.columns))
    if missing:
        raise ValueError(f"Missing required columns: {', '.join(missing)}")


def add_analysis_features(frame: pd.DataFrame) -> pd.DataFrame:
    """Return a copy with the documented aggregate analysis indicators."""
    require_columns(frame, DISABILITY_COLUMNS)
    result = frame.copy()

    disability = result.loc[:, DISABILITY_COLUMNS].apply(
        pd.to_numeric, errors="coerce"
    )
    result["disability"] = disability.eq(1).any(axis=1).astype("int8")
    result["sensory"] = disability.loc[
        :, ["dis_see", "dis_hear", "dis_talk"]
    ].eq(1).any(axis=1).astype("int8")
    result["physical"] = disability.loc[
        :, ["dis_walk", "dis_arm", "dis_dress"]
    ].eq(1).any(axis=1).astype("int8")

    if set(CAUSE_COLUMNS).issubset(result.columns):
        causes = result.loc[:, CAUSE_COLUMNS].apply(pd.to_numeric, errors="coerce")
        result["congenital_disability"] = causes.eq(1).any(axis=1).astype("int8")

    education = ["secondary", "bac", "higher"]
    if set(education).issubset(result.columns):
        attained = result.loc[:, education].apply(pd.to_numeric, errors="coerce")
        result["mandatory_education"] = attained.eq(1).any(axis=1).astype("int8")

    if "other" in result.columns:
        income = pd.to_numeric(result["other"], errors="coerce")
        result["log_other_income"] = 0.0
        positive = income.gt(0)
        result.loc[positive, "log_other_income"] = np.log(income.loc[positive])

    return result
