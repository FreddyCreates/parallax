from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Optional

import torch
from torch import Tensor, nn
import torch.nn.functional as F
from torch.distributions import Normal


@dataclass(frozen=True)
class VAEOutput:
    reconstruction: Tensor
    mean: Tensor
    log_var: Tensor

    def kl_divergence(self) -> Tensor:
        return -0.5 * torch.mean(1.0 + self.log_var - self.mean.pow(2) - self.log_var.exp())


class MarketRegimeVAE(nn.Module):
    """Variational autoencoder for latent market-regime discovery."""

    def __init__(self, input_dim: int, latent_dim: int, hidden_dims: tuple[int, ...] = (256, 128), dropout: float = 0.1) -> None:
        super().__init__()
        encoder_layers: list[nn.Module] = []
        in_features = input_dim
        for hidden_dim in hidden_dims:
            encoder_layers.extend([nn.Linear(in_features, hidden_dim), nn.GELU(), nn.Dropout(dropout)])
            in_features = hidden_dim
        self.encoder = nn.Sequential(*encoder_layers)
        self.mean_head = nn.Linear(in_features, latent_dim)
        self.log_var_head = nn.Linear(in_features, latent_dim)

        decoder_layers: list[nn.Module] = []
        in_features = latent_dim
        for hidden_dim in reversed(hidden_dims):
            decoder_layers.extend([nn.Linear(in_features, hidden_dim), nn.GELU(), nn.Dropout(dropout)])
            in_features = hidden_dim
        decoder_layers.append(nn.Linear(in_features, input_dim))
        self.decoder = nn.Sequential(*decoder_layers)

    def encode(self, x: Tensor) -> tuple[Tensor, Tensor]:
        hidden = self.encoder(x)
        return self.mean_head(hidden), self.log_var_head(hidden)

    def reparameterize(self, mean: Tensor, log_var: Tensor) -> Tensor:
        std = torch.exp(0.5 * log_var)
        eps = torch.randn_like(std)
        return mean + eps * std

    def decode(self, z: Tensor) -> Tensor:
        return self.decoder(z)

    def forward(self, x: Tensor) -> VAEOutput:
        mean, log_var = self.encode(x)
        z = self.reparameterize(mean, log_var)
        reconstruction = self.decode(z)
        return VAEOutput(reconstruction=reconstruction, mean=mean, log_var=log_var)

    def loss(self, x: Tensor, beta: float = 1.0) -> dict[str, Tensor]:
        output = self(x)
        reconstruction_loss = F.mse_loss(output.reconstruction, x)
        kl_loss = output.kl_divergence()
        total = reconstruction_loss + beta * kl_loss
        return {"loss": total, "reconstruction_loss": reconstruction_loss, "kl_loss": kl_loss}


class GANGenerator(nn.Module):
    def __init__(self, noise_dim: int, output_dim: int, hidden_dims: tuple[int, ...] = (256, 256), dropout: float = 0.1) -> None:
        super().__init__()
        layers: list[nn.Module] = []
        in_features = noise_dim
        for hidden_dim in hidden_dims:
            layers.extend([nn.Linear(in_features, hidden_dim), nn.GELU(), nn.Dropout(dropout)])
            in_features = hidden_dim
        layers.append(nn.Linear(in_features, output_dim))
        self.network = nn.Sequential(*layers)

    def forward(self, noise: Tensor) -> Tensor:
        return self.network(noise)


class GANDiscriminator(nn.Module):
    def __init__(self, input_dim: int, hidden_dims: tuple[int, ...] = (256, 256), dropout: float = 0.1) -> None:
        super().__init__()
        layers: list[nn.Module] = []
        in_features = input_dim
        for hidden_dim in hidden_dims:
            layers.extend([nn.Linear(in_features, hidden_dim), nn.LeakyReLU(0.2), nn.Dropout(dropout)])
            in_features = hidden_dim
        layers.append(nn.Linear(in_features, 1))
        self.network = nn.Sequential(*layers)

    def forward(self, x: Tensor) -> Tensor:
        return self.network(x).squeeze(-1)


