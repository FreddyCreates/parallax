from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Optional

import torch
from torch import Tensor, nn
import torch.nn.functional as F


@dataclass(frozen=True)
class SequenceForecast:
    """Structured forecast output for sequence models."""

    prediction: Tensor
    latent_state: Optional[Tensor] = None
    attention_weights: Optional[Tensor] = None


class PositionalEncoding(nn.Module):
    """Sinusoidal positional encoding for transformer-based models."""

    def __init__(self, d_model: int, dropout: float = 0.1, max_len: int = 4096) -> None:
        super().__init__()
        position = torch.arange(max_len, dtype=torch.float32).unsqueeze(1)
        div_term = torch.exp(
            torch.arange(0, d_model, 2, dtype=torch.float32) * (-math.log(10000.0) / d_model)
        )
        pe = torch.zeros(max_len, d_model, dtype=torch.float32)
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        self.register_buffer("pe", pe.unsqueeze(0), persistent=False)
        self.dropout = nn.Dropout(dropout)

    def forward(self, x: Tensor) -> Tensor:
        return self.dropout(x + self.pe[:, : x.size(1)])


class AttentionPooling(nn.Module):
    """Single-query attention pooling over temporal features."""

    def __init__(self, hidden_dim: int, dropout: float = 0.1) -> None:
        super().__init__()
        self.score = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.Tanh(),
            nn.Dropout(dropout),
            nn.Linear(hidden_dim, 1),
        )

    def forward(self, x: Tensor, mask: Optional[Tensor] = None) -> tuple[Tensor, Tensor]:
        scores = self.score(x).squeeze(-1)
        if mask is not None:
            scores = scores.masked_fill(~mask.bool(), float("-inf"))
        weights = torch.softmax(scores, dim=-1)
        pooled = torch.sum(x * weights.unsqueeze(-1), dim=1)
        return pooled, weights


class MultiAssetAttention(nn.Module):
    """Multi-head self-attention for cross-asset interactions."""

    def __init__(self, embed_dim: int, num_heads: int, dropout: float = 0.1) -> None:
        super().__init__()
        self.attention = nn.MultiheadAttention(
            embed_dim=embed_dim,
            num_heads=num_heads,
            dropout=dropout,
            batch_first=True,
        )
        self.norm = nn.LayerNorm(embed_dim)
        self.ffn = nn.Sequential(
            nn.Linear(embed_dim, embed_dim * 4),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(embed_dim * 4, embed_dim),
        )
        self.ffn_norm = nn.LayerNorm(embed_dim)
        self.dropout = nn.Dropout(dropout)

    def forward(self, assets: Tensor, key_padding_mask: Optional[Tensor] = None) -> tuple[Tensor, Tensor]:
        attended, weights = self.attention(
            assets,
            assets,
            assets,
            key_padding_mask=key_padding_mask,
            need_weights=True,
        )
        assets = self.norm(assets + self.dropout(attended))
        fused = self.ffn_norm(assets + self.dropout(self.ffn(assets)))
        return fused, weights


class ForecastHead(nn.Module):
    def __init__(self, hidden_dim: int, horizon: int, output_dim: int, dropout: float = 0.1) -> None:
        super().__init__()
        self.horizon = horizon
        self.output_dim = output_dim
        self.projection = nn.Sequential(
            nn.LayerNorm(hidden_dim),
            nn.Dropout(dropout),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
            nn.Linear(hidden_dim, horizon * output_dim),
        )

    def forward(self, context: Tensor) -> Tensor:
        forecast = self.projection(context)
        return forecast.view(context.size(0), self.horizon, self.output_dim)


class LSTMForecaster(nn.Module):
    """LSTM forecaster for market time-series prediction."""

    def __init__(
        self,
        input_dim: int,
        hidden_dim: int,
        num_layers: int = 2,
        horizon: int = 1,
        output_dim: int = 1,
        dropout: float = 0.1,
        bidirectional: bool = False,
        use_attention: bool = True,
    ) -> None:
        super().__init__()
        recurrent_dropout = dropout if num_layers > 1 else 0.0
        self.encoder = nn.LSTM(
            input_size=input_dim,
            hidden_size=hidden_dim,
            num_layers=num_layers,
            dropout=recurrent_dropout,
            batch_first=True,
            bidirectional=bidirectional,
        )
        model_dim = hidden_dim * (2 if bidirectional else 1)
        self.pool = AttentionPooling(model_dim, dropout) if use_attention else None
        self.head = ForecastHead(model_dim, horizon, output_dim, dropout)

    def forward(self, x: Tensor, mask: Optional[Tensor] = None) -> SequenceForecast:
        sequence, (hidden, _) = self.encoder(x)
        if self.pool is None:
            context = sequence[:, -1]
            weights = None
        else:
            context, weights = self.pool(sequence, mask)
        latent_state = hidden.transpose(0, 1).reshape(x.size(0), -1)
        return SequenceForecast(self.head(context), latent_state=latent_state, attention_weights=weights)


