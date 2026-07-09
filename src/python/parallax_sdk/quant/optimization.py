"""Optimization algorithms for portfolio construction and research.

The module combines deterministic optimization based on SciPy with
population-based algorithms that remain useful for discontinuous,
non-convex, or simulation-driven objective functions.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Sequence

import numpy as np
import pandas as pd
from numpy.typing import ArrayLike
from scipy.optimize import Bounds, LinearConstraint, OptimizeResult, dual_annealing, minimize

Objective = Callable[[np.ndarray], float]


@dataclass(slots=True)
class PortfolioOptimizationResult:
    """Summary of a portfolio optimization run."""

    weights: pd.Series
    expected_return: float
    volatility: float
    sharpe_ratio: float
    success: bool
    message: str


@dataclass(slots=True)
class ConvexOptimizationResult:
    """Standardized output for convex optimization problems."""

    solution: np.ndarray
    objective_value: float
    success: bool
    message: str
    result: OptimizeResult


@dataclass(slots=True)
class GeneticAlgorithmResult:
    """Result from the genetic-algorithm solver."""

    best_position: np.ndarray
    best_score: float
    history: list[float]


@dataclass(slots=True)
class SimulatedAnnealingResult:
    """Wrapper around SciPy's simulated annealing output."""

    best_position: np.ndarray
    best_score: float
    success: bool
    message: str
    result: OptimizeResult


@dataclass(slots=True)
class ParticleSwarmResult:
    """Output from particle-swarm optimization."""

    best_position: np.ndarray
    best_score: float
    history: list[float]


