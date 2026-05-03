# Correlation Structures and Regime Shifts in Nordic Stock Markets
This repository contains the codes for producing the figures from the following paper:
M. A. Girnyk, "Correlation Structures and Regime Shifts in Nordic Stock Markets", Applied Mathematical Finance, 2026.

# Abstract
Financial markets exhibit time-varying interdependencies and abrupt regime shifts, with diversification benefits often deteriorating during crises. This paper studies time-varying dependencies in Nordic equity markets and examines whether correlation-eigenstructure dynamics can be exploited for regime-aware portfolio construction. Using two decades of daily data for the OMXS30, OMXC20 and OMXH25 universes, rolling correlation matrices display pronounced regime dependence: stress episodes are associated with a sharp increase in the leading eigenvalue and counter-cyclical behavior of the second eigenvalue. Beyond these broad regularities, the Nordic markets are shown to form a tightly integrated regional system in the dominant eigenmode, while remaining heterogeneous in the strength and persistence of the second mode. Moreover, eigenportfolio regressions are shown to be consistent with a market-factor interpretation of the dominant eigenmode. Building on these findings, the paper proposes a regime-aware allocation framework that combines correlation-matrix cleaning, an eigenvalue-ratio crisis indicator and long-only optimization with constraints that bound exposures to dominant systematic eigenmodes. Backtests indicate that the proposed approach improves downside protection and risk-adjusted performance relative to a na\"{i}ve minimum-variance benchmark during crises, while remaining competitive with state-of-the-art benchmarks in tranquil periods. The gains are shown to remain robust to reasonable variation in the crisis-period exposure thresholds.

# Preprint
A preprint of the article available at https://arxiv.org/pdf/2601.06090

## Software requirements
The codes have been developed in Matlab 2022b and requires the Optimization Toolbox package. They generate all the figures and tables in the paper.

## License
This code is licensed under the Apache-2.0 license. If you use this code in any way for research that results in a publication, please cite the article above.
