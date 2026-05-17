# `kronxNBC` Usage Examples

**Package:** `kronxNBC`  
**Version inspected:** `0.1.0`  
**Core function:** `student_t_naive_bayes()`  
**Framework:** Clock of Regimes (COR) heavy-tailed regime classification

---

## 1. Purpose of the Package

The `kronxNBC` package implements a **Student-t Naive Bayes classifier** designed for financial regime classification under the **Clock of Regimes (COR)** framework.

Unlike Gaussian Naive Bayes, this classifier estimates a scaled Student-t likelihood for every class-feature pair:

\[
X_j \mid S = k \sim t_{\nu_{kj}}(\mu_{kj}, \sigma_{kj}).
\]

The package estimates:

- `mu`: class-conditional location,
- `sd`: class-conditional scale,
- `nu`: class-conditional tail thickness,
- `prior`: class prior probabilities.

The key COR interpretation is:

| Estimated Quantity | COR Interpretation |
|---|---|
| Low `sd` | quiet, stable local behavior |
| High `sd` | elevated regime volatility |
| High `nu` | near-Gaussian, thin-tailed regime |
| Low `nu` | fat-tailed, fragile stress regime |
| High posterior Stress probability | regime fragility signal |

---

## 2. Install the Package from a Local Tarball

From R:

```r
install.packages(
  "kronxNBC_0.1.0.tar.gz",
  repos = NULL,
  type  = "source"
)
```

Then load it:

```r
library(kronxNBC)
```

If the tarball is in another directory, provide the full path:

```r
install.packages(
  "/Users/yourname/path/to/kronxNBC_0.1.0.tar.gz",
  repos = NULL,
  type  = "source"
)
```

---

## 3. Inspect the Main Function

```r
?student_t_naive_bayes
?predict.student_t_naive_bayes
?tables
?coef.student_t_naive_bayes
?plot.student_t_naive_bayes
```

The principal call is:

```r
model <- student_t_naive_bayes(
  x       = X,
  y       = y,
  prior   = NULL,
  nu_grid = c(3:30, 40, 60, 100)
)
```

Arguments:

| Argument | Meaning |
|---|---|
| `x` | Numeric matrix of predictors. Must have column names. |
| `y` | Factor, character, or logical class labels. |
| `prior` | Optional class prior vector. If omitted, empirical frequencies are used. |
| `nu_grid` | Candidate Student-t degrees of freedom. All values must be greater than 2. |

---

## 4. Minimal Working Example

This is the smallest complete example.

```r
#!/usr/local/bin/Rscript

library(kronxNBC)

set.seed(42)

n_per <- 50L

y <- factor(
  rep(c("Calm", "Stress", "Trend"), each = n_per),
  levels = c("Calm", "Stress", "Trend")
)

X <- rbind(
  cbind(
    ret = rnorm(n_per, mean = 0.000, sd = 0.005),
    vol = rnorm(n_per, mean = 0.010, sd = 0.002),
    dd  = rnorm(n_per, mean = -0.002, sd = 0.002)
  ),
  cbind(
    ret = rt(n_per, df = 3) * 0.020,
    vol = rnorm(n_per, mean = 0.040, sd = 0.008),
    dd  = rnorm(n_per, mean = -0.050, sd = 0.020)
  ),
  cbind(
    ret = rnorm(n_per, mean = 0.001, sd = 0.009),
    vol = rnorm(n_per, mean = 0.020, sd = 0.004),
    dd  = rnorm(n_per, mean = -0.015, sd = 0.006)
  )
)

model <- student_t_naive_bayes(X, y)

print(model)
summary(model)
```

Expected result:

- The model should return an object of class `student_t_naive_bayes`.
- The Stress class should generally show higher volatility and lower `nu` on fat-tailed variables.

---

## 5. Example: Fit, Predict, and Evaluate Accuracy

