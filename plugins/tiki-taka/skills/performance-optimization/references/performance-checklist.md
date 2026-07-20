# Performance Checklist (reference)

Extended checklists and command reference for the `performance-optimization` skill.
See `../SKILL.md` for the workflow and anti-pattern fixes this expands on.

## Frontend audit

- [ ] LCP element identified; its request is not render-blocked or lazy-loaded
- [ ] Above-the-fold images have explicit `width`/`height` and `fetchpriority="high"`
- [ ] Below-the-fold images use `loading="lazy"` + `decoding="async"`
- [ ] Fonts preloaded; `font-display: swap` set; subset to used glyphs
- [ ] `preconnect` / `dns-prefetch` for third-party origins on the critical path
- [ ] JS bundle split by route; heavy rarely-used features dynamically imported
- [ ] No long tasks (>50ms) on the main thread during interaction
- [ ] No layout shift from late content, ads, or unsized media

## Backend audit

- [ ] No N+1 queries — list endpoints use joins/includes or batched loads
- [ ] All list endpoints paginated with a hard max page size
- [ ] Indexes cover the columns in every WHERE / ORDER BY / JOIN on hot paths
- [ ] Connection pool sized to load; no pool exhaustion under peak
- [ ] Frequently-read, rarely-changed data cached with a TTL and clear invalidation
- [ ] Cache-Control / ETag set on cacheable responses
- [ ] No synchronous heavy compute blocking the event loop / request thread

## Commands

```bash
# Lighthouse (single run)
npx lighthouse https://example.com --output html --view

# Lighthouse CI (regression gate)
npx lhci autorun

# Bundle size gate
npx bundlesize --config bundlesize.config.json

# Analyze a webpack/Vite bundle
npx vite-bundle-visualizer          # Vite
npx webpack-bundle-analyzer stats.json   # webpack

# DB slow-query log (Postgres): set in postgresql.conf
#   log_min_duration_statement = 200   # log queries > 200ms

# Explain a slow query
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
```

## Verification loop

1. Capture baseline numbers (Lighthouse score, p95 latency, bundle KB).
2. Apply one change addressing the identified bottleneck.
3. Re-measure the same numbers under the same conditions.
4. Keep the change only if the target metric improved without regressing others.
5. Add a CI gate (budget, lhci, bundlesize) so the win doesn't erode.
