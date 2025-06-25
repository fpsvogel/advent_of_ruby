## [0.3.3] - 2025-06-25

- Added auto-formatting of files created by `arb bootstrap` if RuboCop is available. https://github.com/fpsvogel/advent_of_ruby/pull/1 by [@dvandersluis](https://github.com/dvandersluis)
- Fixed a bug with `arb bootstrap` on Day 8 and 9. [`b324d28`](https://github.com/fpsvogel/advent_of_ruby/commit/b324d28aa7665eba7f6236fa26c02102909fcb27)
- Changed formatting of created spec files: for `let(:input)`, use a `do ... end` block (not curly braces), and use `END` as the heredoc delimiter.
- Bumped Ruby version to 3.4.4

## [0.3.2] - 2025-06-08

- Use YJIT if available.

## [0.3.1] - 2025-03-18

- Fixed bugs in refreshing the AoC cookie.

## [0.3.0] - 2025-03-18

- Added solutions from Reddit (pre-downloaded).
- Made GitHub solutions pre-downloaded as well.

## [0.2.0] - 2024-11-14

- Renamed some command-line options.
- Expanded `arb run` to run variant solutions (e.g. `#part_1_faster`) alongside normal solutions (`#part_1`).

## [0.1.0] - 2024-10-21

- Initial release.
