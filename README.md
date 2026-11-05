# RailGlue

Run several Rails apps side by side on one `localhost`, as if they were
one app. Each app gets its own container, its tools come from
[mise](https://mise.jdx.dev/), nginx routes URL prefixes to apps, and all
databases share one PostgreSQL and/or MySQL server, plus one Redis server.

## Requirements

- Docker with Compose v2, usable by your user (`docker ps` works).
- Ruby 3.0+ on the host, for `bin/railglue` and the tests (stdlib only).

## Quick start

```sh
git submodule add git@example.com:you/shop.git apps/shop
$EDITOR railglue.yml        # list the app; see the comments in that file
bin/railglue up -d --build  # first boot installs Ruby and gems; be patient
bin/railglue urls
```

Each app needs a Ruby version in `.ruby-version`, `.tool-versions` or
`mise.toml`. `railglue.yml` is the single source of truth.
`bin/railglue` turns it into `.railglue/<project>/compose.yaml` and
`nginx.conf`. Those files are regenerated before every command, so don't
edit them.

## Commands

| Command | Does |
| --- | --- |
| `bin/railglue up -d --build` | Build and start everything |
| `bin/railglue logs -f shop` | Follow one app's logs |
| `bin/railglue exec shop bin/rails c` | Rails console in a running app |
| `bin/railglue rspec shop [ARGS]` | Run the app's rspec suite |
| `bin/railglue down` | Stop everything (add `-v` to drop data) |

Any command that isn't `generate`, `rspec`, `urls` or `help` is passed to
`docker compose`. Use `--config FILE` or `$RAILGLUE_CONFIG` to choose
another config file.

## How it works

- **Mount paths.** Puma loads `docker/app/config.ru`, which wraps the app
  in `map RAILGLUE_MOUNT_PATH`. Rails sees the prefix as `SCRIPT_NAME`, so
  routes and URL helpers include it. You don't have to change the app.
  `RAILS_RELATIVE_URL_ROOT` is set too, for asset paths.
- **Databases.** Each app gets `DATABASE_URL` pointing at
  `<name>_development` on the shared server (PostgreSQL unless the app
  sets `database`). `rspec` switches to `<name>_test`. `db:prepare`
  creates both as needed.
- **Redis.** Apps with `redis: true` get `REDIS_URL`. Each app has its
  own Redis database number for development and another for tests,
  based on its position in `apps:`. Reordering the list reassigns them.
- **Browsers.** The image includes Chromium and chromedriver, with the
  flags it needs to run inside a container.
  `driven_by :selenium, using: :headless_chrome` (or Cuprite) works
  without extra setup.
- **Routing check.** nginx adds an `X-Railglue-App` header to every
  response.

## Tests

The tests use Minitest, which ships with Ruby.

```sh
rake test            # unit tests (fast, no Docker)
rake test:e2e        # boot railglue.yml's apps and check each homepage
rake test:fixtures   # boot 3 fixture apps; check routing, DBs, rspec
```

`test:fixtures` uses `test/fixtures/railglue.yml`: two PostgreSQL apps at
`/` and `/beta` (beta also uses Redis), plus a MySQL app at `/gamma`,
served on port 3999. It also runs each app's request specs and a
Capybara system spec. Set `RAILGLUE_E2E_KEEP=1` to leave the stack
running afterwards.

## Security notes

This is a development environment only.

- The database superusers and Redis use the fixed password `railglue`.
  Database and Redis ports are never published to the host; only the
  apps can reach them. nginx listens only on `127.0.0.1`.
- The image installs mise with `curl https://mise.run | sh`. The version
  is pinned (`MISE_VERSION`), but the build trusts that script.
- Chromium runs with `--no-sandbox` because its sandbox can't start in an
  unprivileged container. Only point system tests at trusted pages.
- `mise.toml` files under `/app` are trusted automatically, so only add
  apps whose code you trust.
- Base images are pinned by tag, not by digest.