class ScenarioGAN(nn.Module):
    """GAN for market scenario generation and stress testing."""

    def __init__(self, generator: GANGenerator, discriminator: GANDiscriminator, label_smoothing: float = 0.1) -> None:
        super().__init__()
        self.generator = generator
        self.discriminator = discriminator
        self.label_smoothing = label_smoothing

    def discriminator_loss(self, real_samples: Tensor, fake_samples: Tensor) -> Tensor:
        real_targets = torch.full((real_samples.size(0),), 1.0 - self.label_smoothing, device=real_samples.device)
        fake_targets = torch.zeros(fake_samples.size(0), device=fake_samples.device)
        real_loss = F.binary_cross_entropy_with_logits(self.discriminator(real_samples), real_targets)
        fake_loss = F.binary_cross_entropy_with_logits(self.discriminator(fake_samples.detach()), fake_targets)
        return real_loss + fake_loss

    def generator_loss(self, fake_samples: Tensor) -> Tensor:
        targets = torch.ones(fake_samples.size(0), device=fake_samples.device)
        return F.binary_cross_entropy_with_logits(self.discriminator(fake_samples), targets)

    @torch.no_grad()
    def sample(self, noise: Tensor) -> Tensor:
        return self.generator(noise)


class TimeEmbedding(nn.Module):
    def __init__(self, embedding_dim: int) -> None:
        super().__init__()
        self.embedding_dim = embedding_dim
        self.projection = nn.Sequential(
            nn.Linear(embedding_dim, embedding_dim * 4),
            nn.SiLU(),
            nn.Linear(embedding_dim * 4, embedding_dim),
        )

    def forward(self, timesteps: Tensor) -> Tensor:
        half_dim = self.embedding_dim // 2
        exponent = -math.log(10000.0) * torch.arange(half_dim, device=timesteps.device) / max(half_dim - 1, 1)
        freqs = torch.exp(exponent)
        args = timesteps.float().unsqueeze(-1) * freqs.unsqueeze(0)
        embedding = torch.cat([torch.sin(args), torch.cos(args)], dim=-1)
        if embedding.size(-1) < self.embedding_dim:
            embedding = F.pad(embedding, (0, self.embedding_dim - embedding.size(-1)))
        return self.projection(embedding)


class DiffusionDenoiser(nn.Module):
    """Sequence denoiser for score-based price path simulation."""

    def __init__(self, input_dim: int, model_dim: int = 128, num_layers: int = 4, num_heads: int = 4, dropout: float = 0.1) -> None:
        super().__init__()
        self.input_projection = nn.Linear(input_dim, model_dim)
        self.time_embedding = TimeEmbedding(model_dim)
        encoder_layer = nn.TransformerEncoderLayer(
            d_model=model_dim,
            nhead=num_heads,
            dim_feedforward=model_dim * 4,
            dropout=dropout,
            batch_first=True,
            norm_first=True,
            activation="gelu",
        )
        self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.output_projection = nn.Linear(model_dim, input_dim)

    def forward(self, x: Tensor, timesteps: Tensor) -> Tensor:
        encoded = self.input_projection(x)
        time_bias = self.time_embedding(timesteps).unsqueeze(1)
        encoded = self.encoder(encoded + time_bias)
        return self.output_projection(encoded)


class GaussianDiffusionScheduler(nn.Module):
    """Noise scheduler and sampler for price-path diffusion models."""

    def __init__(self, timesteps: int = 1000, beta_start: float = 1e-4, beta_end: float = 0.02) -> None:
        super().__init__()
        betas = torch.linspace(beta_start, beta_end, timesteps)
        alphas = 1.0 - betas
        alpha_bars = torch.cumprod(alphas, dim=0)
        self.register_buffer("betas", betas, persistent=False)
        self.register_buffer("alphas", alphas, persistent=False)
        self.register_buffer("alpha_bars", alpha_bars, persistent=False)
        self.timesteps = timesteps

    def q_sample(self, x_start: Tensor, t: Tensor, noise: Optional[Tensor] = None) -> Tensor:
        noise = torch.randn_like(x_start) if noise is None else noise
        alpha_bar = self.alpha_bars[t].view(-1, 1, 1)
        return alpha_bar.sqrt() * x_start + (1.0 - alpha_bar).sqrt() * noise

    def predict_start_from_noise(self, x_t: Tensor, t: Tensor, noise: Tensor) -> Tensor:
        alpha_bar = self.alpha_bars[t].view(-1, 1, 1)
        return (x_t - (1.0 - alpha_bar).sqrt() * noise) / alpha_bar.sqrt().clamp_min(1e-6)

    @torch.no_grad()
    def p_sample(self, model: DiffusionDenoiser, x_t: Tensor, t: Tensor) -> Tensor:
        noise_pred = model(x_t, t)
        alpha = self.alphas[t].view(-1, 1, 1)
        alpha_bar = self.alpha_bars[t].view(-1, 1, 1)
        beta = self.betas[t].view(-1, 1, 1)
        mean = (x_t - beta / (1.0 - alpha_bar).sqrt().clamp_min(1e-6) * noise_pred) / alpha.sqrt()
        if torch.all(t == 0):
            return mean
        noise = torch.randn_like(x_t)
        return mean + beta.sqrt() * noise

    @torch.no_grad()
    def sample(self, model: DiffusionDenoiser, shape: tuple[int, int, int], device: Optional[torch.device] = None) -> Tensor:
        sample = torch.randn(shape, device=device or next(model.parameters()).device)
        for timestep in reversed(range(self.timesteps)):
            t = torch.full((shape[0],), timestep, device=sample.device, dtype=torch.long)
            sample = self.p_sample(model, sample, t)
        return sample