```r
#!/usr/local/bin/Rscript

library(kronxNBC)

set.seed(123)

n_per <- 120L

y <- factor(
  rep(c("Calm", "Steady", "Stress"), each = n_per),
  levels = c("Calm", "Steady", "Stress")
)

X <- rbind(
  cbind(
    log_return         = rnorm(n_per, 0.0002, 0.003),
    rolling_volatility = abs(rnorm(n_per, 0.004, 0.001)),
    drawdown           = rnorm(n_per, -0.002, 0.002),
    transition_stress  = abs(rnorm(n_per, 0.001, 0.0005)),
    residence_pressure = rpois(n_per, 1),
    ruin_proxy         = rbeta(n_per, 1, 20)
  ),
  cbind(
    log_return         = rnorm(n_per, 0.0005, 0.006),
    rolling_volatility = abs(rnorm(n_per, 0.009, 0.002)),
    drawdown           = rnorm(n_per, -0.010, 0.004),
    transition_stress  = abs(rnorm(n_per, 0.004, 0.001)),
    residence_pressure = rpois(n_per, 4),
    ruin_proxy         = rbeta(n_per, 2, 10)
  ),
  cbind(
    log_return         = rt(n_per, df = 3) * 0.018,
    rolling_volatility = abs(rnorm(n_per, 0.025, 0.006)),
    drawdown           = rnorm(n_per, -0.040, 0.015),
    transition_stress  = abs(rnorm(n_per, 0.018, 0.006)),
    residence_pressure = rpois(n_per, 12),
    ruin_proxy         = rbeta(n_per, 5, 3)
  )
)

# Random split for diagnostic regime classification.
idx_train <- sample(seq_len(nrow(X)), size = floor(0.80 * nrow(X)))

X_train <- X[idx_train, , drop = FALSE]
y_train <- y[idx_train]

X_test  <- X[-idx_train, , drop = FALSE]
y_test  <- y[-idx_train]

model <- student_t_naive_bayes(
  x       = X_train,
  y       = y_train,
  nu_grid = c(3:30, 40, 60, 100)
)

pred_class <- predict(model, newdata = X_test, type = "class")
pred_prob  <- predict(model, newdata = X_test, type = "prob")

confusion <- table(True = y_test, Predicted = pred_class)
accuracy  <- mean(pred_class == y_test)

print(confusion)
cat("\nAccuracy:", round(accuracy, 4), "\n")
cat("\nFirst six posterior probability rows:\n")
print(round(head(pred_prob), 4))
```

Interpretation:

- `predict(..., type = "class")` gives the maximum posterior class.
- `predict(..., type = "prob")` gives posterior probabilities for every regime.
- A high Stress posterior is a supervised fragility warning.

---

## 6. Example: Extract Fitted Student-t Parameters

```r
params <- coef(model)
print(round(params, 6))
```

The coefficient table has one row per feature and grouped columns by class:

```text
Calm:mu    Calm:sd    Calm:nu    Steady:mu    Steady:sd    Steady:nu    Stress:mu    Stress:sd    Stress:nu
```

A COR-style reading:

| Feature | What to Inspect |
|---|---|
| `log_return` | tail thickness of returns by regime |
| `rolling_volatility` | volatility separation across regimes |
| `drawdown` | severity of regime deterioration |
| `transition_stress` | downside semi-deviation pressure |
| `residence_pressure` | persistence of adverse states |
| `ruin_proxy` | local probability of extreme loss |

To inspect only the fitted `nu` matrix:

```r
print(model$params$nu)
```

A healthy COR fit usually gives:

```text
Stress nu < Steady nu < Calm nu
```

especially for return-like or downside-sensitive features.

---

## 7. Example: Use `tables()` for Per-Feature Parameter Tables

Return all tables:

```r
tabs <- tables(model)
print(tabs)
```

Return one feature by name:

```r
tables(model, which = "log_return")
```

Return one feature by position:

```r
tables(model, which = 2L)
```

Each table contains:

| Row | Meaning |
|---|---|
| `mu` | fitted Student-t location |
| `sd` | fitted Student-t scale |
| `nu` | fitted Student-t tail thickness |

Example interpretation:

```r
tables(model, which = "ruin_proxy")
```

