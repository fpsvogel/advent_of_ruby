# Updating downloaded solutions

Here is how to download solutions from a new Advent of Code, and update the gem to include them.

After a new Advent of Code is over:

1. Copy the Reddit megathread IDs and add them to `megathread_ids.rb`. Megathreads are listed on this page: https://www.reddit.com/r/adventofcode/?f=flair_name%3A%22SOLUTION%20MEGATHREAD%22
2. Run the following commands, substituting `2025` for the year of the recent Advent of Code:
  - `bin/download_solutions reddit -y 2025`
  - `bin/download_solutions github -y 2025`
