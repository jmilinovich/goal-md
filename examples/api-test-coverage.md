# Goal: Bring Storefront API test coverage from 47% to 90%

We have a FastAPI service (`storefront-api`) with 43 endpoints across 6 resource groups. Half of them have zero test coverage. The test suite takes 12 seconds to run and most of the existing tests are for the auth and products modules — everything else is bare.

An agent should be able to grind through this autonomously: pick the next uncovered endpoint, write tests, run them, check coverage, commit, repeat.

## Fitness Function

```bash
pytest tests/ --cov=app --cov-report=json:coverage.json -q && python scripts/coverage_score.py
```

`coverage_score.py` reads `coverage.json` and outputs:

```
{"score": 47, "max": 100, "by_module": {"auth": 91, "products": 82, "orders": 12, "inventory": 0, "webhooks": 0, "admin": 33}}
```

### Metric Definition

```
score = total_line_coverage_pct (as reported by pytest-cov)
```

The number is just line coverage across `app/`. No branch coverage, no mutation testing — keep it simple. We can layer those on later.

| Component | What it measures |
|-----------|------------------|
| **Line coverage** | % of lines in `app/` executed by the test suite |

### Metric Mutability

- [x] **Locked** — The agent cannot modify `coverage_score.py`, pytest config, or any `# pragma: no cover` directives. Coverage means coverage.

## Operating Mode

- [x] **Converge** — Stop when coverage target is met or progress stalls.

### Stopping Conditions

Stop and report when ANY of:

