
# Reproducible CBS datasets using the `synthpop.extract` package

[![R-CMD-check](https://github.com/sodascience/synthpop.extract/actions/workflows/r-cmd-check.yml/badge.svg)](https://github.com/sodascience/synthpop.extract/actions/workflows/r-cmd-check.yml)

The goal of this package is to establish a procedure for exporting synthetic datasets
based on real data at Statistics Netherlands
([CBS](https://www.cbs.nl/en-gb)).  
This is a repository containing code that generates synthetic datasets
specialized to CBS datasets using
[`synthpop.extract`](https://github.com/cran/synthpop) package and a tutorial
guiding how to utilize the package.

## Installation

The package can be installed using the `remotes` package:

```R
remotes::install_github("sodascience/synthpop.extract")
```

## Getting started
You can find documentation on getting started with this package at the [`getting_started.md`](./examples/getting_started.md) file.That file is a tutorial that shows the procedure of generating synthetic datasets using the example dataset (`big5`). For illustrative purposes, the results of factor analyses based on the original dataset and synthetic dataset are compared.

## Structure of the package

-   [`/R`](./R/) folder contains four R scripts. `data.R` describes the data included in the package, `extract_params.R` has a function that extracts model parameters to excel, `read_write.R` has functions that read in the excel sheets, load the parameters back in R, and `generate.R` has a function that generates synthetic datasets based on the parameters.

-   [`/data`](./data/) folder contains two `Birthweight.rda` and `big5.rda` data files.

-   [`/examples`](./examples/) folder contains the tutorial (`getting_started.html`) and other demo files.

## Contact

Do you have questions, suggestions, or remarks? File an issue in the
issue tracker or feel free to contact [Erik-Jan van
Kesteren](https://github.com/vankesteren)
([@ejvankesteren](https://twitter.com/ejvankesteren)).
