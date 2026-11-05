# Railglue
Create a docker compose development environment called RailGlue that can run
multiple Ruby on Rails apps simultaneously as though they were one app:
- Assume each app is a git submodule under `apps/`.
- Spin up a container for each app.
- Use [mise](https://mise.jdx.dev/) to install each app's required software.
- Use an nginx reverse proxy to host all the apps together on the same
  `localhost`.
- Allow the developer to define where each app's root url should be; for
  example, one could be at true root `/`, while two others are at `/app2` and
  `/app3`.
- Expect each app to have its own database, but put all the databases in a
  shared container. So if two apps use PostgreSQL, for example, they can both
  be handled under the same PostgreSQL instance.
- Allow containerized testing of each app through rspec, with support for
  browser simulation systems like capybara.
- Include a basic automated test for the overall environment. Make sure each
  app spins up and renders a homepage at the expected URL.

# General Guidelines
- Don't repeat yourself: every piece of knowledge must have a single,
  unambiguous, authoritative representation within the system.
- Break up functions so each one serves a single purpose.
- Make sure every line is 80 characters or less and remove any trailing
  whitespace.
- Keep in-code documentation as short and to-the-point as possible. Avoid
  multi-line comments in the middle of functions.
- Where appropriate, follow NASA's [Power of 10 Rules][power-of-10],
  specifically:
  - Avoid recursion.
  - Give all loops a fixed upper bound.
  - Prefer static memory allocation over dynamic.
  - Declare all objects/variables at the smallest possible scope.
  - Code must compile/parse without warnings.
- After each change, check syntax and run some manual tests to make sure all
  core features still work.
- Write automated tests for all features.
  - When writing tests, follow the [test pyramid][test-pyramid] strategy,
    where the tests are mostly unit tests, some integration tests, and
    minimal end-to-end tests.
  - If a testing framework does not already exist in the repo, offer
    suggestions for one.
- Check for security vulnerabilities and warn the developer of any you find,
  either in the code itself or in dependencies.
- Make atomic commits.

[power-of-10]:
  https://en.wikipedia.org/wiki/The_Power_of_10:_Rules_for_Developing_Safety-Critical_Code
[test-pyramid]: https://en.wikipedia.org/wiki/Software_testing
