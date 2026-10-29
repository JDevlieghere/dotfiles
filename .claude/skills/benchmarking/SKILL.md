---
name: benchmarking
description: Measure command runtime with hyperfine, never `time`. Load when timing a command, comparing the performance of two builds or implementations, or backing a performance claim with numbers.
---

# Benchmarking

Measure with `hyperfine`, never `time`, `/usr/bin/time`, or ad-hoc timestamps. One
`time` run is a single noisy sample; hyperfine repeats runs, reports mean ± σ and
range, and warns about outliers.

## Basics

```bash
hyperfine --warmup 3 '<cmd>'
```

- `--warmup N` discards N runs to warm caches. For cold-cache numbers, use `--prepare '<cmd>'` instead.
- `-N` skips the intermediate shell (no pipes or redirects). Use it for commands under ~5 ms, where shell spawn dominates; hyperfine warns when this applies.
- `--runs N` or `--min-runs N` raises the sample count for noisy commands.
- `--setup` and `--cleanup` run once per command; `--prepare` and `--conclude` run around every timing run.
- Output is discarded. `--show-output` debugs a misbehaving command.
- A non-zero exit aborts the benchmark unless `-i` is passed.

## Comparing

Benchmark alternatives in one invocation so they share conditions. Hyperfine reports
the relative speedup.

```bash
hyperfine -w 3 -n before './build-base/bin/tool args' -n after './build/bin/tool args'
```

- `--reference '<cmd>'` sets the baseline for relative speed.
- `-L var a,b,c` or `-P var min max` sweeps a parameter, substituted as `{var}`.

## Reporting

- Report mean ± σ and the relative speedup, never a single best run.
- A difference within σ is noise. Say so rather than claim a win.
- Measure optimized builds. Debug or assertion-enabled numbers don't reflect real performance.
- `--export-markdown FILE` produces a table for PRs and commit messages; `--export-json FILE` keeps raw samples.
