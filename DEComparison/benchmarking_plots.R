library(data.table)
library(ggplot2)

preparePlotData <- function(data_type = c("simulatedCytoGLMM", "downsampled_covid_spike", "dual_platelets")){
  data_type <- match.arg(data_type)
  if (data_type == "simulatedCytoGLMM"){
    path <-  "DEComparison/simulatedCytoGLMM"
    trues <- c("m01", "m02", "m03", "m04", "m05")
    keep <- 3
  } else if (data_type == "downsampled_covid_spike"){
    path <-  "DEComparison/downsampled_covid_spike"
    trues <- c("CD62P", "CD63", "CD107a", "CD154")
    keep <- 6
  } else if (data_type == "dual_platelets"){
    path <-  "DEComparison/dual_platelets"
    trues <- c("CD62P", "CD63", "CD107a", "CD154")
  }
  
  result_rds <-
    list.files(path = path,
               pattern = "\\.rds$",
               full.names = T)
  results <-
    data.table::rbindlist(sapply(result_rds, function(rds)
      readRDS(rds)[["results"]], simplify = FALSE),
      idcol = "dataset")
  results <- results[, .SD, .SDcols = unique(names(results))]
  results[, dataset := basename(dataset)]
  times <-
    data.table::rbindlist(sapply(result_rds, function(rds)
      readRDS(rds)[["times"]], simplify = FALSE),
      idcol = "dataset")
  times[, dataset := basename(dataset)]
  
  
  if (data_type!="dual_platelets"){
    # because dual has no subsampling
    times[, nr_of_cells := tstrsplit(dataset, "_", keep = keep)]
    times[, nr_of_cells := as.numeric(nr_of_cells)]
    results[, nr_of_cells := tstrsplit(dataset, "_", keep = keep)]
    if (data_type == "downsampled_covid_spike"){
      sce_covid_spike <- readRDS("DataGeneration/covid/sce_spiked_clustered_full_ds_full.rds")
      nr_cells_full <- sum(ei(sce_covid_spike)$n_cells)
      results$nr_of_cells[results$nr_of_cells == "full"] <- nr_cells_full
    }
    results[, nr_of_cells := as.numeric(nr_of_cells)]
    
    if (data_type=="downsampled_covid_spike"){
      times[, alpha := tstrsplit(dataset, "_", keep = 4)]
      times[, alpha := factor(alpha, levels = c("full", "25", "50", "75", "100"))]
      results[, alpha := tstrsplit(dataset, "_", keep = 4)]
      results[, alpha := factor(alpha, levels = c("full", "25", "50", "75", "100"))]
      
      
      
      stats_table <- results[, .(
        TP = sum(p_adj <= 0.05 &
                   marker_id %in% trues
                 & alpha != 100,na.rm = T),
        FP = sum((p_adj <= 0.05 | is.na(p_adj)) &
                   !(marker_id %in% trues)),
        TN = sum(p_adj > 0.05 &
                   !(marker_id %in% trues), na.rm = T),
        FN = sum((p_adj > 0.05 | is.na(p_adj)) &
                   marker_id %in% trues
                 & alpha != 100)
      ), by = .(method, nr_of_cells, alpha)]
      
    } else if (data_type=="simulatedCytoGLMM") {
      
      stats_table <- results[, .(
        TP = sum(
          p_adj <= 0.05 &
            marker_id %in% trues
          ,
          na.rm = T
        ),
        FP = sum((p_adj <= 0.05 | is.na(p_adj)) &
                   !(
                     marker_id %in% trues
                   )),
        TN = sum(p_adj > 0.05 &
                   !(
                     marker_id %in% trues
                   ), na.rm = T),
        FN = sum(
          (p_adj > 0.05 | is.na(p_adj)) &
            marker_id %in% trues
        )
      ), by = .(method, nr_of_cells)] # , alpha)]
      
      
    }
  } else if (data_type=="dual_platelets") {
    stats_table <- results[, .(
      TP = sum(
        p_adj <= 0.05 &
          marker_id %in% trues
        ,
        na.rm = T
      ),
      FP = sum((p_adj <= 0.05 | is.na(p_adj)) &
                 !(
                   marker_id %in% trues
                 )),
      TN = sum(p_adj > 0.05 &
                 !(
                   marker_id %in% trues
                 ), na.rm = T),
      FN = sum(
        (p_adj > 0.05 | is.na(p_adj)) &
          marker_id %in% trues
      )
    ), by = .(method)]
  } else stop('unknown data_type')
  
  
  stats_table[, sensitivity := TP / (TP + FN)]
  stats_table[, specificity := TN / (TN + FP)]
  stats_table[, precision := TP / (TP + FP)]
  stats_table[, F1 := 2 * (sensitivity * precision) / (sensitivity + precision)]
  
  if (data_type!="dual_platelets") {
    times$nr_of_cells <- as.numeric(times$nr_of_cells)
    stats_table$nr_of_cells <- as.numeric(stats_table$nr_of_cells)
    
    if (data_type=="simulatedCytoGLMM")
    stats_table <-
      merge(stats_table, times[, .(method, nr_of_cells, elapsed)])
    else if (data_type=="downsampled_covid_spike")
    stats_table <-
      merge(stats_table, times[, .(method, nr_of_cells, elapsed, alpha)])
  } else if (data_type=="dual_platelets") {
    stats_table <-
      merge(stats_table, times[, .(method,elapsed)])
  } else stop('unknown data_type')
  
  return(stats_table)
}

