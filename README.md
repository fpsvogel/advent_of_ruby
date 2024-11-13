# Advent of Ruby

There are [lots of CLI tools for doing Advent of Code in Ruby](#prior-art). Why make another?

This one does a few things differently:

- It **shows other people's solutions**. This was inspired by [Exercism's community solutions](https://exercism.org/tracks/ruby/exercises/circular-buffer/solutions).
- It's geared toward **leisurely solving puzzles across all years**. You *can* use it for the competition in December, but I didn't build it with that in mind.
- It has **a magically simple CLI**, which mostly involves spamming the `arb` command.
- It uses **Git instead of a database** to track the user's progress and current state.

## Installation

```
gem install advent_of_ruby
```

## Usage

In a directory where you want to store your solutions, run the command `arb` and follow the prompts.

Here's a demo. (Not pictured: perusing other people's solutions for each part, `01_1.rb` and `01_2.rb`.)

https://github.com/user-attachments/assets/e9a868c5-1867-4704-9da5-79aa3b0def89

## Commands

Shortcuts:

- Any command can be abbreviated with its first letter, e.g. `arb b` for `arb bootstrap`.
- Just `arb` is short for `arb run`.
- `arb help` shows a summary of each command.

### `arb bootstrap [YEAR] [DAY]`

- Downloads the input and instructions files for the given day.
- Creates a solution file and a spec file for the given day.
- Downloads other people's solutions, from these repos:
  - <https://github.com/eregon/adventofcode>
  - <https://github.com/gchan/advent-of-code-ruby>
  - <https://github.com/ahorner/advent-of-code>
  - <https://github.com/ZogStriP/adventofcode>
  - <https://github.com/erikw/advent-of-code-solutions>
- *If both arguments are omitted, it bootstraps the next puzzle, i.e. the puzzle after the one that was last committed to Git.*
- *If only the day argument is omitted, it bootstraps the next puzzle of the given year.*
- Opens all of the new files using `editor_command` in `config.yml`.

### `arb run [YEAR] [DAY]`

- Runs specs for the given day.
- If specs pass, also runs the currently in-progress part (Part One or Part Two) of the given day.
- If you're seeing specs run when you want to run only the real input, or vice versa, add one of the following flags:
  - `--spec` (`-s`) runs only the specs. (To run only Part One or Part Two specs, in the spec file change `it` to `xit` on the other part's example to skip it.)
  - `--one` (`-o`) runs only Part One with the real input.
  - `--two` (`-t`) runs only Part Two with the real input.
  - `--variant=my_variant` (`-v my_variant`) runs a variant (`#part_1_my_variant` and/or `#part_2_my_variant` in this case).
- Optionally submits the answer, via a prompt that appears if specs pass and the answer has not already been submitted.
- *If both arguments are omitted, it runs the puzzle that is untracked in Git, if any.*

### `arb commit`

- Commits new or modified solutions to Git.

### `arb progress`

- Shows progress (total and by year) based on the number of your solutions committed in Git.

## Prior art

- [AoC-rb](https://github.com/Keirua/aoc-cli)—this gem was originally based on it
- [AocRb](https://github.com/pacso/aoc_rb)
- [aoc-cli](https://github.com/apexatoll/aoc-cli)
- [aocli](https://github.com/astley92/aocli)
- [advent_of_code_cli](https://github.com/egiurleo/advent_of_code_cli)
- [advent_of_code_generator](https://github.com/Tyflomate/advent_of_code_generator)
- [advent-rb](https://github.com/dnlgrv/advent-rb)
