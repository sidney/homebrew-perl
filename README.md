# sidney perl

Homebrew keg_only formulae for development testing using various versions of perl on recent macOS
Do not use this tap for released versions of perl, instead get perl from homebrew/core
Older perl versions are patched so compiler options are compatible with recent versions of macOS
when building CPAN modules, and get latest versions of the core modules from CPAN.

## How do I install these formulae? Install the latested released minor version 5.XX.Y of 5.XX
`brew install sidney/perl/perl@5.XX`

Or `brew tap sidney/perl` and then `brew install perl@5.XX`.

After installing use `brew link sidney/perl/perl@5.XX`

## Documentation
`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## Development
When updating the formula, test them with brew audit --strict --online and --new

To build new bottles, for each perl version individually, create a branch in git,
do some edit to the formula file to commit, push the new branch, create a pr from it,
wait for the test-bot action to successfully complete, then label the pr with pr_pull
which will trigger the pr-pull action that retrieves the bottles created by test-bot