If the Stress column has a higher `mu` for `ruin_proxy`, the classifier has learned that Stress corresponds to higher local ruin probability.

---

## 8. Example: Plot Fitted Student-t Densities

Plot all features:

```r
plot(model)
```

Plot one feature:

```r
plot(model, which = "log_return")
```

Plot conditional densities instead of prior-weighted marginal densities:

```r
plot(model, which = "log_return", prob = "conditional")
```

Plot multiple selected features:

```r
plot(model, which = c("log_return", "drawdown", "ruin_proxy"))
```

Add boxed legend:

```r
plot(model, which = "rolling_volatility", legend.box = TRUE)
```

Interpretation:

- Overlapping curves imply weaker class separation.
- A Stress density with wide support and low `nu` signals heavy-tailed fragility.
- A Calm density that is narrow and centered near zero indicates stable market behavior.

---

## 9. Example: Custom Class Priors

By default, class priors are empirical class frequencies.

For imbalanced financial data, Stress observations may be rare. You can impose custom priors:

```r
custom_prior <- c(
  Calm   = 0.60,
  Steady = 0.30,
  Stress = 0.10
)

model_prior <- student_t_naive_bayes(
  x     = X_train,
  y     = y_train,
  prior = custom_prior
)

print(model_prior$prior)
```

The package normalizes the supplied prior to sum to one.

Alternative stress-sensitive prior:

```r
stress_sensitive_prior <- c(
  Calm   = 0.45,
  Steady = 0.30,
  Stress = 0.25
)

model_stress_sensitive <- student_t_naive_bayes(
  x     = X_train,
  y     = y_train,
  prior = stress_sensitive_prior
)
```

COR interpretation:

- Conservative risk management may assign a higher prior to Stress.
- Tactical classification may use empirical priors.
- Crisis monitoring may intentionally overweight rare Stress states.

---

## 10. Example: Classify a New Market Observation

Suppose a new ES observation has the following COR features:

```r
new_obs <- matrix(
  c(
    -0.018,  # log_return
     0.027,  # rolling_volatility
    -0.045,  # drawdown
     0.019,  # transition_stress
    14.000,  # residence_pressure
     0.720   # ruin_proxy
  ),
  nrow = 1,
  dimnames = list(NULL, colnames(X_train))
)

predict(model, newdata = new_obs, type = "class")
predict(model, newdata = new_obs, type = "prob")
```

Expected COR interpretation:

- Large negative return,
- high volatility,
- deep drawdown,
- elevated downside semi-deviation,
- high residence pressure,
- high ruin proxy,

should produce a high posterior probability for `Stress`.

---

## 11. Example: Real CSV Workflow

Assume you have a CSV file named `cor_features.csv` with this structure:

```text
timestamp,log_return,rolling_volatility,drawdown,transition_stress,residence_pressure,ruin_proxy,regime
2026-01-02 10:00:00,0.0004,0.0041,-0.0010,0.0008,0,0.02,Calm
2026-01-02 11:00:00,-0.0060,0.0110,-0.0120,0.0040,3,0.15,Steady
2026-01-02 12:00:00,-0.0230,0.0300,-0.0520,0.0200,15,0.78,Stress
```

Run:

```r
#!/usr/local/bin/Rscript

library(kronxNBC)

cor_data <- read.csv("cor_features.csv", stringsAsFactors = FALSE)

features <- c(
  "log_return",
  "rolling_volatility",
  "drawdown",
  "transition_stress",
  "residence_pressure",
  "ruin_proxy"
)

cor_data$regime <- factor(
  cor_data$regime,
  levels = c("Calm", "Steady", "Stress")
)

complete_idx <- complete.cases(cor_data[, c(features, "regime")])
cor_data <- cor_data[complete_idx, ]

X <- as.matrix(cor_data[, features])
y <- cor_data$regime

set.seed(123)
idx_train <- sample(seq_len(nrow(X)), floor(0.80 * nrow(X)))

X_train <- X[idx_train, , drop = FALSE]
y_train <- y[idx_train]
X_test  <- X[-idx_train, , drop = FALSE]
y_test  <- y[-idx_train]

model <- student_t_naive_bayes(X_train, y_train)

pred <- predict(model, X_test, type = "class")
prob <- predict(model, X_test, type = "prob")

print(table(True = y_test, Predicted = pred))
cat("Accuracy:", mean(pred == y_test), "\n")

out <- data.frame(
  timestamp = cor_data$timestamp[-idx_train],
  true      = y_test,
  predicted = pred,
  prob
)

write.csv(out, "kronxNBC_predictions.csv", row.names = FALSE)
write.csv(coef(model), "kronxNBC_fitted_parameters.csv")
```