class PortfolioOptimizer:
    """SciPy-based mean-variance and risk-budgeting optimization."""

    def __init__(
        self,
        expected_returns: pd.Series | Sequence[float],
        covariance: pd.DataFrame | ArrayLike,
        risk_free_rate: float = 0.0,
    ) -> None:
        self.expected_returns = pd.Series(expected_returns, dtype=float)
        self.asset_names = list(self.expected_returns.index)
        cov_df = pd.DataFrame(covariance, index=self.asset_names, columns=self.asset_names, dtype=float)
        self.covariance = cov_df
        self.risk_free_rate = float(risk_free_rate)

    @classmethod
    def from_price_history(
        cls,
        prices: pd.DataFrame,
        frequency: int = 252,
        risk_free_rate: float = 0.0,
    ) -> "PortfolioOptimizer":
        """Construct the optimizer from a price history matrix."""
        returns = prices.pct_change().dropna(how="all")
        expected_returns = returns.mean() * frequency
        covariance = returns.cov() * frequency
        return cls(expected_returns=expected_returns, covariance=covariance, risk_free_rate=risk_free_rate)

    def _portfolio_return(self, weights: np.ndarray) -> float:
        return float(weights @ self.expected_returns.to_numpy())

    def _portfolio_volatility(self, weights: np.ndarray) -> float:
        cov = self.covariance.to_numpy()
        return float(np.sqrt(np.clip(weights @ cov @ weights, 0.0, None)))

    def _finalize(self, weights: np.ndarray, result: OptimizeResult) -> PortfolioOptimizationResult:
        expected_return = self._portfolio_return(weights)
        volatility = self._portfolio_volatility(weights)
        excess = expected_return - self.risk_free_rate
        sharpe = excess / volatility if volatility > 0 else np.nan
        return PortfolioOptimizationResult(
            weights=pd.Series(weights, index=self.asset_names, name="weight"),
            expected_return=expected_return,
            volatility=volatility,
            sharpe_ratio=float(sharpe),
            success=bool(result.success),
            message=str(result.message),
        )

    def optimize_max_sharpe(
        self,
        bounds: Sequence[tuple[float, float]] | None = None,
        allow_short: bool = False,
    ) -> PortfolioOptimizationResult:
        """Maximize the ex-ante Sharpe ratio using SLSQP."""
        n_assets = len(self.expected_returns)
        if bounds is None:
            default = (-1.0, 1.0) if allow_short else (0.0, 1.0)
            bounds = [default] * n_assets
        x0 = np.full(n_assets, 1.0 / n_assets)

        def objective(weights: np.ndarray) -> float:
            vol = self._portfolio_volatility(weights)
            if vol <= 1e-12:
                return 1e6
            return -(self._portfolio_return(weights) - self.risk_free_rate) / vol

        constraints = [{"type": "eq", "fun": lambda w: np.sum(w) - 1.0}]
        result = minimize(objective, x0=x0, method="SLSQP", bounds=bounds, constraints=constraints)
        return self._finalize(result.x, result)

    def optimize_min_variance(
        self,
        target_return: float | None = None,
        bounds: Sequence[tuple[float, float]] | None = None,
    ) -> PortfolioOptimizationResult:
        """Minimize portfolio variance, optionally subject to a target return."""
        n_assets = len(self.expected_returns)
        bounds = bounds or [(0.0, 1.0)] * n_assets
        x0 = np.full(n_assets, 1.0 / n_assets)
        constraints: list[dict[str, object]] = [{"type": "eq", "fun": lambda w: np.sum(w) - 1.0}]
        if target_return is not None:
            constraints.append({"type": "eq", "fun": lambda w: self._portfolio_return(w) - target_return})
        result = minimize(
            lambda w: self._portfolio_volatility(w) ** 2,
            x0=x0,
            method="SLSQP",
            bounds=bounds,
            constraints=constraints,
        )
        return self._finalize(result.x, result)

    def optimize_risk_parity(
        self,
        bounds: Sequence[tuple[float, float]] | None = None,
    ) -> PortfolioOptimizationResult:
        """Compute a risk-parity allocation by equalizing risk contributions."""
        n_assets = len(self.expected_returns)
        bounds = bounds or [(0.0, 1.0)] * n_assets
        cov = self.covariance.to_numpy()
        x0 = np.full(n_assets, 1.0 / n_assets)

        def objective(weights: np.ndarray) -> float:
            portfolio_var = float(weights @ cov @ weights)
            if portfolio_var <= 1e-16:
                return 1e6
            marginal = cov @ weights
            contributions = weights * marginal / np.sqrt(portfolio_var)
            target = np.mean(contributions)
            return float(np.sum((contributions - target) ** 2))

        result = minimize(
            objective,
            x0=x0,
            method="SLSQP",
            bounds=bounds,
            constraints=[{"type": "eq", "fun": lambda w: np.sum(w) - 1.0}],
        )
        return self._finalize(result.x, result)