class AffineCoupling(nn.Module):
    def __init__(self, feature_dim: int, hidden_dim: int = 256) -> None:
        super().__init__()
        split_dim = feature_dim // 2
        self.split_dim = split_dim
        self.scale_shift = nn.Sequential(
            nn.Linear(split_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, (feature_dim - split_dim) * 2),
        )

    def forward(self, x: Tensor) -> tuple[Tensor, Tensor]:
        x_a, x_b = x[:, : self.split_dim], x[:, self.split_dim :]
        log_scale, shift = self.scale_shift(x_a).chunk(2, dim=-1)
        log_scale = torch.tanh(log_scale)
        z_b = x_b * torch.exp(log_scale) + shift
        z = torch.cat([x_a, z_b], dim=-1)
        log_det = log_scale.sum(dim=-1)
        return z, log_det

    def inverse(self, z: Tensor) -> tuple[Tensor, Tensor]:
        z_a, z_b = z[:, : self.split_dim], z[:, self.split_dim :]
        log_scale, shift = self.scale_shift(z_a).chunk(2, dim=-1)
        log_scale = torch.tanh(log_scale)
        x_b = (z_b - shift) * torch.exp(-log_scale)
        x = torch.cat([z_a, x_b], dim=-1)
        log_det = -log_scale.sum(dim=-1)
        return x, log_det


class NormalizingFlowModel(nn.Module):
    """Normalizing flow for flexible market distribution modeling."""

    def __init__(self, feature_dim: int, num_layers: int = 6, hidden_dim: int = 256) -> None:
        super().__init__()
        self.layers = nn.ModuleList([AffineCoupling(feature_dim, hidden_dim) for _ in range(num_layers)])
        self.register_buffer("base_mean", torch.zeros(feature_dim), persistent=False)
        self.register_buffer("base_std", torch.ones(feature_dim), persistent=False)

    @property
    def base_distribution(self) -> Normal:
        return Normal(self.base_mean, self.base_std)

    def forward(self, x: Tensor) -> tuple[Tensor, Tensor]:
        log_det_total = torch.zeros(x.size(0), device=x.device, dtype=x.dtype)
        z = x
        for index, layer in enumerate(self.layers):
            if index % 2 == 1:
                z = torch.flip(z, dims=[-1])
            z, log_det = layer(z)
            log_det_total = log_det_total + log_det
        return z, log_det_total

    def inverse(self, z: Tensor) -> tuple[Tensor, Tensor]:
        log_det_total = torch.zeros(z.size(0), device=z.device, dtype=z.dtype)
        x = z
        for index, layer in reversed(list(enumerate(self.layers))):
            x, log_det = layer.inverse(x)
            if index % 2 == 1:
                x = torch.flip(x, dims=[-1])
            log_det_total = log_det_total + log_det
        return x, log_det_total

    def log_prob(self, x: Tensor) -> Tensor:
        z, log_det = self.forward(x)
        base_log_prob = self.base_distribution.log_prob(z).sum(dim=-1)
        return base_log_prob + log_det

    @torch.no_grad()
    def sample(self, num_samples: int, device: Optional[torch.device] = None) -> Tensor:
        device = device or self.base_mean.device
        z = self.base_distribution.sample((num_samples,)).to(device)
        x, _ = self.inverse(z)
        return x


__all__ = [
    "AffineCoupling",
    "DiffusionDenoiser",
    "GANDiscriminator",
    "GANGenerator",
    "GaussianDiffusionScheduler",
    "MarketRegimeVAE",
    "NormalizingFlowModel",
    "ScenarioGAN",
    "TimeEmbedding",
    "VAEOutput",
]