Outputs:

| File | Meaning |
|---|---|
| `kronxNBC_predictions.csv` | predicted class and posterior probabilities |
| `kronxNBC_fitted_parameters.csv` | fitted `mu`, `sd`, and `nu` parameters |

---

## 12. Example: Feature Engineering from Prices

This example creates COR features from a price series.

Input CSV format:

```text
timestamp,close
2026-01-02 10:00:00,5000.25
2026-01-02 11:00:00,5002.75
2026-01-02 12:00:00,4980.50
```

Feature engineering script:

```r
#!/usr/local/bin/Rscript

library(zoo)

price_data <- read.csv("prices.csv", stringsAsFactors = FALSE)

price_data$log_return <- c(NA, diff(log(price_data$close)))
price_data <- price_data[!is.na(price_data$log_return), ]

n_roll <- 24L

rolling_volatility <- rollapply(
  price_data$log_return,
  width = n_roll,
  FUN = sd,
  fill = NA,
  align = "right"
)
rolling_volatility <- pmax(rolling_volatility, 0.0001)

rolling_max <- rollapply(
  price_data$close,
  width = n_roll,
  FUN = max,
  fill = NA,
  align = "right"
)

drawdown <- (price_data$close - rolling_max) / rolling_max

downside_dev <- function(x) {
  neg_x <- x[x < 0]
  if (length(neg_x) == 0L) return(0)
  sqrt(mean(neg_x^2))
}

transition_stress <- rollapply(
  price_data$log_return,
  width = n_roll,
  FUN = downside_dev,
  fill = NA,
  align = "right"
)
transition_stress <- pmax(transition_stress, 0.0001)

is_dd <- ifelse(drawdown < -0.005, 1L, 0L)
is_dd[is.na(is_dd)] <- 0L

residence_pressure <- ave(
  is_dd,
  cumsum(is_dd == 0L),
  FUN = cumsum
)
residence_pressure <- pmax(residence_pressure, 0.0001)

rolling_mean <- rollapply(
  price_data$log_return,
  width = n_roll,
  FUN = mean,
  fill = NA,
  align = "right"
)

ruin_proxy <- pnorm(
  -0.02,
  mean = rolling_mean,
  sd   = rolling_volatility
)
ruin_proxy <- pmax(ruin_proxy, 0.0001)

cor_features <- data.frame(
  timestamp          = price_data$timestamp,
  log_return         = price_data$log_return,
  rolling_volatility = rolling_volatility,
  drawdown           = drawdown,
  transition_stress  = transition_stress,
  residence_pressure = residence_pressure,
  ruin_proxy         = ruin_proxy
)

cor_features <- cor_features[complete.cases(cor_features), ]

write.csv(cor_features, "cor_features_unlabeled.csv", row.names = FALSE)
```

To train the classifier, you still need labels such as:

- decoded HMM states,
- manually labeled regimes,
- Viterbi states,
- threshold-defined regimes.

---

## 13. Example: Add Labels from Decoded HMM States

Suppose you have:

```text
decoded_states.csv
```

with:

```text
timestamp,state
2026-01-02 10:00:00,2
2026-01-02 11:00:00,2
2026-01-02 12:00:00,1
```

Map HMM states into COR labels:

