# Integral policy iteration: the baseline

This note follows the original two-state example in [demo_integral_pi.m](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/demo_integral_pi.m): collect trajectories with a fixed feedback gain, fit its quadratic value function, then improve the gain. It uses base MATLAB and the standard JVM for saving source hashes.

## 1. Problem and initial policy

The [double integrator](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/src/%2Badp/%2Bmodels/doubleIntegrator.m) is

$$
\dot x=Ax+Bu,\qquad
A=\begin{bmatrix}0&1\\0&0\end{bmatrix},\quad
B=\begin{bmatrix}0\\1\end{bmatrix},\quad
Q=I_2,\quad R=1.
$$

For continuous feedback $u=-Kx$, the objective is

$$
V_K(x_0)=\int_0^\infty \left(x(t)^\top Qx(t)+u(t)^\top Ru(t)\right)\,dt.
$$

The cost is undiscounted and has no factor of $1/2$. A single state is a two-element column; stored trajectories have one state per row. There is no exploration or input modification in this example, so the recorded nominal, behavior, filtered and applied inputs all equal $-Kx$.

The initial gain is $K_0=[1,2]$. The matrix $A-BK_0$ has both eigenvalues at $-1$, so this policy is admissible for the stated infinite-horizon cost. The experiment checks this using $A$ before calling the learner.

## 2. Evaluate one frozen policy

For a stabilizing gain $K_i$, write its exact value as $V_i(x)=x^\top P_i x$. With $A_i=A-BK_i$, the policy-evaluation equation is

$$
A_i^\top P_i+P_iA_i+Q+K_i^\top RK_i=0.
$$

Along a trajectory of this fixed policy,

$$
\frac{d}{dt}V_i(x(t))=-x(t)^\top Qx(t)-u(t)^\top Ru(t).
$$

Integrating over a collection window $[a,b]$ gives the identity used for learning:

$$
V_i(x(a))-V_i(x(b))=
\int_a^b \left(x(t)^\top Qx(t)+u(t)^\top Ru(t)\right)\,dt.
$$

[collectBatch](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/src/%2Badp/%2Bsim/collectBatch.m) collects six independent, resettable segments per policy. Each lasts 0.25 seconds and starts from one column of

```matlab
initialStates = [1,0,1,-1,0.5,-1; 0,1,1,1,-1,0.5];
```

The gain stays fixed throughout the entire batch; improvement happens after collection and fitting. The integral is an augmented state in `ode45`. The 26 requested output times per segment are a recording grid; feedback remains continuous. The solver uses relative tolerance `1e-10`, absolute tolerance `1e-12` and maximum step `0.01`. These settings are recorded, but no proved integration-error bound is supplied.

## 3. Turn the identity into a value fit

The [quadratic basis](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/src/%2Badp/%2Bbasis/quadratic2.m) and coefficient convention are

$$
\phi(x)=\begin{bmatrix}x_1^2\\2x_1x_2\\x_2^2\end{bmatrix},\qquad
w_i=\begin{bmatrix}P_{i,11}\\P_{i,12}\\P_{i,22}\end{bmatrix},\qquad
V_i(x)=w_i^\top\phi(x).
$$

The factor of two belongs in the basis: the middle coefficient is $P_{i,12}$, not $2P_{i,12}$.

For segment $j$, the collector stores

$$
\Phi_{j,:}=\left[\phi(x(a_j))-\phi(x(b_j))\right]^\top,\qquad
y_j=\int_{a_j}^{b_j}(x^\top Qx+u^\top Ru)\,dt.
$$

Thus each round fits the six-by-three system $\Phi w_i=y$. [fitValue](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/src/%2Badp/%2Blearn/fitValue.m) uses an economy SVD $\Phi=U\Sigma W^\top$ to obtain the least-squares estimate

$$
\widehat w_i=W\Sigma^{-1}U^\top y,\qquad
\widehat P_i=\begin{bmatrix}\widehat w_{i,1}&\widehat w_{i,2}\\\widehat w_{i,2}&\widehat w_{i,3}\end{bmatrix}.
$$

The fit requires rank three at relative singular-value tolerance `1e-12` and condition number at most `1e8`; six rows alone do not establish rank. The learner also requires a positive-definite fitted matrix. The stored fit residual is `Phi*weights-y`, with the opposite sign to the integrated Bellman expression `V(end)-V(start)+cost`; their norms agree.

## 4. Improve the gain, then collect again

Since $\nabla V_i(x)=2P_i x$, minimizing the Hamiltonian over $u$ gives

