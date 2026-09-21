"""Command-line entry point for reproducible analysis outputs."""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

from .features import add_analysis_features
from .statistics import difference_in_means, fit_probit

SUMMARY_VARIABLES = (
    "work_lwk",
    "age",
    "female",
    "married",
    "health_prob",
    "secondary",
    "bac",
    "higher",
)

PROBIT_PREDICTORS = (
    "disability",
    "age",
    "female",
    "married",
    "secondary",
    "bac",
    "higher",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Analyze a processed ENIGH person-level dataset."
    )
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, default=Path("outputs"))
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    frame = add_analysis_features(pd.read_csv(args.input, low_memory=False))
    args.output_dir.mkdir(parents=True, exist_ok=True)

    summary = difference_in_means(frame, "disability", SUMMARY_VARIABLES)
    summary.to_csv(args.output_dir / "difference_in_means.csv")

    model = fit_probit(frame, "work_lwk", PROBIT_PREDICTORS)
    coefficients = pd.DataFrame(
        {
            "coefficient": model.params,
            "standard_error": model.bse,
            "p_value": model.pvalues,
        }
    )
    coefficients.to_csv(args.output_dir / "probit_coefficients.csv")

    metadata = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "input": str(args.input),
        "observations_loaded": len(frame),
        "probit_observations": int(model.nobs),
        "outcome": "work_lwk",
        "predictors": list(PROBIT_PREDICTORS),
    }
    (args.output_dir / "analysis_metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
