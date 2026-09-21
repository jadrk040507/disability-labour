# Disability and labor-market outcomes in Mexico

[![CI](https://github.com/jadrk040507/disability-labour/actions/workflows/ci.yml/badge.svg)](https://github.com/jadrk040507/disability-labour/actions/workflows/ci.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-3776AB.svg)](https://www.python.org/)

Reproducibility materials for studying employment and income differences by
disability status in Mexico. The project combines the 2020 *Encuesta Nacional
de Ingresos y Gastos de los Hogares* (ENIGH) population, employment, and income
tables and implements descriptive comparisons and binary-outcome models.

The accompanying paper is **“Disability and Labor Market Outcomes in Mexico”**
by María José Favela Cantarero. This repository is maintained by Juan Alvaro
Díaz Raimond Kedilhac as a research-code and reproducibility project; the paper
and its empirical claims remain the author's work.

## Research design

The analysis asks how labor-force participation and earnings differ by
disability status and type. Disability indicators follow the ENIGH activity-
difficulty questions: a person is classified as disabled when an activity is
reported as very difficult or impossible. The code also constructs education,
employment, job-quality, and income measures used in the paper.

This is an observational, cross-sectional analysis. Descriptive differences
and fitted models should not be read as causal effects. Population estimates
must use the ENIGH survey design and expansion factors.

## Reproducible workflow

1. Create an environment and install the project.

   ```bash
   python -m venv .venv
   source .venv/bin/activate
   python -m pip install -e '.[dev]'
   ```

2. Download the 2020 ENIGH files from the project’s
   [OSF data deposit](https://osf.io/89ftb/) and place these tables in
   `data/raw/`:

   - `poblacion.csv`
   - `trabajos.csv`
   - `ingresos.csv`

3. Build the merged person-level file from the repository root.

   ```bash
   python scripts/python/Base_creation.py
   ```

4. Run the documented Python analysis and write machine-readable outputs.

   ```bash
   disability-labour-analyze \
     --input data/processed/disability_work.csv \
     --output-dir outputs
   ```

5. Run the automated checks.

   ```bash
   pytest
   ruff check src tests
   ```

Raw and derived person-level data are deliberately excluded from version
control. The pipeline fails with a clear message when required columns are
missing.

## Repository map

| Path | Purpose |
|---|---|
| `src/disability_labour/` | Tested transformations and statistical helpers |
| `scripts/python/` | ENIGH ingestion plus exploratory Python analyses |
| `scripts/stata/` | Stata preparation and summary-statistics variants |
| `scripts/R/` | R regression specifications |
| `tests/` | Synthetic-data tests; no confidential microdata required |
| `docs/` | Paper, source descriptor, and methodology notes |
| `outputs/` | Generated tables (ignored except for its placeholder) |

The Python package is the maintained interface. R and Stata files are retained
to document earlier specifications and may require version-specific packages.

## Outputs

The analysis command creates:

- `difference_in_means.csv`: group means, mean differences, and Welch tests;
- `probit_coefficients.csv`: coefficient estimates, standard errors, and
  p-values for the employment model;
- `analysis_metadata.json`: sample size, formula inputs, and generation time.

No generated estimates are committed. This keeps the repository independent of
restricted or locally downloaded microdata and makes every result traceable to
one execution.

## Documentation and citation

- [Methodology and variable definitions](docs/METHODOLOGY.md)
- [Original paper](docs/Disability%20and%20the%20Labor%20Market%20in%20Mexico%20Final%20Version.pdf)
- [ENIGH table descriptor](docs/descriptor.pdf)

If you reuse the research design, cite the paper. If you reuse the software,
cite this repository using [`CITATION.cff`](CITATION.cff).

## License

Code is released under the [MIT License](LICENSE). The documents and source
microdata may have separate rights and terms set by their authors or providers.
