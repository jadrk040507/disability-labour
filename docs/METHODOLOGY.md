# Methodology and variable construction

## Unit of analysis and source tables

The unit of analysis is an ENIGH 2020 household resident. Records are linked by
`folioviv`, `foliohog`, and `numren`. The build script combines:

- `poblacion.csv`: demographics, disability, education, health, and recent work;
- `trabajos.csv`: primary-job characteristics and benefits;
- `ingresos.csv`: six-month average income by source code.

Only the main job (`id_trabajo == 1`) is retained. Household employees and
guests are excluded following the grouping used in the original analysis.

## Disability measures

Eight activity domains are represented: walking, seeing, using arms or hands,
learning or concentrating, hearing, self-care, communicating, and mental or
emotional activity. The binary domain indicators equal one when the respondent
reports either a lot of difficulty or inability to perform the activity.

The maintained Python feature layer constructs three aggregates:

- `disability`: at least one of the eight domain indicators;
- `physical`: walking, arms or hands, or self-care;
- `sensory`: seeing, hearing, or communicating.

`congenital_disability` records whether any reported domain is coded as present
from birth. This is a descriptive classification, not an instrument or a claim
of exogeneity.

## Education, employment, and income

Education indicators correspond to the highest level reported in ENIGH. The
analysis command uses separate secondary, upper-secondary (`bac`), and higher-
education indicators to preserve nonlinearity.

`work_lwk` is the binary recent-employment outcome. Income variables are
six-month averages assembled from ENIGH income-source codes. The transformation
`log_other_income` equals the natural logarithm for strictly positive values and
zero otherwise; users estimating income equations should revisit this choice
and distinguish structural zeros from missing values.

## Statistical output

`difference_in_means.csv` reports unweighted group means and Welch unequal-
variance t tests. `probit_coefficients.csv` reports a complete-case probit model
with an explicit intercept. These outputs are diagnostic and reproducible, but
they are not substitutes for the paper's full specifications.

## Inference and limitations

- ENIGH is a complex survey. Population estimates require expansion factors,
  strata, and primary sampling units; the lightweight Python command does not
  yet implement design-based standard errors.
- The cross-section does not identify a causal effect of disability.
- Self-reported activity difficulty may contain measurement error.
- Work experience is proxied using years of social-security contributions and
  may be especially incomplete for informal and self-employed workers.
- Complete-case estimation can change the composition of the analysis sample.

These limitations should accompany every public interpretation of the results.
