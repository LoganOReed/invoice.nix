# Latex Invoice Flake
Creates a freshbooks esc invoice so I don't have to pay for it.
data.csv needs invoice number, client, desc's, qty's, and rate's.
the tex file calculates subtotals and grand total, and due date

## To Use
Migrate most recent watson data to data.csv, then run
```
nix run github:LoganOReed/invoice.nix
```
This will generate a pdf in the cwd