```r
decoded <- read.csv("decoded_states.csv", stringsAsFactors = FALSE)
cor_features <- read.csv("cor_features_unlabeled.csv", stringsAsFactors = FALSE)

stopifnot(nrow(decoded) == nrow(cor_features))

state_labels <- c(
  "1" = "Stress",
  "2" = "Calm",
  "3" = "Steady"
)

cor_features$regime <- factor(
  state_labels[as.character(decoded$state)],
  levels = c("Calm", "Steady", "Stress")
)

write.csv(cor_features, "cor_features_labeled.csv", row.names = FALSE)
```

Then train:

```r
library(kronxNBC)

features <- c(
  "log_return",
  "rolling_volatility",
  "drawdown",
  "transition_stress",
  "residence_pressure",
  "ruin_proxy"
)

X <- as.matrix(cor_features[, features])
y <- cor_features$regime

model <- student_t_naive_bayes(X, y)
summary(model)
```

---

## 14. Example: COR Operator Interpretation After Classification

The classifier gives posterior regime probabilities. These can feed a COR operator layer.

Define a transition matrix:

```r
A <- matrix(
  c(
    0.96, 0.035, 0.005,
    0.08, 0.86,  0.06,
    0.03, 0.17,  0.80
  ),
  nrow = 3,
  byrow = TRUE,
  dimnames = list(
    c("Calm", "Steady", "Stress"),
    c("Calm", "Steady", "Stress")
  )
)
```

Use regime-level tail thickness estimates:

```r
nu_by_regime <- rowMeans(model$params$nu)
print(nu_by_regime)
```

Construct Talebian hazards:

```r
eps_min  <- 0.01
c_hazard <- 0.05

epsilon <- eps_min + c_hazard / nu_by_regime
print(epsilon)
```

Build COR operators:

```r
Q <- diag(1 - epsilon) %*% A
K <- Q - diag(nrow(Q))
N <- solve(-K)

rho_N <- max(Mod(eigen(N)$values))

cat("\nQ operator:\n")
print(round(Q, 5))

cat("\nKilled generator K = Q - I:\n")
print(round(K, 5))

cat("\nFundamental matrix N = -K^{-1}:\n")
print(round(N, 5))

cat("\nSpectral fragility rho(N):", round(rho_N, 5), "\n")
```

Interpretation:

| COR Object | Meaning |
|---|---|
| `Q` | open-system transition operator with leakage |
| `K` | killed generator |
| `N` | expected residence-time geometry |
| `rho_N` | spectral fragility / persistence index |

---

## 15. Example: Posterior-Weighted COR Fragility Score

Use the classifier posterior probabilities to produce a time-varying fragility score.

```r
prob <- predict(model, X, type = "prob")

nu_by_regime <- rowMeans(model$params$nu)
epsilon <- eps_min + c_hazard / nu_by_regime

epsilon <- epsilon[colnames(prob)]

fragility_score <- as.numeric(prob %*% epsilon)

cor_signal <- data.frame(
  regime_hat      = predict(model, X, type = "class"),
  prob,
  fragility_score = fragility_score
)

head(cor_signal)
```

Interpretation:

- Low score: posterior mass concentrated in Calm.
- Intermediate score: posterior mass concentrated in Steady.
- High score: posterior mass concentrated in Stress.

Save the result:

```r
write.csv(cor_signal, "kronxNBC_cor_fragility_signal.csv", row.names = FALSE)
```

---

## 16. Example: Stress Alert Rule

A simple supervised COR alert can be defined as:

```r
prob <- predict(model, X, type = "prob")

stress_alert <- prob[, "Stress"] > 0.70

alerts <- data.frame(
  stress_probability = prob[, "Stress"],
  stress_alert       = stress_alert
)

table(alerts$stress_alert)
```

A stricter rule combines posterior probability and fragility score:

```r
fragility_score <- as.numeric(prob %*% epsilon[colnames(prob)])

stress_alert_2 <- prob[, "Stress"] > 0.60 & fragility_score > quantile(fragility_score, 0.90)

table(stress_alert_2)
```

COR interpretation:

