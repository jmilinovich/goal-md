# Goal: Bring Storefront API test coverage from 47% to 90%

We have a FastAPI service (`storefront-api`) with 43 endpoints across 6 resource groups. Half of them have zero test coverage. The test suite takes 12 seconds to run and most of the existing tests are for the auth and products modules — everything else was written during a hackathon in March and never got tests. The hackathon team has since left.

An agent should be able to grind through this autonomously: pick the next uncovered endpoint, write tests, run them, check coverage, commit, repeat. The hard part isn't writing the tests — it's that half the untested code has implicit dependencies on Stripe webhook state or assumes a specific order of database seeding that you only discover when you actually try to call the endpoint in isolation. The `webhooks` module is the worst offender: the handler assumes `event.data.object` has been pre-validated by Stripe's SDK, but in tests there's no SDK — you're constructing events by hand and the validation is stricter than you'd expect.

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
| Test `POST /api/v1/orders` | +4-6% | Create order with valid cart. Assert 201, check response schema. Mock Stripe payment intent. **Gotcha**: the handler calls `inventory.reserve()` internally — if you don't seed inventory for the SKUs in your cart, you get a 409 that looks like a Stripe error but is actually an inventory error. Ask me how I know. |
| Test `GET /api/v1/orders/{id}` | +2-3% | Seed an order, fetch by ID. Test 200 and 404. Also test fetching another merchant's order — should 404, not 403 (we intentionally don't leak existence). |
| Test `PATCH /api/v1/orders/{id}/cancel` | +2-3% | Cancel a pending order. Assert status transition. Test cancelling already-shipped (expect 409). Test cancelling already-cancelled (expect 409 with distinct error code `ORDER_ALREADY_CANCELLED` — the handler has two 409 branches and only one is currently covered). |
| Test `GET /api/v1/orders` with filters | +2-3% | Pagination, `?status=pending`, `?created_after=2024-01-01`. Assert correct filtering. **Edge case**: `?status=refunded` only returns fully-refunded orders, not partial refunds — this has confused QA before and the behavior is intentional. |
| Test `POST /api/v1/orders/{id}/refund` | +2% | Full and partial refund. Mock Stripe refund call. Assert amount validation. **The `/orders/:id/refund` endpoint returns 403 when called without `admin` or `merchant:refund` scope** — this is the only endpoint that checks fine-grained OAuth scopes instead of just role. Test both scope-missing and role-missing cases separately. |

### inventory module (target: 0% -> 80%+)

| Action | Impact | How |
|--------|--------|-----|
| Test `GET /api/v1/inventory/{sku}` | +3-4% | Seed inventory records, fetch by SKU. Test 200 response with `quantity`, `reserved`, `available` fields. **Note**: `available` is computed (`quantity - reserved`), not stored — verify the math is right when `reserved > 0`. Also test with a SKU containing special characters (`SKU-2024/Q1#PROMO`) — the router uses path params and the slash needs URL encoding. I lost 20 minutes to this. |
| Test `POST /api/v1/inventory/adjust` | +3-4% | Positive and negative adjustments. Assert new quantity. Test negative-below-zero (expect 422 with `INSUFFICIENT_STOCK`, not generic validation error). Also test adjustment of exactly zero — it's allowed but returns 200 with no change, which is weird but intentional. The response body still includes an `adjustment_id` for the zero-adjustment, and it shows up in the audit log. |
| Test `POST /api/v1/inventory/reserve` | +2-3% | Reserve stock for an order. Assert `reserved` field increments. Test over-reserve (expect 409). **Concurrency note**: two simultaneous reserves can both succeed if they read the same snapshot — the handler uses `SELECT ... FOR UPDATE` but only inside a transaction. Worth testing with `available = 1` and two rapid reserve calls. In SQLite this won't reproduce the race, but the test documents the expectation. |
| Test `POST /api/v1/inventory/bulk-import` | +2-3% | Upload CSV fixture. Assert all SKUs created. Test malformed CSV (expect 422 with row-level errors). The error response includes `{"errors": [{"row": 3, "field": "quantity", "message": "..."}]}` — assert the structure, not just the status code. **Gotcha**: the CSV parser expects `\n` line endings. If your test fixture has `\r\n` (which happens if you create it on Windows or with certain editors), the parser silently drops the last column of every row. Use `b"sku,quantity\nABC,10\n"` explicitly. |
| Test `GET /api/v1/inventory` with low-stock filter | +1-2% | `?below_threshold=10`. Assert only low-stock items returned. Also verify that items with exactly `available = 10` are included (the filter is `<=`, not `<`). Edge case: items with `available = 0` should also appear — they did not until a bugfix in v2.3 and there's a regression test comment in the router for it. |

### webhooks module (target: 0% -> 75%+)

