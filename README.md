# Advent of Ruby

There are [lots of CLI tools for doing Advent of Code in Ruby](#prior-art). Why make another?

This one does a few things differently:

- It shows other people's solutions. This was inspired by [Exercism's community solutions](https://exercism.org/tracks/ruby/exercises/circular-buffer/solutions).
- It's not geared toward the competition in December, but instead toward leisurely solving puzzles across all years.
- It has a CLI that is magically simple, which mostly involves spamming the `arb` command.
- It uses Git instead of a database to track the user's progress and current state.

## Installation

This gem isn't published yet, so for now you can install it by running these commands:

```
git clone https://github.com/fpsvogel/advent_of_ruby.git
cd advent_of_ruby
rake install
```

## Usage

1. Create a directory where you want to store your solutions.
2. In that directory, run the command `arb` and follow the prompts!

## Commands

Okay, if you *really* want to know all the details, here they are.

Note: all commands can be abbreviated with their first letter, e.g. `arb b` for `arb bootstrap`.

- `arb bootstrap [YEAR] [DAY]`
  - Commits new and modified solutions to Git.
  - Downloads the input and instructions files for the given day.
  - Creates a source file and a spec file for the given day.
  - Downloads other people's solutions, from these repos:
    - <https://github.com/eregon/adventofcode>
    - <https://github.com/gchan/advent-of-code-ruby>
    - <https://github.com/ahorner/advent-of-code>
    - <https://github.com/ZogStriP/adventofcode>
    - <https://github.com/erikw/advent-of-code-solutions>
  - *If both arguments are omitted, it bootstraps the next puzzle, i.e. the puzzle after the one that was last committed to Git.*
  - *If only the day argument is omitted, it bootstraps the next puzzle of the given year.*
  - Opens all of the new files using `editor_command` in `config.yml`.
- `arb run [YEAR] [DAY]`
  - Runs specs for the given day.
  - Unless specs fail, runs the currently in-progress part (Part One or Part Two) of the given day.
  - If you're seeing specs run when you want to run only the real input, or vice versa, add one of the following flags:
    - `--spec` (`-s`) runs only the specs. (To run only Part One or Part Two specs, in the spec file change `it` to `xit` on the other one to skip it.)
    - `--real_part_1` (`-o`) runs only Part One with the real input.
    - `--real_part_2` (`-t`) runs only Part Two with the real input.
  - Optionally submits the answer, via a prompt that appears if it has not already been submitted.
  - *If both arguments are omitted, it runs the puzzle that is untracked in Git, if any.*
- `arb git` commits new and modified solutions to Git. This is handy if (unlike the basic "solve and then run `arb bootstrap`" flow) you like to make multiple commits per solution, e.g. one after your own solution and then another after improving it based on other people's solutions.
- `arb progress` shows progress (total and by year) based on the number of your solutions committed in Git.
- `arb help` shows a summary of each command.

## Prior art

- [AoC-rb](https://github.com/Keirua/aoc-cli)—this gem was originally based on it
- [AocRb](https://github.com/pacso/aoc_rb)
- [aoc-cli](https://github.com/apexatoll/aoc-cli)
- [aocli](https://github.com/astley92/aocli)
- [advent_of_code_cli](https://github.com/egiurleo/advent_of_code_cli)
- [advent_of_code_generator](https://github.com/Tyflomate/advent_of_code_generator)
- [advent-rb](https://github.com/dnlgrv/advent-rb)
