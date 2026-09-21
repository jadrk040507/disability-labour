import numpy as np
import pandas as pd
import pytest

from disability_labour.features import add_analysis_features


def base_frame() -> pd.DataFrame:
    return pd.DataFrame(
        {
            "dis_walk": [0, 1, 0],
            "dis_see": [0, 0, 0],
            "dis_arm": [0, 0, 0],
            "dis_learn": [0, 0, 0],
            "dis_hear": [0, 0, 1],
            "dis_dress": [0, 0, 0],
            "dis_talk": [0, 0, 0],
            "dis_ment": [0, 0, 0],
        }
    )


def test_builds_disability_domain_indicators_without_mutating_input():
    source = base_frame()
    result = add_analysis_features(source)

    assert result["disability"].tolist() == [0, 1, 1]
    assert result["physical"].tolist() == [0, 1, 0]
    assert result["sensory"].tolist() == [0, 0, 1]
    assert "disability" not in source.columns


def test_log_income_is_zero_for_nonpositive_values():
    source = base_frame().assign(other=[100.0, 0.0, -5.0])
    result = add_analysis_features(source)

    assert result["log_other_income"].tolist() == pytest.approx(
        [np.log(100.0), 0.0, 0.0]
    )


def test_reports_missing_disability_columns():
    with pytest.raises(ValueError, match="dis_ment"):
        add_analysis_features(base_frame().drop(columns="dis_ment"))
