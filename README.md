
# Reproducible CBS datasets using the `synthpop.extract` package
[![R-CMD-check](https://github.com/sodascience/synthpop.extract/actions/workflows/r-cmd-check.yml/badge.svg)](https://github.com/sodascience/synthpop.extract/actions/workflows/r-cmd-check.yml)

The goal of this package is to establish a procedure for exporting synthetic datasets based on real data at Statistics Netherlands
([CBS](https://www.cbs.nl/en-gb)). This is a repository containing code that generates synthetic datasets specialized to CBS datasets using [`synthpop.extract`](https://github.com/cran/synthpop) package and a tutorial guiding how to utilize the package.

## Installation
The package can be installed using the `remotes` package:

```R
remotes::install_github("sodascience/synthpop.extract")
```

On the CBS remote access (RA) environment, you first need to upload the package as a folder (subject to checks by the RA team). This folder can be downloaded from the releases page [here](https://github.com/sodascience/synthpop.extract/releases/latest). Once the folder is on the RA environment, unzip it to a nice location and install the package as follows:

```R
install.packages("C:/path/to/synthpop.extract", repos = NULL, type = "source")
```

## Getting started
You can find documentation on getting started with this package on the SoDa team's website [`here`](https://odissei-soda.nl/tutorials/post-3/). 

## Contact
This project is developed and maintained by the [ODISSEI Social Data
Science (SoDa)](https://odissei-data.nl/nl/soda/) team.

<img src="img/soda_logo.png" alt="SoDa logo" width="250px"/>

Do you have questions, suggestions, or remarks? File an issue in the issue tracker or feel free to contact the team via https://odissei-soda.nl.