- Posterior Stress probability measures current class membership.
- Fragility score measures structural hazard-weighted exposure.
- The combined rule prevents overreacting to isolated noisy observations.

---

## 17. Example: Save and Reload the Fitted Model

Save:

```r
saveRDS(model, "kronxNBC_student_t_model.rds")
```

Reload:

```r
model2 <- readRDS("kronxNBC_student_t_model.rds")

predict(model2, X_test, type = "prob")
```

This is useful for production workflows where the model is trained once and then reused for scoring new data.

---

## 18. Example: Complete Script for Synthetic COR Demonstration

Save this as:

```text
run_kronxNBC_synthetic_COR_example.R
```

```r
#!/usr/local/bin/Rscript

library(kronxNBC)

set.seed(20260516)

n_per <- 250L
classes <- c("Calm", "Steady", "Stress")

y <- factor(rep(classes, each = n_per), levels = classes)

X <- rbind(
  cbind(
    log_return         = rnorm(n_per, 0.0002, 0.003),
    rolling_volatility = abs(rnorm(n_per, 0.004, 0.001)),
    drawdown           = rnorm(n_per, -0.002, 0.002),
    transition_stress  = abs(rnorm(n_per, 0.001, 0.0005)),
    residence_pressure = rpois(n_per, 1),
    ruin_proxy         = rbeta(n_per, 1, 20)
  ),
  cbind(
    log_return         = rnorm(n_per, 0.0005, 0.006),
    rolling_volatility = abs(rnorm(n_per, 0.009, 0.002)),
    drawdown           = rnorm(n_per, -0.010, 0.004),
    transition_stress  = abs(rnorm(n_per, 0.004, 0.001)),
    residence_pressure = rpois(n_per, 4),
    ruin_proxy         = rbeta(n_per, 2, 10)
  ),
  cbind(
    log_return         = rt(n_per, df = 3) * 0.018,
    rolling_volatility = abs(rnorm(n_per, 0.025, 0.006)),
    drawdown           = rnorm(n_per, -0.040, 0.015),
    transition_stress  = abs(rnorm(n_per, 0.018, 0.006)),
    residence_pressure = rpois(n_per, 12),
    ruin_proxy         = rbeta(n_per, 5, 3)
  )
)

set.seed(123)
idx_train <- sample(seq_len(nrow(X)), floor(0.80 * nrow(X)))

X_train <- X[idx_train, , drop = FALSE]
y_train <- y[idx_train]
X_test  <- X[-idx_train, , drop = FALSE]
y_test  <- y[-idx_train]

model <- student_t_naive_bayes(
  x       = X_train,
  y       = y_train,
  nu_grid = c(3:30, 40, 60, 100)
)

cat("\n--- Model Summary ---\n")
summary(model)

cat("\n--- Fitted Parameters ---\n")
print(round(coef(model), 6))

pred_class <- predict(model, X_test, type = "class")
pred_prob  <- predict(model, X_test, type = "prob")

cat("\n--- Confusion Matrix ---\n")
print(table(True = y_test, Predicted = pred_class))

cat("\nAccuracy:", round(mean(pred_class == y_test), 4), "\n")

cat("\n--- First 10 Posterior Probabilities ---\n")
print(round(head(pred_prob, 10), 4))

# COR operator layer
A <- matrix(
  c(
    0.96, 0.035, 0.005,
    0.08, 0.86,  0.06,
    0.03, 0.17,  0.80
  ),
  nrow = 3,
  byrow = TRUE,
  dimnames = list(classes, classes)
)

eps_min  <- 0.01
c_hazard <- 0.05

nu_by_regime <- rowMeans(model$params$nu)
epsilon <- eps_min + c_hazard / nu_by_regime

Q <- diag(1 - epsilon) %*% A
K <- Q - diag(3)
N <- solve(-K)
rho_N <- max(Mod(eigen(N)$values))

cat("\n--- COR Tail Thickness by Regime ---\n")
print(round(nu_by_regime, 4))

cat("\n--- COR Hazard by Regime ---\n")
print(round(epsilon, 6))

cat("\n--- Fundamental Matrix N ---\n")
print(round(N, 4))

cat("\nSpectral fragility rho(N):", round(rho_N, 4), "\n")

# Posterior-weighted fragility
prob_all <- predict(model, X, type = "prob")
epsilon_ordered <- epsilon[colnames(prob_all)]
fragility_score <- as.numeric(prob_all %*% epsilon_ordered)

signal <- data.frame(
  regime_true     = y,
  regime_hat      = predict(model, X, type = "class"),
  prob_all,
  fragility_score = fragility_score
)

write.csv(signal, "kronxNBC_synthetic_COR_signal.csv", row.names = FALSE)
write.csv(coef(model), "kronxNBC_synthetic_parameters.csv")

cat("\nFiles written:\n")
cat("- kronxNBC_synthetic_COR_signal.csv\n")
cat("- kronxNBC_synthetic_parameters.csv\n")
```

