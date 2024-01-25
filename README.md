# Cyanus-Paper-Code
Code associated with the paper "A systematic comparison of novel and existing differential analysis methods for CyTOF data", more specifically, the data generation and the DE methods comparison.

Code for the Shiny App can be found at [biomedbigdata/cyanus](https://github.com/biomedbigdata/cyanus).

## Table of Contents
* [Dataset Simulation](#dataset-simulation)
* [Methods Evaluation](#methods-evaluation)

## Dataset Simulation
The PBMC dataset, the simulated CytoGLMM dataset (and its downsampled versions) and the semi-simulated COVID-19 dataset (and its downsampled versions) can be reproduced using the scripts in DataGeneration. The dual antiplatelet therapy dataset is available upon request from Melissa.Klug@tum.de.


## Methods Evaluation
The evaluation of the methods on the different datasets can be found in the DEComparison directory. Each dataset has a subdirectory containing the benchmarking scripts for running the methods, the resulting .rds objects and an evaluation.R script. Using the evaluation scripts, the plots from the paper can be reproduced.