class ConvexOptimizer:
    """Thin wrapper around SciPy for convex optimization problems."""

    @staticmethod
    def solve(
        objective: Objective,
        x0: Sequence[float],
        gradient: Callable[[np.ndarray], np.ndarray] | None = None,
        hessian: Callable[[np.ndarray], np.ndarray] | None = None,
        bounds: Sequence[tuple[float, float]] | None = None,
        a_eq: ArrayLike | None = None,
        b_eq: ArrayLike | None = None,
        a_ub: ArrayLike | None = None,
        b_ub: ArrayLike | None = None,
    ) -> ConvexOptimizationResult:
        """Solve a differentiable convex optimization problem."""
        constraints: list[LinearConstraint] = []
        if a_eq is not None and b_eq is not None:
            a_eq_arr = np.atleast_2d(np.asarray(a_eq, dtype=float))
            b_eq_arr = np.asarray(b_eq, dtype=float)
            constraints.append(LinearConstraint(a_eq_arr, b_eq_arr, b_eq_arr))
        if a_ub is not None and b_ub is not None:
            a_ub_arr = np.atleast_2d(np.asarray(a_ub, dtype=float))
            b_ub_arr = np.asarray(b_ub, dtype=float)
            constraints.append(LinearConstraint(a_ub_arr, -np.inf, b_ub_arr))

        kwargs: dict[str, object] = {"method": "trust-constr", "constraints": constraints}
        if bounds is not None:
            lower, upper = zip(*bounds)
            kwargs["bounds"] = Bounds(lower, upper)
        if gradient is not None:
            kwargs["jac"] = gradient
        if hessian is not None:
            kwargs["hess"] = hessian
        result = minimize(objective, x0=np.asarray(x0, dtype=float), **kwargs)
        return ConvexOptimizationResult(
            solution=np.asarray(result.x, dtype=float),
            objective_value=float(result.fun),
            success=bool(result.success),
            message=str(result.message),
            result=result,
        )

    @staticmethod
    def quadratic_program(
        q_matrix: ArrayLike,
        c_vector: ArrayLike | None = None,
        bounds: Sequence[tuple[float, float]] | None = None,
        a_eq: ArrayLike | None = None,
        b_eq: ArrayLike | None = None,
        a_ub: ArrayLike | None = None,
        b_ub: ArrayLike | None = None,
        x0: Sequence[float] | None = None,
    ) -> ConvexOptimizationResult:
        """Solve a quadratic program of the form 0.5 x'Qx + c'x."""
        q = np.asarray(q_matrix, dtype=float)
        c = np.zeros(q.shape[0], dtype=float) if c_vector is None else np.asarray(c_vector, dtype=float)
        if x0 is None:
            x0 = np.zeros(q.shape[0], dtype=float)

        def objective(x: np.ndarray) -> float:
            return float(0.5 * x @ q @ x + c @ x)

        def gradient(x: np.ndarray) -> np.ndarray:
            return q @ x + c

        def hessian(_: np.ndarray) -> np.ndarray:
            return q

        return ConvexOptimizer.solve(
            objective=objective,
            x0=x0,
            gradient=gradient,
            hessian=hessian,
            bounds=bounds,
            a_eq=a_eq,
            b_eq=b_eq,
            a_ub=a_ub,
            b_ub=b_ub,
        )


class GeneticAlgorithmOptimizer:
    """Simple continuous genetic algorithm for non-convex problems."""

    def __init__(
        self,
        bounds: Sequence[tuple[float, float]],
        population_size: int = 100,
        generations: int = 200,
        mutation_rate: float = 0.1,
        crossover_rate: float = 0.7,
        elite_fraction: float = 0.1,
        random_state: int | np.random.Generator | None = None,
    ) -> None:
        self.bounds = np.asarray(bounds, dtype=float)
        self.population_size = int(population_size)
        self.generations = int(generations)
        self.mutation_rate = float(mutation_rate)
        self.crossover_rate = float(crossover_rate)
        self.elite_fraction = float(elite_fraction)
        self.rng = np.random.default_rng(random_state)

    def _initial_population(self) -> np.ndarray:
        lows = self.bounds[:, 0]
        highs = self.bounds[:, 1]
        return self.rng.uniform(lows, highs, size=(self.population_size, len(self.bounds)))

    def optimize(self, objective: Objective) -> GeneticAlgorithmResult:
        """Minimize a black-box objective function."""
        population = self._initial_population()
        n_elite = max(1, int(self.population_size * self.elite_fraction))
        history: list[float] = []

        def score(pop: np.ndarray) -> np.ndarray:
            return np.array([objective(individual) for individual in pop], dtype=float)

        for _ in range(self.generations):
            fitness = score(population)
            order = np.argsort(fitness)
            population = population[order]
            fitness = fitness[order]
            history.append(float(fitness[0]))
            elites = population[:n_elite].copy()
            next_generation = [*elites]

            while len(next_generation) < self.population_size:
                contenders = population[self.rng.integers(0, self.population_size, size=4)]
                contender_scores = np.array([objective(candidate) for candidate in contenders])
                parents = contenders[np.argsort(contender_scores)[:2]]
                child = parents[0].copy()
                if self.rng.random() < self.crossover_rate:
                    alpha = self.rng.random(len(self.bounds))
                    child = alpha * parents[0] + (1.0 - alpha) * parents[1]
                mutation_mask = self.rng.random(len(self.bounds)) < self.mutation_rate
                if mutation_mask.any():
                    span = self.bounds[:, 1] - self.bounds[:, 0]
                    child[mutation_mask] += self.rng.normal(scale=0.1 * span[mutation_mask])
                child = np.clip(child, self.bounds[:, 0], self.bounds[:, 1])
                next_generation.append(child)
            population = np.vstack(next_generation[: self.population_size])

        final_scores = score(population)
        best_index = int(np.argmin(final_scores))
        return GeneticAlgorithmResult(
            best_position=np.asarray(population[best_index], dtype=float),
            best_score=float(final_scores[best_index]),
            history=history,
        )