Run from terminal:

```bash
Rscript run_kronxNBC_synthetic_COR_example.R
```

---

## 19. Common Errors and Fixes

### Error: `x must be a numeric matrix`

Cause: `x` is a data frame with non-numeric columns.

Fix:

```r
X <- as.matrix(data[, features])
storage.mode(X) <- "double"
```

---

### Error: `x must have unique column names`

Cause: the predictor matrix has no column names.

Fix:

```r
colnames(X) <- c("log_return", "rolling_volatility", "drawdown")
```

---

### Error: `y must contain at least two classes`

Cause: all labels are the same after filtering.

Fix:

```r
table(y)
```

Check that at least two regimes are present.

---

### Error: `each class must have at least two observations`

Cause: one regime has fewer than two rows.

Fix:

```r
table(y)
```

Then remove extremely rare classes or increase the sample size.

---

### Error: `nu_grid must be numeric with all values > 2`

Cause: Student-t variance is finite only for `nu > 2`.

Fix:

```r
nu_grid <- c(3:30, 40, 60, 100)
```

---

## 20. Recommended COR Workflow

The recommended end-to-end workflow is:

```text
Price data
   |
   v
Log returns
   |
   v
COR feature engineering
   |
   v
HMM / Viterbi / manual regime labels
   |
   v
student_t_naive_bayes()
   |
   v
Posterior regime probabilities
   |
   v
Tail-thickness extraction: nu
   |
   v
Hazard mapping: epsilon = epsilon_min + c_hazard / nu
   |
   v
COR operators: A -> Q -> K -> N
   |
   v
Fragility score, ruin proxy, stress alerts
```

---

## 21. Practical Interpretation Template

After running the classifier, report:

```r
summary(model)
round(coef(model), 6)
table(True = y_test, Predicted = pred_class)
round(head(pred_prob), 4)
model$params$nu
```

Then write the interpretation as:

```text
The Student-t Naive Bayes classifier identifies regime-specific distributional structure. The Stress regime exhibits higher volatility, deeper drawdowns, elevated ruin proxy values, and lower degrees of freedom, indicating heavier tails. In the COR framework, lower nu maps into higher hazard through epsilon_i = epsilon_min + c_hazard / nu_i. The resulting killed operator K = Q - I and fundamental matrix N = -K^{-1} translate supervised regime classification into survival geometry and spectral fragility.
```

---

## 22. Summary

The `kronxNBC` package is used as follows:

1. Construct a numeric feature matrix `X`.
2. Construct regime labels `y`.
3. Fit:

```r
model <- student_t_naive_bayes(X, y)
```

4. Predict:

```r
predict(model, X, type = "class")
predict(model, X, type = "prob")
```

5. Extract parameters:

```r
coef(model)
tables(model)
model$params$nu
```

6. Map the fitted Student-t tail structure into the COR framework:

```r
epsilon <- eps_min + c_hazard / rowMeans(model$params$nu)
Q <- diag(1 - epsilon) %*% A
K <- Q - diag(nrow(Q))
N <- solve(-K)
```

This gives a complete bridge from **supervised heavy-tailed classification** to **Clock of Regimes survival geometry**.
