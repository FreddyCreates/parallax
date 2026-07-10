"""Game-theoretic tooling for market design and strategic analysis."""

from __future__ import annotations

from dataclasses import dataclass

import nashpy as nash
import numpy as np
from numpy.typing import ArrayLike


@dataclass(slots=True)
class NashEquilibriumResult:
    """Representation of a mixed-strategy Nash equilibrium."""

    strategy_row: np.ndarray
    strategy_column: np.ndarray
    payoff_row: float
    payoff_column: float


@dataclass(slots=True)
class AuctionOutcome:
    """Outcome of an auction mechanism."""

    winner: int | None
    winning_bid: float
    payment: float
    utilities: np.ndarray


def solve_nash_equilibria(payoff_row: ArrayLike, payoff_column: ArrayLike) -> list[NashEquilibriumResult]:
    """Solve for Nash equilibria using :mod:`nashpy` support enumeration."""
    row = np.asarray(payoff_row, dtype=float)
    column = np.asarray(payoff_column, dtype=float)
    game = nash.Game(row, column)
    equilibria = []
    for sigma_r, sigma_c in game.support_enumeration():
        payoff_r, payoff_c = game[sigma_r, sigma_c]
        equilibria.append(
            NashEquilibriumResult(
                strategy_row=np.asarray(sigma_r, dtype=float),
                strategy_column=np.asarray(sigma_c, dtype=float),
                payoff_row=float(payoff_r),
                payoff_column=float(payoff_c),
            )
        )
    return equilibria


def first_price_sealed_bid_auction(
    valuations: ArrayLike,
    bids: ArrayLike | None = None,
    reserve_price: float = 0.0,
) -> AuctionOutcome:
    """Run a first-price sealed-bid auction."""
    values = np.asarray(valuations, dtype=float)
    submitted = values.copy() if bids is None else np.asarray(bids, dtype=float)
    winner = int(np.argmax(submitted))
    winning_bid = float(submitted[winner])
    if winning_bid < reserve_price:
        return AuctionOutcome(winner=None, winning_bid=winning_bid, payment=0.0, utilities=np.zeros_like(values))
    utilities = np.zeros_like(values)
    utilities[winner] = values[winner] - winning_bid
    return AuctionOutcome(winner=winner, winning_bid=winning_bid, payment=winning_bid, utilities=utilities)


def second_price_sealed_bid_auction(
    valuations: ArrayLike,
    bids: ArrayLike | None = None,
    reserve_price: float = 0.0,
) -> AuctionOutcome:
    """Run a Vickrey second-price sealed-bid auction."""
    values = np.asarray(valuations, dtype=float)
    submitted = values.copy() if bids is None else np.asarray(bids, dtype=float)
    order = np.argsort(submitted)
    winner = int(order[-1])
    winning_bid = float(submitted[winner])
    second_bid = float(submitted[order[-2]]) if len(submitted) > 1 else reserve_price
    payment = max(second_bid, reserve_price)
    if winning_bid < reserve_price:
        return AuctionOutcome(winner=None, winning_bid=winning_bid, payment=0.0, utilities=np.zeros_like(values))
    utilities = np.zeros_like(values)
    utilities[winner] = values[winner] - payment
    return AuctionOutcome(winner=winner, winning_bid=winning_bid, payment=payment, utilities=utilities)


def english_auction(
    valuations: ArrayLike,
    increment: float = 1.0,
    reserve_price: float = 0.0,
) -> AuctionOutcome:
    """Simulate an ascending English auction."""
    values = np.asarray(valuations, dtype=float)
    order = np.argsort(values)
    winner = int(order[-1])
    highest = float(values[winner])
    if highest < reserve_price:
        return AuctionOutcome(winner=None, winning_bid=highest, payment=0.0, utilities=np.zeros_like(values))
    second_highest = float(values[order[-2]]) if len(values) > 1 else reserve_price
    payment = min(highest, max(reserve_price, second_highest + increment))
    utilities = np.zeros_like(values)
    utilities[winner] = highest - payment
    return AuctionOutcome(winner=winner, winning_bid=highest, payment=payment, utilities=utilities)


class StrategicGameAnalyzer:
    """Strategic analysis helpers for normal-form games."""

    def __init__(self, payoff_row: ArrayLike, payoff_column: ArrayLike) -> None:
        self.payoff_row = np.asarray(payoff_row, dtype=float)
        self.payoff_column = np.asarray(payoff_column, dtype=float)

    def best_response_correspondence(self) -> dict[str, dict[int, list[int]]]:
        """Compute best responses for each player against pure strategies."""
        row_best = {}
        for column_action in range(self.payoff_row.shape[1]):
            payoffs = self.payoff_row[:, column_action]
            row_best[column_action] = np.where(payoffs == payoffs.max())[0].tolist()
        column_best = {}
        for row_action in range(self.payoff_column.shape[0]):
            payoffs = self.payoff_column[row_action, :]
            column_best[row_action] = np.where(payoffs == payoffs.max())[0].tolist()
        return {"row": row_best, "column": column_best}

    def eliminate_dominated_strategies(self, strict: bool = False) -> dict[str, object]:
        """Iteratively remove dominated pure strategies."""
        remaining_rows = list(range(self.payoff_row.shape[0]))
        remaining_cols = list(range(self.payoff_row.shape[1]))
        row_payoff = self.payoff_row.copy()
        col_payoff = self.payoff_column.copy()
        changed = True
        while changed:
            changed = False
            for i in range(len(remaining_rows)):
                for j in range(len(remaining_rows)):
                    if i == j:
                        continue
                    left = row_payoff[i]
                    right = row_payoff[j]
                    dominated = np.all(left < right) if strict else (np.all(left <= right) and np.any(left < right))
                    if dominated:
                        row_payoff = np.delete(row_payoff, i, axis=0)
                        col_payoff = np.delete(col_payoff, i, axis=0)
                        del remaining_rows[i]
                        changed = True
                        break
                if changed:
                    break
            if changed:
                continue
            for i in range(len(remaining_cols)):
                for j in range(len(remaining_cols)):
                    if i == j:
                        continue
                    left = col_payoff[:, i]
                    right = col_payoff[:, j]
                    dominated = np.all(left < right) if strict else (np.all(left <= right) and np.any(left < right))
                    if dominated:
                        row_payoff = np.delete(row_payoff, i, axis=1)
                        col_payoff = np.delete(col_payoff, i, axis=1)
                        del remaining_cols[i]
                        changed = True
                        break
                if changed:
                    break
        return {
            "remaining_rows": remaining_rows,
            "remaining_columns": remaining_cols,
            "reduced_row_payoffs": row_payoff,
            "reduced_column_payoffs": col_payoff,
        }

    def nash_equilibria(self) -> list[NashEquilibriumResult]:
        """Convenience wrapper returning all mixed equilibria."""
        return solve_nash_equilibria(self.payoff_row, self.payoff_column)