plot_cells_vs_elapsed <- function(stats_table){
  if ("alpha" %in% names(stats_table)){
    plot <- ggplot(stats_table,
                   aes(
                     x = nr_of_cells,
                     y = elapsed,
                     color = method,
                     shape = alpha
                   )) +
      geom_jitter(size = 3) +
      theme_bw() + theme(text = element_text(size = 18), axis.text.x = element_text(angle = 45, hjust = 1))
  } else {
    plot <- ggplot(stats_table,
         aes(
           x = nr_of_cells,
           y = elapsed,
           color = method
         )) +
    geom_jitter(size = 3) +
    theme_bw() + theme(text = element_text(size = 18), axis.text.x = element_text(angle = 45, hjust = 1))
  }
  return(plot)
}

plot_sens_vs_spec <- function(stats_table){
  plot <- ggplot(stats_table,
                 aes(
                   x = 1 - specificity,
                   y = sensitivity,
                   color = method,
                   shape = method
                 )) +
    scale_shape_manual(values=1:stats_table[, uniqueN(method)]) +
    geom_point(size = 5, alpha = .6) +
    ylim(c(0.0, 1.0)) +
    xlim(c(0.0, 1.0)) +
    theme_bw() +
    theme(text = element_text(size = 18), axis.text.x = element_text(angle = 45, hjust = 1))
  if ("nr_of_cells" %in% colnames(stats_table)){
    if ("alpha" %in% colnames(stats_table))
      plot <- plot + facet_grid(nr_of_cells~alpha)
    else
      plot <- plot + facet_wrap(~nr_of_cells)
  }
  return(plot)
}

plot_sens_vs_pre <- function(stats_table){
    plot <- ggplot(stats_table,
                   aes(
                     x = sensitivity,
                     y = precision,
                     color = method,
                     shape = method
                   )) +
      scale_shape_manual(values=1:stats_table[, data.table::uniqueN(method)]) +
      geom_point(size = 5, alpha = .6) +
      ylim(c(0.0, 1.0)) +
      xlim(c(0.0, 1.0)) +
      theme_bw() +
      theme(text = element_text(size = 18), axis.text.x = element_text(angle = 45, hjust = 1))
    
    if ("nr_of_cells" %in% colnames(stats_table)){
      if ("alpha" %in% colnames(stats_table)){
        plot <- plot +facet_grid(nr_of_cells ~ alpha)
      } else {
        plot <- plot +facet_wrap(~nr_of_cells)
      }
    }
  return(plot)
}

plot_f1_vs_elapsed <- function(stats_table){
  if ("nr_of_cells" %in% names(stats_table)){
    plot <- ggplot(stats_table, aes(
      x = F1,
      y = elapsed,
      color = as.factor(nr_of_cells),
      shape = as.factor(nr_of_cells)
    )) + facet_wrap(~ method) +
      geom_point(size = 5, alpha = .6) +
      xlim(c(0, 1)) +
      theme_bw() + theme(text = element_text(size = 18), axis.text.x = element_text(angle = 45, hjust = 1))
  } else {
    plot <- ggplot(stats_table, aes(
      x = F1,
      y = elapsed,
      color = as.factor(method),
    )) +
      geom_point(size = 5, alpha = .6) +
      xlim(c(0, 1)) +
      theme_bw() + theme(text = element_text(size = 18), axis.text.x = element_text(angle = 45, hjust = 1))
  }
 
 return(plot)
}