| Action | Impact | How |
|--------|--------|-----|
| Test `POST /api/v1/webhooks` | +2-3% | Register a webhook URL with event types. Assert 201. Test duplicate URL (expect 409). Also test registering with an unreachable URL — the handler does a HEAD check on registration and returns 422 if the URL doesn't respond within 5s. Mock this with `respx`. |
| Test `DELETE /api/v1/webhooks/{id}` | +1-2% | Remove a registration. Assert 204. Test nonexistent (expect 404). |
| Test `GET /api/v1/webhooks` | +1% | List all registrations for the authenticated merchant. Should not return other merchants' webhooks — seed two merchants, assert isolation. |
| Test webhook delivery retry logic | +3-4% | Seed a failed delivery, trigger retry via `POST /api/v1/webhooks/{id}/retry`. Mock the target URL. Assert exponential backoff headers. The retry schedule is 1s, 5s, 25s, 125s — the `next_retry_at` field in the response should reflect this. |
| Test HMAC signature verification | +2-3% | The `X-Storefront-Signature` header. Compute expected HMAC, assert middleware validates. Test tampered payload (expect 401). **The signing key rotates** — `WEBHOOK_SIGNING_KEY` in config. Both the current and previous key should be accepted during the rotation window. |

### admin module (target: 33% -> 80%+)

| Action | Impact | How |
|--------|--------|-----|
| Test `GET /api/v1/admin/metrics` | +2% | Assert response includes `total_orders`, `revenue_30d`, `active_users`. Requires admin role — test with regular user (expect 403). **The `revenue_30d` field is a string like `"12345.67"`, not a float** — the serializer uses `Decimal` to avoid floating-point drift. Assert the type. |
| Test `POST /api/v1/admin/users/{id}/suspend` | +2-3% | Suspend a user. Assert they can't authenticate after. Test suspending an admin (expect 403 — admins can't suspend other admins, only superadmins can). Test suspending yourself (expect 403 with `CANNOT_SELF_SUSPEND`). |
| Test `GET /api/v1/admin/audit-log` | +2-3% | Seed some actions, query with `?action=order.cancel&since=2024-06-01`. Assert pagination, assert log entries have `actor`, `action`, `timestamp`, `details`. **Pagination uses cursor, not offset** — the `next` field is an opaque token, not a page number. |

## Known Issues

Things the agent will run into and should work around, not try to fix:

- **`conftest.py` has a global `event_loop` fixture** that conflicts with `pytest-asyncio` 0.23+. If you see `RuntimeError: Event loop is closed`, pin `pytest-asyncio<0.23` in the test deps. We know. It's on the backlog.
- **The `orders` router imports `app.services.email`** which tries to initialize a SendGrid client at import time. The existing `conftest.py` patches this at the module level, but if you import the router in a new way (e.g., for type hints), the patch might not be active yet. Always import through the test client, not directly.
- **SQLite doesn't enforce foreign keys by default.** The test DB config has `PRAGMA foreign_keys = ON` but this sometimes gets lost if you create a second connection. If a test passes locally but shouldn't (e.g., inserting an order for a nonexistent user), this is probably why.
- **`factories.OrderFactory` sets `status="pending"` by default** but the factory doesn't call `inventory.reserve()`. So if you create an order via the factory and then try to cancel it, the cancel handler checks reserved inventory and panics because there's nothing to unreserve. Either use `factories.OrderFactory(status="confirmed")` with a matching `InventoryReservationFactory`, or create orders through the API endpoint which handles both. We've gone back and forth on fixing the factory and decided the explicit approach is less magic.
- **Webhook signature tests are timezone-sensitive.** The HMAC payload includes a timestamp, and the handler rejects signatures older than 5 minutes. If your test constructs a signature with `datetime.utcnow()` but the handler uses `time.time()`, you'll get intermittent 401s depending on clock resolution. Use the `freezegun` fixture from conftest.

## Constraints

1. **No mocking the database** — Use the real SQLite test DB. Factory Boy for fixtures. Tests must exercise actual SQLAlchemy queries, not mock them away.
2. **Mock all external services** — Stripe, SendGrid, any webhook targets. Use `respx` for httpx mocking. No test should make a real HTTP call.
3. **Each test file maps 1:1 to a router file** — `app/routers/orders.py` -> `tests/test_orders.py`. Don't create a separate file per endpoint.
4. **No `# pragma: no cover`** — Don't game the metric. If code is untestable, note it in the commit message and move on.
5. **Tests must be independent** — No ordering dependencies. Each test sets up its own fixtures via factories. `pytest-randomly` is in the dev deps for a reason.
6. **Keep the suite under 30 seconds** — If a new test is slow, it's probably hitting something it shouldn't be. Fix the mock.
7. **Use `factories.py` for all test data** — Don't hand-build dicts. The factories handle FK relationships and defaults. If a factory doesn't exist for the model you need, add one — don't inline the creation.

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
