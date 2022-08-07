
# Reproducible CBS datasets using the synthpop package

Our goal is to establish a procedure for exporting synthetic datasets
based on real data at Statistics Netherlands
([CBS](https://www.cbs.nl/en-gb)).  
This is a repository containing code that generates synthetic datasets
specialized to CBS datasets using
[`synthpop`](https://github.com/cran/synthpop) package and a tutorial
guiding how to utilize the code.

## Description

-   `synthpop_extractor.R` file contains three functions that extract
    model parameters to excel, read in the excel sheets, load the
    parameters back in R, and generate synthetic datasets based on the
    parameters.

-   `/raw_data` folder contains `source.txt` file that describes where
    you can download the original dataset that is used in the tutorial.

-   `/data` folder contains the cleaned up version of dataset
    (`big5.RDS`). The code that is used to process the original raw
    dataset can be found in `process_rawdata.R`.

-   `getting_started.html` is the tutorial that shows the procedure of
    generating synthetic dataset using the example dataset (`big5.RDS`).
    For illustrative purposes, the results of factor analyses based on
    the original dataset and synthetic dataset are compared.

![Factor analysis baased on original data](/img/CFA_originaldata)

![Factor analysis baased on original data](/img/CFA_syndata.png)

## Contact

Do you have questions, suggestions, or remarks? File an issue in the
issue tracker or feel free to contact [Erik-Jan van
Kesteren](https://github.com/vankesteren)
([@ejvankesteren](https://twitter.com/ejvankesteren)).