$$
2Ru+B^\top\nabla V_i(x)=0,\qquad
u_{i+1}(x)=-R^{-1}B^\top P_i x.
$$

[integralPI](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/src/%2Badp/%2Blearn/integralPI.m) applies this map to the fitted matrix:

```matlab
improvedK = R\(B'*value.P);
policyChange = norm(improvedK-K,'fro');
```

It stops when `policyChange <= 1e-9`, with at most 20 evaluation rounds. Otherwise, it uses the improved gain to collect the next batch. The demo raises an error if convergence is not reached within this budget.

`result.learning.K` is the gain that generated the final fitted batch, and `result.learning.P` estimates that same policy's value. `result.learning.nextPolicyK` is its greedy improvement. The implementation keeps this K/P pairing even at the iteration limit; the final fitted P must not be relabeled as an evaluation of `nextPolicyK`. On a converged return the two gains differ by at most the stopping tolerance.

## 5. Keep simulation and learning information separate

| Role | Information used |
|---|---|
| Simulator and collector | Plant dynamics, cost, initial states and the gain being evaluated; returns trajectories, regression data and cost/input declarations |
| Learner | `collector(K)`, known B and R, initial K and fitting settings; checks the batch's declared Q/R and executed-input consistency; receives neither A nor the analytic optimum |
| Independent experiment checks | A for initial/final closed-loop poles, and the analytic LQR solution below for gain/value errors |

For this particular problem, the independent reference is

$$
P^\star=\begin{bmatrix}\sqrt{3}&1\\1&\sqrt{3}\end{bmatrix},\qquad
K^\star=\begin{bmatrix}1&\sqrt{3}\end{bmatrix}.
$$

These matrices are defined in the demo after the learner returns. The learner uses known B in the greedy step; the example is not an unknown-B method. The complete function and data contracts are in the [implemented API](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/IMPLEMENTED_API.md#preserved-ct-integral-pi-baseline). For adding a different method, use the separate [method-extension contracts](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/METHOD_CONTRACTS.zh-CN.md).

## 6. Run and inspect the result

From the repository root in MATLAB:

```matlab
[result, runDir] = demo_reproductions('baseline');
result.learning.K
result.learning.P
result.metrics
```

See [Getting started](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/GETTING_STARTED.md) for setup. The default run creates a new folder under `runs/`; the saved files come from this execution.

| Inspect | Contents |
|---|---|
| `result.config` | Plant, seed, initial gain, collection windows, fitting settings and evaluation settings |
| `result.learning.history{j}` | Evaluated gain, fitted value, improved gain, fit diagnostics and raw batch for round j |
| `result.evaluation` | Learned-policy rollout, including row-wise states, input channels and integrated cost |
| `result.metrics` | Reference errors, regression residual/conditioning, poles and cost/value checks |
| `fullfile(runDir,'result.mat')` | The complete result struct, including collection and evaluation trajectories |
| JSON files in `runDir` | `config.json`, `environment.json`, `source_version.json`, `summary.json`, `diagnostics.json`; `manifest.json` records artifact and MATLAB source hashes |

The evaluation uses $x_0=[1,-1]^\top$ and $T=8$ seconds. Its accumulated cost is finite-horizon. For the exact value of a fixed stabilizing policy,

$$
V_K(x_0)=J_K(0,T)+V_K(x(T)).
$$

The demo checks the numerical counterpart with its fitted P: `learnedFinitePlusTail` adds `learnedFiniteHorizonCost` and `learnedTailValue`, and `valueIdentityError` compares the sum with `learnedValueAtInitialState`.

The saved [September 8 quickstart record](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/docs/validation/quickstart-baseline.json) reports five rounds, gain error about $8.37\times10^{-14}$, eight-second cost $1.46410079898$ and tail value $8.16\times10^{-7}$. Their sum agrees numerically with the analytic initial value $2\sqrt{3}-2\approx1.46410161514$. These are recorded results, not prescribed values for every future environment.

The project figure retains the earlier September 7 run: [summary](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/docs/assets/data/baseline-summary.json), [trajectory CSV](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/docs/assets/data/baseline-trajectory.csv) and [convergence CSV](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/docs/assets/data/baseline-convergence.csv). Those CSVs are figure data already included in the repository; the baseline run itself saves MAT/JSON files. [Validation](https://github.com/tanjunkai2001/adp-matlab/blob/main/VALIDATION.md) links the test records and source hashes, while [Artifacts](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/ARTIFACTS.md) describes figure bundles and separately preserved historical runs.
