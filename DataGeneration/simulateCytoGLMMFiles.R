# clone functions git
if(!file.exists("cyanus_functions")){
  system("git clone git@github.com:biomedbigdata/cyanus_functions.git")
}

library(CATALYST)
source("cyanus_functions/functions/cytoGLMM_functions.R")
source("cyanus_functions/functions/prep_functions.R")
source("cyanus_functions/functions/cluster_functions.R")

data_dir <- "out"
n <- 200000
set.seed(1234)
sce <- simulateSCE(
  n_samples = 22,
  n_cells = n,
  n_markers = 20,
  n_true = 5
)
sce <- addClusterAll(sce)

filename <-
  file.path(data_dir, sprintf("simulated_cytoGLMM_%d_cells.rds", n))
if (!file.exists(filename)){
  if(!file.exists(data_dir)){
    dir.create(data_dir)
  }
  saveRDS(sce, filename)
}

last_sce <- sce
for (n in rev(c(1000, 2000, 5000, 10000, 15000, 20000))) {
  sce_down <- downSampleSCE(last_sce, n)
  filename <-
    file.path(data_dir, sprintf("simulated_cytoGLMM_%d_cells.rds", n))
  saveRDS(sce_down, filename)
  last_sce <- sce_down
}
