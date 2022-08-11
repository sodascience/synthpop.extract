We are trying to establish a procedure for exporting synthetic datasets
based on real datasets at Statistics Netherlands
([CBS](https://www.cbs.nl/en-gb)). We want to use this synthetic data to
make research reproducible. The general procedure is as follows:

1.  Extract parameters of models based on the original data using the
    `synthpop` package.
2.  Export the parameters to Excel and store them in an xlsx file.
3.  Import the xlsx file from the CBS environment into your local
    device.
4.  Read in the excel file and load the parameters back in R.
5.  Generate synthetic data based on the model parameters.

Here we will illustrate each step of the procedure using an example data
set.

<hr>

# Preparation

First, we need to load the following packages and import the functions
(i.e., `synp_get_param`, `synp_read_sheets`, `synp_gen_syndat`) from the
`synthpop_extractor.R` file.

    ## load packages
    library(skimr)
    library(stringr)
    library(readxl)
    library(writexl)
    library(synthpop)
    library(lavaan)
    library(lavaanPlot)

    ## import the functions
    source("synthpop_extractor.R")

# Example dataset

`big5_kag.csv` is a [Big Five personality
traits](https://en.wikipedia.org/wiki/Big_Five_personality_traits) data
set found on
[kaggle](https://www.kaggle.com/datasets/tunguz/big-five-personality-test).
It contains more than a million (1,015,342) answers collected from 2016
to 2018. It includes 50 questions, which participants rate by themselves
on a five-point-Likert scale where a *1* represents *complete
disagreement*, a *3* for a *neutral* response and a *5* for *full
agreement*. For ease of computation, here we will analyze only a subset
of the dataset (e.g., 100,000 answers for 25 questions). The cleaned
dataset can be found in the `data` folder (`big5.RDS`) and the code for
cleaning up can be found in `process_rawdata.R` file.

<details>
<summary>
***See the set of questions used***.
</summary>

<br> **EXT = Extraversion**

-   EXT1 I am the life of the party.
-   EXT2 I don’t talk a lot.
-   EXT3 I feel comfortable around people.
-   EXT4 I keep in the background.
-   EXT5 I start conversations.

**EST = Emotional Stability**

-   EST1 I get stressed out easily.
-   EST2 I am relaxed most of the time.
-   EST3 I worry about things.
-   EST4 I seldom feel blue.
-   EST5 I am easily disturbed.

**AGR = Agreeableness**

-   AGR1 I feel little concern for others.
-   AGR2 I am interested in people.
-   AGR3 I insult people.
-   AGR4 I sympathize with others’ feelings.
-   AGR5 I am not interested in other people’s problems.

**CSN = Conscientiousness**

-   CSN1 I am always prepared.
-   CSN2 I leave my belongings around.
-   CSN3 I pay attention to details.
-   CSN4 I make a mess of things.
-   CSN5 I get chores done right away.

**OPN = Openness to new experiences**

-   OPN1 I have a rich vocabulary.
-   OPN2 I have difficulty understanding abstract ideas.
-   OPN3 I have a vivid imagination.
-   OPN4 I am not interested in abstract ideas.
-   OPN5 I have excellent ideas.

</details>

<br>

    ## load data
    big5 <- readRDS("./data/big5.RDS")

Let’s take a quick look at the data summary.

    ## data summary
    skim(big5)

<details>
<summary>
***See the data summary.***
</summary>

<table>
<caption>Data summary</caption>
<tbody>
<tr class="odd">
<td style="text-align: left;">Name</td>
<td style="text-align: left;">big5</td>
</tr>
<tr class="even">
<td style="text-align: left;">Number of rows</td>
<td style="text-align: left;">100000</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Number of columns</td>
<td style="text-align: left;">25</td>
</tr>
<tr class="even">
<td style="text-align: left;">_______________________</td>
<td style="text-align: left;"></td>
</tr>
<tr class="odd">
<td style="text-align: left;">Column type frequency:</td>
<td style="text-align: left;"></td>
</tr>
<tr class="even">
<td style="text-align: left;">numeric</td>
<td style="text-align: left;">25</td>
</tr>
<tr class="odd">
<td style="text-align: left;">________________________</td>
<td style="text-align: left;"></td>
</tr>
<tr class="even">
<td style="text-align: left;">Group variables</td>
<td style="text-align: left;">None</td>
</tr>
</tbody>
</table>

Data summary

**Variable type: numeric**

<table>
<colgroup>
<col style="width: 12%" />
<col style="width: 9%" />
<col style="width: 12%" />
<col style="width: 4%" />
<col style="width: 4%" />
<col style="width: 2%" />
<col style="width: 3%" />
<col style="width: 3%" />
<col style="width: 3%" />
<col style="width: 4%" />
<col style="width: 37%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">skim_variable</th>
<th style="text-align: right;">n_missing</th>
<th style="text-align: right;">complete_rate</th>
<th style="text-align: right;">mean</th>
<th style="text-align: right;">sd</th>
<th style="text-align: right;">p0</th>
<th style="text-align: right;">p25</th>
<th style="text-align: right;">p50</th>
<th style="text-align: right;">p75</th>
<th style="text-align: right;">p100</th>
<th style="text-align: left;">hist</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">EXT1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2.64</td>
<td style="text-align: right;">1.26</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▇▆▇▅▂</td>
</tr>
<tr class="even">
<td style="text-align: left;">EXT2</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.21</td>
<td style="text-align: right;">1.31</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▅▆▇▇▇</td>
</tr>
<tr class="odd">
<td style="text-align: left;">EXT3</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.29</td>
<td style="text-align: right;">1.22</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▂▆▇▇▅</td>
</tr>
<tr class="even">
<td style="text-align: left;">EXT4</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2.84</td>
<td style="text-align: right;">1.21</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▅▇▇▆▃</td>
</tr>
<tr class="odd">
<td style="text-align: left;">EXT5</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.28</td>
<td style="text-align: right;">1.28</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▃▅▆▇▅</td>
</tr>
<tr class="even">
<td style="text-align: left;">EST1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2.69</td>
<td style="text-align: right;">1.32</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▇▇▆▆▃</td>
</tr>
<tr class="odd">
<td style="text-align: left;">EST2</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.17</td>
<td style="text-align: right;">1.23</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▃▆▇▇▅</td>
</tr>
<tr class="even">
<td style="text-align: left;">EST3</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2.14</td>
<td style="text-align: right;">1.13</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▇▇▃▂▁</td>
</tr>
<tr class="odd">
<td style="text-align: left;">EST4</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2.66</td>
<td style="text-align: right;">1.25</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▆▇▇▅▂</td>
</tr>
<tr class="even">
<td style="text-align: left;">EST5</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.14</td>
<td style="text-align: right;">1.25</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▃▇▇▇▅</td>
</tr>
<tr class="odd">
<td style="text-align: left;">AGR1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.73</td>
<td style="text-align: right;">1.33</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▂▃▃▅▇</td>
</tr>
<tr class="even">
<td style="text-align: left;">AGR2</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.83</td>
<td style="text-align: right;">1.14</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▂▅▇▇</td>
</tr>
<tr class="odd">
<td style="text-align: left;">AGR3</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.73</td>
<td style="text-align: right;">1.27</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▃▃▅▇</td>
</tr>
<tr class="even">
<td style="text-align: left;">AGR4</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.93</td>
<td style="text-align: right;">1.13</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▂▃▇▇</td>
</tr>
<tr class="odd">
<td style="text-align: left;">AGR5</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.71</td>
<td style="text-align: right;">1.16</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▂▅▇▆</td>
</tr>
<tr class="even">
<td style="text-align: left;">CSN1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.29</td>
<td style="text-align: right;">1.18</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▂▅▆▇▃</td>
</tr>
<tr class="odd">
<td style="text-align: left;">CSN2</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.05</td>
<td style="text-align: right;">1.37</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▅▇▆▇▆</td>
</tr>
<tr class="even">
<td style="text-align: left;">CSN3</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.98</td>
<td style="text-align: right;">1.04</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▂▃▇▇</td>
</tr>
<tr class="odd">
<td style="text-align: left;">CSN4</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.36</td>
<td style="text-align: right;">1.23</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▂▅▆▇▆</td>
</tr>
<tr class="even">
<td style="text-align: left;">CSN5</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2.62</td>
<td style="text-align: right;">1.27</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▇▇▇▅▃</td>
</tr>
<tr class="odd">
<td style="text-align: left;">OPN1</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.65</td>
<td style="text-align: right;">1.16</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▂▆▇▇</td>
</tr>
<tr class="even">
<td style="text-align: left;">OPN2</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.91</td>
<td style="text-align: right;">1.10</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▂▅▇▇</td>
</tr>
<tr class="odd">
<td style="text-align: left;">OPN3</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">4.00</td>
<td style="text-align: right;">1.10</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▂▃▆▇</td>
</tr>
<tr class="even">
<td style="text-align: left;">OPN4</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.98</td>
<td style="text-align: right;">1.07</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▁▃▆▇</td>
</tr>
<tr class="odd">
<td style="text-align: left;">OPN5</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">3.79</td>
<td style="text-align: right;">0.99</td>
<td style="text-align: right;">0</td>
<td style="text-align: right;">3</td>
<td style="text-align: right;">4</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">5</td>
<td style="text-align: left;">▁▁▆▇▅</td>
</tr>
</tbody>
</table>

</details>

<br>

# Extract model parameters

As the first step to generate synthetic data, we extract the model
parameters.

-   Note that numbers are not allowed to be in the variable names. The
    variable names can only contain alphabetical characters. Here I
    choose to change the numbers to *Roman numerals*. You are free to
    switch them to anything sensible to you though, as long as they
    consist only of characters.
-   Once the variable names are sorted, get the `synds` object using
    using `synthpop` package. Currently, we only support method `"norm"`
    (for normally-distributed continuous variables) and `"logreg"`(for
    binary variables). Make sure you set `models=TRUE` when calling
    `syn` function.
-   Next, use `synp_get_param` function, which takes the data and
    `synds` object as arguments to extract model parameters.

<!-- -->

    ## convert the number in the variable names to Roman numeral
    colnames(big5) <- c("EXT_I", "EXT_II", "EXT_III", "EXT_IV", "EXT_V", 
                        "EST_I", "EST_II", "EST_III", "EST_IV",  "EST_V", 
                        "AGR_I", "AGR_II", "AGR_III", "AGR_IV",  "AGR_V", 
                        "CSN_I", "CSN_II", "CSN_III", "CSN_IV", "CSN_V", 
                        "OPN_I", "OPN_II", "OPN_III", "OPN_IV", "OPN_V")
    ## get the synds object
    synds <- syn(big5, method="norm", models=TRUE)

    Warning: In your synthesis there are numeric variables with 5 or fewer levels: EXT_II, EXT_IV, EST_I, EST_III, EST_V, AGR_I, AGR_III, AGR_V, CSN_II, CSN_IV, OPN_II, OPN_IV.
    Consider changing them to factors. You can do it using parameter 'minnumlevels'.

    Synthesis
    -----------
     EXT_I EXT_II EXT_III EXT_IV EXT_V EST_I EST_II EST_III EST_IV EST_V
     AGR_I AGR_II AGR_III AGR_IV AGR_V CSN_I CSN_II CSN_III CSN_IV CSN_V
     OPN_I OPN_II OPN_III OPN_IV OPN_V

    ## extract parameters and store them as "model_par"
    model_par <- synp_get_param(big5, synds)

# Export to Excel / Import from CBS

We export the model parameters to Excel using `writexl` package:
`write_xlsx(list of dataframes, filepath)`. Then, you would be able to
import the xlsx file from the CBS environment and store it in your local
device.

    ## export to Excel
    write_xlsx(model_par, "big5.xlsx")

# Read xlsx file into R

We read in the model parameters from xlsx file using `synp_read_sheets`
function: `synp_read_sheets(filepath)`.

    ## read in the parameters
    parameters <- synp_read_sheets("big5.xlsx")

# Generate synthetic data

We can generate the synthetic data using `synp_gen_syndat` function:
`synp_gen_syndat(list of parameters, n = sample size)`.

    ## generate synthetic data
    syndat <- synp_gen_syndat(parameters, n = nrow(big5))

    ## check the synthetic data
    head(syndat)

<details>
<summary>
***Check the synthetic data.***
</summary>

          EXT_I    EXT_II  EXT_III   EXT_IV    EXT_V    EST_I    EST_II   EST_III
    1 1.7967667 4.5696000 2.470643 3.594090 4.198519 2.772357 2.2940055 1.0240887
    2 1.5007013 3.3665465 3.995861 3.043404 1.888603 2.725456 4.1250895 3.0772931
    3 0.2680578 3.3021180 4.042961 2.081508 2.697252 1.983089 3.8994498 1.4229752
    4 2.1136429 2.6683560 2.328611 3.324001 2.376048 0.606386 0.6036654 1.9568738
    5 1.9526136 0.2552039 2.827340 1.287563 2.680024 3.749983 4.6991672 2.8453722
    6 4.3846772 4.3583375 2.510808 3.943423 2.911146 2.809992 4.7573085 0.5804507
        EST_IV    EST_V    AGR_I   AGR_II  AGR_III   AGR_IV     AGR_V    CSN_I
    1 3.351888 2.378564 4.596974 3.976686 3.253106 5.523169 2.8610634 3.778898
    2 1.386318 3.061497 3.289554 2.738364 4.055344 2.856149 2.8726993 3.599830
    3 5.125194 3.286464 2.740520 1.808504 4.838202 3.063368 0.7693168 5.354502
    4 3.580543 1.423675 5.255499 5.670892 4.372636 5.237408 3.9700317 3.614781
    5 1.552014 4.225278 1.282687 2.581844 3.244345 3.566502 2.7901674 2.959656
    6 1.796292 3.621846 5.296630 4.384373 2.047573 4.225048 3.4111598 3.154627
         CSN_II  CSN_III    CSN_IV    CSN_V    OPN_I   OPN_II  OPN_III   OPN_IV
    1 3.8106740 4.519315 4.0367110 2.632301 2.948485 4.144289 3.691886 2.370768
    2 4.3968151 4.349115 3.7182688 1.499465 3.580055 6.402924 2.927798 6.351567
    3 4.8156385 4.910031 4.8085602 4.021736 4.219223 4.960451 5.465395 4.101052
    4 2.5761097 3.982410 4.5385330 2.829688 2.656186 2.827944 3.119061 2.034357
    5 2.2364526 2.227964 4.6671232 3.534914 2.396203 3.630128 2.371671 2.894588
    6 0.7080099 3.920269 0.8335528 2.166659 3.433479 3.402927 6.122450 2.243347
         OPN_V
    1 5.352253
    2 2.758059
    3 4.694848
    4 2.894199
    5 4.197396
    6 3.142482

</details>

<br>

# Run analysis on synthetic data

Here, we run (confirmatory) factor analysis on the synthesized Big5
personality data. Later on, we run the same analysis on the original
data and compare the results to see if both data sets lead to more or
less the same conclusion.

    ## lavaan model formulae
    CFA_model <- '
    EXTRA =~ EXT_I + EXT_II + EXT_III + EXT_IV + EXT_V 
    AGREE =~ AGR_I + AGR_II + AGR_III + AGR_IV + AGR_V 
    EMO   =~ EST_I + EST_II + EST_III + EST_IV + EST_V 
    OPEN  =~ OPN_I + OPN_II + OPN_III + OPN_IV + OPN_V
    CON   =~ CSN_I + CSN_II + CSN_III + CSN_IV + CSN_V 
    '
    ## run CFA on synthetic data
    syn_CFA <- cfa(model = CFA_model, data = syndat, std.lv=TRUE)
    ## assess the fit indices
    fitMeasures(syn_CFA, fit.measures = c("cfi","srmr", "rmsea"))

      cfi  srmr rmsea 
    0.813 0.066 0.066 

<details>
<summary>
***Check the CFA (on synthetic data) results in detail.***
</summary>

    lavaan 0.6-10 ended normally after 18 iterations

      Estimator                                         ML
      Optimization method                           NLMINB
      Number of model parameters                        60
                                                          
      Number of observations                        100000
                                                          
    Model Test User Model:
                                                            
      Test statistic                              116919.160
      Degrees of freedom                                 265
      P-value (Chi-square)                             0.000

    Model Test Baseline Model:

      Test statistic                            625458.621
      Degrees of freedom                               300
      P-value                                        0.000

    User Model versus Baseline Model:

      Comparative Fit Index (CFI)                    0.813
      Tucker-Lewis Index (TLI)                       0.789

    Loglikelihood and Information Criteria:

      Loglikelihood user model (H0)           -3741187.475
      Loglikelihood unrestricted model (H1)   -3682727.895
                                                          
      Akaike (AIC)                             7482494.950
      Bayesian (BIC)                           7483065.725
      Sample-size adjusted Bayesian (BIC)      7482875.043

    Root Mean Square Error of Approximation:

      RMSEA                                          0.066
      90 Percent confidence interval - lower         0.066
      90 Percent confidence interval - upper         0.067
      P-value RMSEA <= 0.05                          0.000

    Standardized Root Mean Square Residual:

      SRMR                                           0.066

    Parameter Estimates:

      Standard errors                             Standard
      Information                                 Expected
      Information saturated (h1) model          Structured

    Latent Variables:
                       Estimate  Std.Err  z-value  P(>|z|)   Std.lv  Std.all
      EXTRA =~                                                              
        EXT_I             0.836    0.004  217.009    0.000    0.836    0.660
        EXT_II            0.905    0.004  230.084    0.000    0.905    0.691
        EXT_III           0.853    0.004  235.714    0.000    0.853    0.704
        EXT_IV            0.858    0.004  239.002    0.000    0.858    0.711
        EXT_V             0.959    0.004  256.354    0.000    0.959    0.750
      AGREE =~                                                              
        AGR_I             0.669    0.005  147.141    0.000    0.669    0.503
        AGR_II            0.674    0.004  177.811    0.000    0.674    0.594
        AGR_III           0.433    0.004   96.378    0.000    0.433    0.341
        AGR_IV            0.788    0.004  213.202    0.000    0.788    0.699
        AGR_V             0.796    0.004  210.257    0.000    0.796    0.690
      EMO =~                                                                
        EST_I             1.081    0.004  264.490    0.000    1.081    0.819
        EST_II            0.723    0.004  182.167    0.000    0.723    0.589
        EST_III           0.786    0.004  220.893    0.000    0.786    0.698
        EST_IV            0.438    0.004  102.049    0.000    0.438    0.349
        EST_V             0.557    0.004  132.607    0.000    0.557    0.445
      OPEN =~                                                               
        OPN_I             0.535    0.004  129.758    0.000    0.535    0.460
        OPN_II            0.794    0.004  206.900    0.000    0.794    0.723
        OPN_III           0.457    0.004  116.120    0.000    0.457    0.415
        OPN_IV            0.708    0.004  189.101    0.000    0.708    0.659
        OPN_V             0.440    0.004  124.628    0.000    0.440    0.443
      CON =~                                                                
        CSN_I             0.693    0.004  169.387    0.000    0.693    0.587
        CSN_II            0.797    0.005  168.217    0.000    0.797    0.583
        CSN_III           0.357    0.004   94.143    0.000    0.357    0.341
        CSN_IV            0.808    0.004  190.368    0.000    0.808    0.654
        CSN_V             0.789    0.004  179.113    0.000    0.789    0.618

    Covariances:
                       Estimate  Std.Err  z-value  P(>|z|)   Std.lv  Std.all
      EXTRA ~~                                                              
        AGREE             0.395    0.004  111.237    0.000    0.395    0.395
        EMO               0.246    0.004   66.386    0.000    0.246    0.246
        OPEN              0.137    0.004   34.000    0.000    0.137    0.137
        CON               0.149    0.004   37.068    0.000    0.149    0.149
      AGREE ~~                                                              
        EMO              -0.071    0.004  -17.432    0.000   -0.071   -0.071
        OPEN              0.198    0.004   47.030    0.000    0.198    0.198
        CON               0.126    0.004   29.356    0.000    0.126    0.126
      EMO ~~                                                                
        OPEN              0.171    0.004   41.849    0.000    0.171    0.171
        CON               0.237    0.004   58.889    0.000    0.237    0.237
      OPEN ~~                                                               
        CON               0.070    0.004   15.891    0.000    0.070    0.070

    Variances:
                       Estimate  Std.Err  z-value  P(>|z|)   Std.lv  Std.all
       .EXT_I             0.905    0.005  189.674    0.000    0.905    0.564
       .EXT_II            0.898    0.005  183.356    0.000    0.898    0.523
       .EXT_III           0.741    0.004  180.280    0.000    0.741    0.505
       .EXT_IV            0.720    0.004  178.370    0.000    0.720    0.494
       .EXT_V             0.716    0.004  166.717    0.000    0.716    0.438
       .AGR_I             1.321    0.007  198.630    0.000    1.321    0.747
       .AGR_II            0.831    0.005  182.753    0.000    0.831    0.647
       .AGR_III           1.426    0.007  214.048    0.000    1.426    0.884
       .AGR_IV            0.651    0.004  151.337    0.000    0.651    0.512
       .AGR_V             0.698    0.005  154.653    0.000    0.698    0.524
       .EST_I             0.575    0.006  104.022    0.000    0.575    0.330
       .EST_II            0.983    0.005  191.841    0.000    0.983    0.653
       .EST_III           0.652    0.004  162.567    0.000    0.652    0.513
       .EST_IV            1.377    0.006  215.764    0.000    1.377    0.878
       .EST_V             1.255    0.006  209.457    0.000    1.255    0.802
       .OPN_I             1.067    0.005  200.191    0.000    1.067    0.788
       .OPN_II            0.575    0.005  124.617    0.000    0.575    0.477
       .OPN_III           1.003    0.005  205.597    0.000    1.003    0.828
       .OPN_IV            0.653    0.004  151.889    0.000    0.653    0.566
       .OPN_V             0.792    0.004  202.352    0.000    0.792    0.804
       .CSN_I             0.913    0.005  176.974    0.000    0.913    0.656
       .CSN_II            1.234    0.007  177.891    0.000    1.234    0.660
       .CSN_III           0.966    0.005  212.219    0.000    0.966    0.884
       .CSN_IV            0.873    0.006  156.813    0.000    0.873    0.572
       .CSN_V             1.009    0.006  168.548    0.000    1.009    0.618
        EXTRA             1.000                               1.000    1.000
        AGREE             1.000                               1.000    1.000
        EMO               1.000                               1.000    1.000
        OPEN              1.000                               1.000    1.000
        CON               1.000                               1.000    1.000

</details>

<br>

    ## plot the CFA model on synthetic data
    lavaanPlot(model = syn_CFA, node_options = list(shape = "box", fontname = "Helvetica"), edge_options = list(color = "grey"), coefs = TRUE, graph_options = list(layout = "circo"))

<div id="htmlwidget-14b8a56fc309f2e14285" style="width:672px;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-14b8a56fc309f2e14285">{"x":{"diagram":" digraph plot { \n graph [ layout = circo ] \n node [ shape = box, fontname = Helvetica ] \n node [shape = box] \n EXT_I; EXT_II; EXT_III; EXT_IV; EXT_V; AGR_I; AGR_II; AGR_III; AGR_IV; AGR_V; EST_I; EST_II; EST_III; EST_IV; EST_V; OPN_I; OPN_II; OPN_III; OPN_IV; OPN_V; CSN_I; CSN_II; CSN_III; CSN_IV; CSN_V \n node [shape = oval] \n EXTRA; AGREE; EMO; OPEN; CON \n \n edge [ color = grey ] \n  EXTRA->EXT_I [label = \"0.84\"] EXTRA->EXT_II [label = \"0.91\"] EXTRA->EXT_III [label = \"0.85\"] EXTRA->EXT_IV [label = \"0.86\"] EXTRA->EXT_V [label = \"0.96\"] AGREE->AGR_I [label = \"0.67\"] AGREE->AGR_II [label = \"0.67\"] AGREE->AGR_III [label = \"0.43\"] AGREE->AGR_IV [label = \"0.79\"] AGREE->AGR_V [label = \"0.8\"] EMO->EST_I [label = \"1.08\"] EMO->EST_II [label = \"0.72\"] EMO->EST_III [label = \"0.79\"] EMO->EST_IV [label = \"0.44\"] EMO->EST_V [label = \"0.56\"] OPEN->OPN_I [label = \"0.54\"] OPEN->OPN_II [label = \"0.79\"] OPEN->OPN_III [label = \"0.46\"] OPEN->OPN_IV [label = \"0.71\"] OPEN->OPN_V [label = \"0.44\"] CON->CSN_I [label = \"0.69\"] CON->CSN_II [label = \"0.8\"] CON->CSN_III [label = \"0.36\"] CON->CSN_IV [label = \"0.81\"] CON->CSN_V [label = \"0.79\"] \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script>

# Run analysis on original data

    ## run CFA on original data
    original_CFA <- cfa(model = CFA_model, data = big5, std.lv=TRUE)
    ## assess the fit indices
    fitMeasures(original_CFA, fit.measures = c("cfi","srmr", "rmsea"))

      cfi  srmr rmsea 
    0.813 0.066 0.066 

<details>
<summary>
***Check the CFA (on original data) results in detail.***
</summary>

    lavaan 0.6-10 ended normally after 19 iterations

      Estimator                                         ML
      Optimization method                           NLMINB
      Number of model parameters                        60
                                                          
      Number of observations                        100000
                                                          
    Model Test User Model:
                                                            
      Test statistic                              116396.465
      Degrees of freedom                                 265
      P-value (Chi-square)                             0.000

    Model Test Baseline Model:

      Test statistic                            621980.047
      Degrees of freedom                               300
      P-value                                        0.000

    User Model versus Baseline Model:

      Comparative Fit Index (CFI)                    0.813
      Tucker-Lewis Index (TLI)                       0.789

    Loglikelihood and Information Criteria:

      Loglikelihood user model (H0)           -3741032.528
      Loglikelihood unrestricted model (H1)   -3682834.295
                                                          
      Akaike (AIC)                             7482185.055
      Bayesian (BIC)                           7482755.831
      Sample-size adjusted Bayesian (BIC)      7482565.149

    Root Mean Square Error of Approximation:

      RMSEA                                          0.066
      90 Percent confidence interval - lower         0.066
      90 Percent confidence interval - upper         0.067
      P-value RMSEA <= 0.05                          0.000

    Standardized Root Mean Square Residual:

      SRMR                                           0.066

    Parameter Estimates:

      Standard errors                             Standard
      Information                                 Expected
      Information saturated (h1) model          Structured

    Latent Variables:
                       Estimate  Std.Err  z-value  P(>|z|)   Std.lv  Std.all
      EXTRA =~                                                              
        EXT_I             0.838    0.004  217.930    0.000    0.838    0.662
        EXT_II            0.903    0.004  230.160    0.000    0.903    0.691
        EXT_III           0.853    0.004  234.583    0.000    0.853    0.701
        EXT_IV            0.860    0.004  239.410    0.000    0.860    0.712
        EXT_V             0.953    0.004  254.331    0.000    0.953    0.746
      AGREE =~                                                              
        AGR_I             0.665    0.005  146.177    0.000    0.665    0.501
        AGR_II            0.677    0.004  177.939    0.000    0.677    0.596
        AGR_III           0.427    0.004   94.987    0.000    0.427    0.336
        AGR_IV            0.787    0.004  212.670    0.000    0.787    0.698
        AGR_V             0.797    0.004  209.239    0.000    0.797    0.688
      EMO =~                                                                
        EST_I             1.077    0.004  264.435    0.000    1.077    0.819
        EST_II            0.722    0.004  181.993    0.000    0.722    0.589
        EST_III           0.783    0.004  219.824    0.000    0.783    0.695
        EST_IV            0.439    0.004  102.545    0.000    0.439    0.351
        EST_V             0.561    0.004  133.401    0.000    0.561    0.448
      OPEN =~                                                               
        OPN_I             0.534    0.004  129.802    0.000    0.534    0.461
        OPN_II            0.796    0.004  206.772    0.000    0.796    0.725
        OPN_III           0.450    0.004  114.457    0.000    0.450    0.410
        OPN_IV            0.702    0.004  187.002    0.000    0.702    0.653
        OPN_V             0.441    0.004  125.096    0.000    0.441    0.445
      CON =~                                                                
        CSN_I             0.687    0.004  168.047    0.000    0.687    0.583
        CSN_II            0.797    0.005  167.636    0.000    0.797    0.582
        CSN_III           0.358    0.004   94.671    0.000    0.358    0.343
        CSN_IV            0.808    0.004  190.284    0.000    0.808    0.655
        CSN_V             0.782    0.004  177.832    0.000    0.782    0.615

    Covariances:
                       Estimate  Std.Err  z-value  P(>|z|)   Std.lv  Std.all
      EXTRA ~~                                                              
        AGREE             0.388    0.004  108.706    0.000    0.388    0.388
        EMO               0.247    0.004   66.694    0.000    0.247    0.247
        OPEN              0.134    0.004   33.270    0.000    0.134    0.134
        CON               0.140    0.004   34.647    0.000    0.140    0.140
      AGREE ~~                                                              
        EMO              -0.072    0.004  -17.563    0.000   -0.072   -0.072
        OPEN              0.189    0.004   44.841    0.000    0.189    0.189
        CON               0.120    0.004   28.003    0.000    0.120    0.120
      EMO ~~                                                                
        OPEN              0.178    0.004   43.620    0.000    0.178    0.178
        CON               0.241    0.004   60.043    0.000    0.241    0.241
      OPEN ~~                                                               
        CON               0.071    0.004   16.110    0.000    0.071    0.071

    Variances:
                       Estimate  Std.Err  z-value  P(>|z|)   Std.lv  Std.all
       .EXT_I             0.897    0.005  189.010    0.000    0.897    0.561
       .EXT_II            0.892    0.005  183.014    0.000    0.892    0.522
       .EXT_III           0.751    0.004  180.594    0.000    0.751    0.508
       .EXT_IV            0.719    0.004  177.781    0.000    0.719    0.493
       .EXT_V             0.725    0.004  167.795    0.000    0.725    0.444
       .AGR_I             1.323    0.007  198.755    0.000    1.323    0.749
       .AGR_II            0.835    0.005  182.157    0.000    0.835    0.645
       .AGR_III           1.428    0.007  214.249    0.000    1.428    0.887
       .AGR_IV            0.650    0.004  150.839    0.000    0.650    0.512
       .AGR_V             0.705    0.005  154.735    0.000    0.705    0.526
       .EST_I             0.570    0.005  104.019    0.000    0.570    0.330
       .EST_II            0.982    0.005  191.825    0.000    0.982    0.653
       .EST_III           0.657    0.004  163.529    0.000    0.657    0.517
       .EST_IV            1.373    0.006  215.662    0.000    1.373    0.877
       .EST_V             1.256    0.006  209.221    0.000    1.256    0.800
       .OPN_I             1.059    0.005  199.927    0.000    1.059    0.788
       .OPN_II            0.572    0.005  123.242    0.000    0.572    0.475
       .OPN_III           1.003    0.005  206.019    0.000    1.003    0.832
       .OPN_IV            0.663    0.004  153.580    0.000    0.663    0.574
       .OPN_V             0.788    0.004  201.943    0.000    0.788    0.802
       .CSN_I             0.914    0.005  177.508    0.000    0.914    0.660
       .CSN_II            1.240    0.007  177.830    0.000    1.240    0.661
       .CSN_III           0.960    0.005  211.978    0.000    0.960    0.882
       .CSN_IV            0.869    0.006  156.051    0.000    0.869    0.571
       .CSN_V             1.007    0.006  169.093    0.000    1.007    0.622
        EXTRA             1.000                               1.000    1.000
        AGREE             1.000                               1.000    1.000
        EMO               1.000                               1.000    1.000
        OPEN              1.000                               1.000    1.000
        CON               1.000                               1.000    1.000

</details>

<br>

    ## plot the CFA model on original data
    lavaanPlot(model = original_CFA, node_options = list(shape = "box", fontname = "Helvetica"), edge_options = list(color = "grey"), coefs = TRUE, graph_options = list(layout = "circo"))

<div id="htmlwidget-d50d83d6b7e3cdabd011" style="width:672px;height:480px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-d50d83d6b7e3cdabd011">{"x":{"diagram":" digraph plot { \n graph [ layout = circo ] \n node [ shape = box, fontname = Helvetica ] \n node [shape = box] \n EXT_I; EXT_II; EXT_III; EXT_IV; EXT_V; AGR_I; AGR_II; AGR_III; AGR_IV; AGR_V; EST_I; EST_II; EST_III; EST_IV; EST_V; OPN_I; OPN_II; OPN_III; OPN_IV; OPN_V; CSN_I; CSN_II; CSN_III; CSN_IV; CSN_V \n node [shape = oval] \n EXTRA; AGREE; EMO; OPEN; CON \n \n edge [ color = grey ] \n  EXTRA->EXT_I [label = \"0.84\"] EXTRA->EXT_II [label = \"0.9\"] EXTRA->EXT_III [label = \"0.85\"] EXTRA->EXT_IV [label = \"0.86\"] EXTRA->EXT_V [label = \"0.95\"] AGREE->AGR_I [label = \"0.67\"] AGREE->AGR_II [label = \"0.68\"] AGREE->AGR_III [label = \"0.43\"] AGREE->AGR_IV [label = \"0.79\"] AGREE->AGR_V [label = \"0.8\"] EMO->EST_I [label = \"1.08\"] EMO->EST_II [label = \"0.72\"] EMO->EST_III [label = \"0.78\"] EMO->EST_IV [label = \"0.44\"] EMO->EST_V [label = \"0.56\"] OPEN->OPN_I [label = \"0.53\"] OPEN->OPN_II [label = \"0.8\"] OPEN->OPN_III [label = \"0.45\"] OPEN->OPN_IV [label = \"0.7\"] OPEN->OPN_V [label = \"0.44\"] CON->CSN_I [label = \"0.69\"] CON->CSN_II [label = \"0.8\"] CON->CSN_III [label = \"0.36\"] CON->CSN_IV [label = \"0.81\"] CON->CSN_V [label = \"0.78\"] \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script>
<hr>

As seen above in the plots as well as in the table below, it is observed
that the resulting estimates from the factor analysis on the synthetic
data closely coincide with those from the analysis on the original data.

<table class="table table-striped table-hover table-condensed" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
Formula
</th>
<th style="text-align:center;">
Synthetic\_estimate
</th>
<th style="text-align:center;">
Original\_estimate
</th>
<th style="text-align:center;">
Synthetic\_se
</th>
<th style="text-align:center;">
Original\_se
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
EXTRA =~ EXT\_IV
</td>
<td style="text-align:center;">
0.858
</td>
<td style="text-align:center;">
0.860
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
<tr>
<td style="text-align:left;">
EXTRA =~ EXT\_V
</td>
<td style="text-align:center;">
0.959
</td>
<td style="text-align:center;">
0.953
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
<tr>
<td style="text-align:left;">
AGREE =~ AGR\_IV
</td>
<td style="text-align:center;">
0.788
</td>
<td style="text-align:center;">
0.787
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
<tr>
<td style="text-align:left;">
AGREE =~ AGR\_V
</td>
<td style="text-align:center;">
0.796
</td>
<td style="text-align:center;">
0.797
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
<tr>
<td style="text-align:left;">
EMO =~ EST\_IV
</td>
<td style="text-align:center;">
0.438
</td>
<td style="text-align:center;">
0.439
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
<tr>
<td style="text-align:left;">
EMO =~ EST\_V
</td>
<td style="text-align:center;">
0.557
</td>
<td style="text-align:center;">
0.561
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
<tr>
<td style="text-align:left;">
OPEN =~ OPN\_IV
</td>
<td style="text-align:center;">
0.708
</td>
<td style="text-align:center;">
0.702
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
<tr>
<td style="text-align:left;">
OPEN =~ OPN\_V
</td>
<td style="text-align:center;">
0.440
</td>
<td style="text-align:center;">
0.441
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
<tr>
<td style="text-align:left;">
CON =~ CSN\_IV
</td>
<td style="text-align:center;">
0.808
</td>
<td style="text-align:center;">
0.808
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
<tr>
<td style="text-align:left;">
CON =~ CSN\_V
</td>
<td style="text-align:center;">
0.789
</td>
<td style="text-align:center;">
0.782
</td>
<td style="text-align:center;">
0.004
</td>
<td style="text-align:center;">
0.004
</td>
</tr>
</tbody>
</table>