def simulated_annealing_optimize(
    objective: Objective,
    bounds: Sequence[tuple[float, float]],
    x0: Sequence[float] | None = None,
    maxiter: int = 500,
    random_state: int | None = None,
) -> SimulatedAnnealingResult:
    """Minimize an objective using SciPy's dual-annealing solver."""
    result = dual_annealing(
        objective,
        bounds=list(bounds),
        x0=None if x0 is None else np.asarray(x0, dtype=float),
        maxiter=maxiter,
        seed=random_state,
    )
    return SimulatedAnnealingResult(
        best_position=np.asarray(result.x, dtype=float),
        best_score=float(result.fun),
        success=bool(result.success),
        message=str(result.message),
        result=result,
    )


class ParticleSwarmOptimizer:
    """Continuous particle swarm optimizer for non-convex search spaces."""

    def __init__(
        self,
        bounds: Sequence[tuple[float, float]],
        swarm_size: int = 80,
        max_iter: int = 250,
        inertia: float = 0.7,
        cognitive: float = 1.4,
        social: float = 1.4,
        random_state: int | np.random.Generator | None = None,
    ) -> None:
        self.bounds = np.asarray(bounds, dtype=float)
        self.swarm_size = int(swarm_size)
        self.max_iter = int(max_iter)
        self.inertia = float(inertia)
        self.cognitive = float(cognitive)
        self.social = float(social)
        self.rng = np.random.default_rng(random_state)

    def optimize(self, objective: Objective) -> ParticleSwarmResult:
        """Minimize a continuous objective by particle swarm optimization."""
        dims = len(self.bounds)
        lows, highs = self.bounds[:, 0], self.bounds[:, 1]
        positions = self.rng.uniform(lows, highs, size=(self.swarm_size, dims))
        velocities = self.rng.normal(scale=(highs - lows) * 0.1, size=(self.swarm_size, dims))
        personal_best = positions.copy()
        personal_scores = np.array([objective(p) for p in positions], dtype=float)
        best_idx = int(np.argmin(personal_scores))
        global_best = personal_best[best_idx].copy()
        global_score = float(personal_scores[best_idx])
        history: list[float] = [global_score]

        for _ in range(self.max_iter):
            r1 = self.rng.random((self.swarm_size, dims))
            r2 = self.rng.random((self.swarm_size, dims))
            velocities = (
                self.inertia * velocities
                + self.cognitive * r1 * (personal_best - positions)
                + self.social * r2 * (global_best - positions)
            )
            positions = np.clip(positions + velocities, lows, highs)
            scores = np.array([objective(p) for p in positions], dtype=float)
            improved = scores < personal_scores
            personal_best[improved] = positions[improved]
            personal_scores[improved] = scores[improved]
            best_idx = int(np.argmin(personal_scores))
            if personal_scores[best_idx] < global_score:
                global_score = float(personal_scores[best_idx])
                global_best = personal_best[best_idx].copy()
            history.append(global_score)

        return ParticleSwarmResult(best_position=global_best, best_score=global_score, history=history)