class GRUForecaster(nn.Module):
    """GRU forecaster optimized for lighter-weight trading deployments."""

    def __init__(
        self,
        input_dim: int,
        hidden_dim: int,
        num_layers: int = 2,
        horizon: int = 1,
        output_dim: int = 1,
        dropout: float = 0.1,
        bidirectional: bool = False,
        use_attention: bool = True,
    ) -> None:
        super().__init__()
        recurrent_dropout = dropout if num_layers > 1 else 0.0
        self.encoder = nn.GRU(
            input_size=input_dim,
            hidden_size=hidden_dim,
            num_layers=num_layers,
            dropout=recurrent_dropout,
            batch_first=True,
            bidirectional=bidirectional,
        )
        model_dim = hidden_dim * (2 if bidirectional else 1)
        self.pool = AttentionPooling(model_dim, dropout) if use_attention else None
        self.head = ForecastHead(model_dim, horizon, output_dim, dropout)

    def forward(self, x: Tensor, mask: Optional[Tensor] = None) -> SequenceForecast:
        sequence, hidden = self.encoder(x)
        if self.pool is None:
            context = sequence[:, -1]
            weights = None
        else:
            context, weights = self.pool(sequence, mask)
        latent_state = hidden.transpose(0, 1).reshape(x.size(0), -1)
        return SequenceForecast(self.head(context), latent_state=latent_state, attention_weights=weights)


class TransformerForecaster(nn.Module):
    """Transformer encoder for multi-step sequence prediction."""

    def __init__(
        self,
        input_dim: int,
        model_dim: int,
        num_heads: int,
        num_layers: int = 4,
        horizon: int = 1,
        output_dim: int = 1,
        dropout: float = 0.1,
        max_len: int = 4096,
        use_cls_token: bool = True,
    ) -> None:
        super().__init__()
        self.use_cls_token = use_cls_token
        self.input_projection = nn.Linear(input_dim, model_dim)
        self.position = PositionalEncoding(model_dim, dropout=dropout, max_len=max_len + int(use_cls_token))
        encoder_layer = nn.TransformerEncoderLayer(
            d_model=model_dim,
            nhead=num_heads,
            dim_feedforward=model_dim * 4,
            dropout=dropout,
            activation="gelu",
            batch_first=True,
            norm_first=True,
        )
        self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.cls_token = nn.Parameter(torch.zeros(1, 1, model_dim)) if use_cls_token else None
        self.pool = AttentionPooling(model_dim, dropout)
        self.head = ForecastHead(model_dim, horizon, output_dim, dropout)

    def forward(self, x: Tensor, mask: Optional[Tensor] = None) -> SequenceForecast:
        embedded = self.input_projection(x)
        padding_mask = None
        if self.use_cls_token:
            cls = self.cls_token.expand(x.size(0), -1, -1)
            embedded = torch.cat([cls, embedded], dim=1)
            if mask is not None:
                cls_mask = torch.ones(mask.size(0), 1, device=mask.device, dtype=mask.dtype)
                mask = torch.cat([cls_mask, mask], dim=1)
        if mask is not None:
            padding_mask = ~mask.bool()
        encoded = self.encoder(self.position(embedded), src_key_padding_mask=padding_mask)
        if self.use_cls_token:
            context = encoded[:, 0]
            weights = None
        else:
            context, weights = self.pool(encoded, mask)
        return SequenceForecast(self.head(context), latent_state=encoded, attention_weights=weights)


class CausalConv1d(nn.Module):
    def __init__(self, in_channels: int, out_channels: int, kernel_size: int, dilation: int = 1) -> None:
        super().__init__()
        self.left_padding = (kernel_size - 1) * dilation
        self.conv = nn.Conv1d(in_channels, out_channels, kernel_size, dilation=dilation)

    def forward(self, x: Tensor) -> Tensor:
        return self.conv(F.pad(x, (self.left_padding, 0)))


