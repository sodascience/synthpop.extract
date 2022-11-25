
# Reproducible CBS datasets using the `synthpop.extract` package

Our goal is to establish a procedure for exporting synthetic datasets
based on real data at Statistics Netherlands
([CBS](https://www.cbs.nl/en-gb)).  
This is a repository containing code that generates synthetic datasets
specialized to CBS datasets using
[`synthpop.extract`](https://github.com/cran/synthpop) package and a tutorial
guiding how to utilize the package.

## Installation

The package can be installed:

> library(devtools)

> remotes::install.packages("sodascience/synthpop.extract")

> library(synthpop.extract

## Description

-   `/R` folder contains four R scripts. `data.R` describes the data included in the package, `extract_params.R` has a function that extracts
    model parameters to excel, `read_write.R` has functions that read in the excel sheets, load the parameters back in R, and `generate.R` has a function that generates synthetic datasets based on the parameters.

-   `/data` folder contains two `Birthweight.rda` and `big5.rda` data files.

-   `/examples` folder contains the tutorial (`getting_started.html`) and demo files.


## Contact

Do you have questions, suggestions, or remarks? File an issue in the
issue tracker or feel free to contact [Erik-Jan van
Kesteren](https://github.com/vankesteren)
([@ejvankesteren](https://twitter.com/ejvankesteren)).