- Coverage reaches 90%
- 5 consecutive endpoints yield no coverage improvement (tests pass but don't increase the number)
- 50 iterations completed
- A test takes longer than 30 seconds (indicates the agent is doing something wrong — probably hitting real external services)

## Bootstrap

1. `cd storefront-api && pip install -e ".[test]"`
2. `cp .env.example .env.test` — fill in `DATABASE_URL=sqlite:///test.db` and `REDIS_URL=fakeredis://`
3. `pytest tests/ -q` — verify existing tests pass (should be 19 passing)
4. Confirm `coverage_score.py` runs and reports ~47%

## Improvement Loop

```
repeat:
  1. pytest tests/ --cov=app --cov-report=json:coverage.json -q
  2. python scripts/coverage_score.py > /tmp/before.json
  3. Read by_module scores — find the module with the lowest coverage
  4. Within that module, find untested endpoints (cross-reference app/routers/*.py with tests/test_*.py)
  5. Pick the highest-impact action from the Action Catalog
  6. Write the tests
  7. pytest tests/ -q  (quick check — do they pass?)
  8. pytest tests/ --cov=app --cov-report=json:coverage.json -q
  9. python scripts/coverage_score.py > /tmp/after.json
  10. Compare: if coverage improved, commit
  11. If coverage unchanged, check if tests are actually hitting the right code paths — adjust and retry once
  12. If still unchanged, move to the next endpoint
```

Commit messages: `[COV:47→52] orders: add tests for POST /orders and GET /orders/{id}`

## Action Catalog

### orders module (target: 12% -> 85%+)

| Action | Impact | How |
|--------|--------|-----|
| Test `POST /api/v1/orders` | +4-6% | Create order with valid cart. Assert 201, check response schema. Mock Stripe payment intent. |
| Test `GET /api/v1/orders/{id}` | +2-3% | Seed an order, fetch by ID. Test 200 and 404. |
| Test `PATCH /api/v1/orders/{id}/cancel` | +2-3% | Cancel a pending order. Assert status transition. Test cancelling already-shipped (expect 409). |
| Test `GET /api/v1/orders` with filters | +2-3% | Pagination, `?status=pending`, `?created_after=2024-01-01`. Assert correct filtering. |
| Test `POST /api/v1/orders/{id}/refund` | +2% | Full and partial refund. Mock Stripe refund call. Assert amount validation. |

### inventory module (target: 0% -> 80%+)

| Action | Impact | How |
|--------|--------|-----|
| Test `GET /api/v1/inventory/{sku}` | +3-4% | Seed inventory records, fetch by SKU. Test 200 response with `quantity`, `reserved`, `available` fields. |
| Test `POST /api/v1/inventory/adjust` | +3-4% | Positive and negative adjustments. Assert new quantity. Test negative-below-zero (expect 422). |
| Test `POST /api/v1/inventory/reserve` | +2-3% | Reserve stock for an order. Assert `reserved` field increments. Test over-reserve (expect 409). |
| Test `POST /api/v1/inventory/bulk-import` | +2-3% | Upload CSV fixture. Assert all SKUs created. Test malformed CSV (expect 422 with row-level errors). |
| Test `GET /api/v1/inventory` with low-stock filter | +1-2% | `?below_threshold=10`. Assert only low-stock items returned. |

### webhooks module (target: 0% -> 75%+)

| Action | Impact | How |
|--------|--------|-----|
| Test `POST /api/v1/webhooks` | +2-3% | Register a webhook URL with event types. Assert 201. Test duplicate URL (expect 409). |
| Test `DELETE /api/v1/webhooks/{id}` | +1-2% | Remove a registration. Assert 204. Test nonexistent (expect 404). |
| Test `GET /api/v1/webhooks` | +1% | List all registrations for the authenticated merchant. |
| Test webhook delivery retry logic | +3-4% | Seed a failed delivery, trigger retry via `POST /api/v1/webhooks/{id}/retry`. Mock the target URL. Assert exponential backoff headers. |
| Test HMAC signature verification | +2-3% | The `X-Storefront-Signature` header. Compute expected HMAC, assert middleware validates. Test tampered payload (expect 401). |

### admin module (target: 33% -> 80%+)

| Action | Impact | How |
|--------|--------|-----|
| Test `GET /api/v1/admin/metrics` | +2% | Assert response includes `total_orders`, `revenue_30d`, `active_users`. Requires admin role — test with regular user (expect 403). |
| Test `POST /api/v1/admin/users/{id}/suspend` | +2-3% | Suspend a user. Assert they can't authenticate after. Test suspending an admin (expect 403). |
| Test `GET /api/v1/admin/audit-log` | +2-3% | Seed some actions, query with `?action=order.cancel&since=2024-06-01`. Assert pagination, assert log entries have `actor`, `action`, `timestamp`, `details`. |

## Constraints

1. **No mocking the database** — Use the real SQLite test DB. Factory Boy for fixtures. Tests must exercise actual SQLAlchemy queries, not mock them away.
2. **Mock all external services** — Stripe, SendGrid, any webhook targets. Use `respx` for httpx mocking. No test should make a real HTTP call.
3. **Each test file maps 1:1 to a router file** — `app/routers/orders.py` -> `tests/test_orders.py`. Don't create a separate file per endpoint.
4. **No `# pragma: no cover`** — Don't game the metric. If code is untestable, note it in the commit message and move on.
5. **Tests must be independent** — No ordering dependencies. Each test sets up its own fixtures via factories. `pytest-randomly` is in the dev deps for a reason.
6. **Keep the suite under 30 seconds** — If a new test is slow, it's probably hitting something it shouldn't be. Fix the mock.

## File Map

| File | Role | Editable? |
|------|------|-----------|
| `tests/test_orders.py` | Order endpoint tests | Yes — this is the work |
| `tests/test_inventory.py` | Inventory endpoint tests | Yes — this is the work |
| `tests/test_webhooks.py` | Webhook endpoint tests | Yes — this is the work |
| `tests/test_admin.py` | Admin endpoint tests | Yes — this is the work |
| `tests/test_auth.py` | Auth tests (91% coverage) | Only if needed for shared fixtures |
| `tests/test_products.py` | Product tests (82% coverage) | Only if gaps found |
| `tests/conftest.py` | Shared fixtures, test client, DB setup | Yes — add factories here |
| `tests/factories.py` | Factory Boy model factories | Yes — add new factories as needed |
| `app/routers/*.py` | The application code | **No** — we're testing, not changing behavior |
| `app/models/*.py` | SQLAlchemy models | **No** |
| `scripts/coverage_score.py` | Fitness function | **No** |
| `pyproject.toml` | Pytest + coverage config | **No** |

## When to Stop

```
Starting score: 47%
Ending score:   NN%
Iterations:     N
Changes made:   (list of test files created/modified with endpoint count)
Remaining gaps: (modules still below 80%, specific endpoints that proved hard to test)
Next actions:   (branch coverage? mutation testing? integration tests for Stripe webhooks?)
```