class TemporalBlock(nn.Module):
    def __init__(
        self,
        in_channels: int,
        out_channels: int,
        kernel_size: int,
        dilation: int,
        dropout: float,
    ) -> None:
        super().__init__()
        self.net = nn.Sequential(
            CausalConv1d(in_channels, out_channels, kernel_size, dilation=dilation),
            nn.GELU(),
            nn.Dropout(dropout),
            CausalConv1d(out_channels, out_channels, kernel_size, dilation=dilation),
            nn.GELU(),
            nn.Dropout(dropout),
        )
        self.downsample = nn.Conv1d(in_channels, out_channels, kernel_size=1) if in_channels != out_channels else nn.Identity()
        self.norm = nn.BatchNorm1d(out_channels)

    def forward(self, x: Tensor) -> Tensor:
        residual = self.downsample(x)
        out = self.net(x)
        return self.norm(out + residual)


class TCNForecaster(nn.Module):
    """Temporal Convolutional Network for high-frequency sequence modeling."""

    def __init__(
        self,
        input_dim: int,
        channels: list[int],
        kernel_size: int = 3,
        horizon: int = 1,
        output_dim: int = 1,
        dropout: float = 0.1,
    ) -> None:
        super().__init__()
        blocks = []
        in_channels = input_dim
        for depth, out_channels in enumerate(channels):
            blocks.append(
                TemporalBlock(
                    in_channels=in_channels,
                    out_channels=out_channels,
                    kernel_size=kernel_size,
                    dilation=2**depth,
                    dropout=dropout,
                )
            )
            in_channels = out_channels
        self.network = nn.Sequential(*blocks)
        self.head = ForecastHead(in_channels, horizon, output_dim, dropout)

    def forward(self, x: Tensor) -> SequenceForecast:
        features = self.network(x.transpose(1, 2)).transpose(1, 2)
        context = features[:, -1]
        return SequenceForecast(self.head(context), latent_state=features)


class WaveNetResidualBlock(nn.Module):
    def __init__(
        self,
        residual_channels: int,
        skip_channels: int,
        kernel_size: int,
        dilation: int,
        dropout: float,
    ) -> None:
        super().__init__()
        self.filter_conv = CausalConv1d(residual_channels, residual_channels, kernel_size, dilation)
        self.gate_conv = CausalConv1d(residual_channels, residual_channels, kernel_size, dilation)
        self.residual_projection = nn.Conv1d(residual_channels, residual_channels, kernel_size=1)
        self.skip_projection = nn.Conv1d(residual_channels, skip_channels, kernel_size=1)
        self.dropout = nn.Dropout(dropout)

    def forward(self, x: Tensor) -> tuple[Tensor, Tensor]:
        gated = torch.tanh(self.filter_conv(x)) * torch.sigmoid(self.gate_conv(x))
        gated = self.dropout(gated)
        residual = self.residual_projection(gated) + x
        skip = self.skip_projection(gated)
        return residual, skip


class WaveNetForecaster(nn.Module):
    """Dilated causal WaveNet model for price-path prediction."""

    def __init__(
        self,
        input_dim: int,
        residual_channels: int = 64,
        skip_channels: int = 128,
        dilation_depth: int = 6,
        num_stacks: int = 2,
        kernel_size: int = 2,
        horizon: int = 1,
        output_dim: int = 1,
        dropout: float = 0.1,
    ) -> None:
        super().__init__()
        self.input_projection = nn.Conv1d(input_dim, residual_channels, kernel_size=1)
        self.blocks = nn.ModuleList(
            [
                WaveNetResidualBlock(
                    residual_channels=residual_channels,
                    skip_channels=skip_channels,
                    kernel_size=kernel_size,
                    dilation=2 ** (layer % dilation_depth),
                    dropout=dropout,
                )
                for layer in range(dilation_depth * num_stacks)
            ]
        )
        self.post = nn.Sequential(
            nn.ReLU(),
            nn.Conv1d(skip_channels, skip_channels, kernel_size=1),
            nn.ReLU(),
        )
        self.head = ForecastHead(skip_channels, horizon, output_dim, dropout)

    def forward(self, x: Tensor) -> SequenceForecast:
        hidden = self.input_projection(x.transpose(1, 2))
        skip_connections = []
        for block in self.blocks:
            hidden, skip = block(hidden)
            skip_connections.append(skip)
        aggregated = torch.stack(skip_connections, dim=0).sum(dim=0)
        features = self.post(aggregated).transpose(1, 2)
        context = features[:, -1]
        return SequenceForecast(self.head(context), latent_state=features)


__all__ = [
    "AttentionPooling",
    "CausalConv1d",
    "GRUForecaster",
    "LSTMForecaster",
    "MultiAssetAttention",
    "PositionalEncoding",
    "SequenceForecast",
    "TCNForecaster",
    "TemporalBlock",
    "TransformerForecaster",
    "WaveNetForecaster",
    "WaveNetResidualBlock",
]
