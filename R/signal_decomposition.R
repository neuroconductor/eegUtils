#' Generalized eigenvalue decomposition based methods for EEG data
#'
#' Implements a selection of Generalized Eigenvalue based decomposition methods
#' for EEG signals. Intended for isolating oscillations at specified
#' frequencies, decomposing channel-based data into components
#' reflecting distinct or combinations of sources of oscillatory signals.
#' Currently, spatio-spectral decomposition (Nikulin, Nolte, & Curio, 2011) and
#' Rhythmic Entrainment Source Separation (Cohen & Gulbinate, 2017) are
#' implemented. The key difference between the two is that the former returns
#' the results of the data-derived spatial filters applied to the
#' bandpass-filtered "signal" data, whereas the latter returns the results of the
#' filters applied to the original, broadband data.
#'
#' @param data An `eeg_data` object
#' @param ... Additional parameters
#' @author Matt Craddock \email{matt@@mattcraddock.com}
#' @return An `eeg_ICA` object. Note that
#' @examples
#' # The default method is Spatio-Spectral Decomposition, which returns
#' # spatially and temporally filtered source timecourses.
#'  decomposed <-
#'    eeg_decompose(demo_epochs,
#'                  sig_range = c(9, 11),
#'                  noise_range = c(8, 12),
#'                  method = "ssd")
#'  plot_psd(decomposed)
#'  # We can plot the spatial filters using `topoplot()`
#'  topoplot(decomposed, 1:2)
#'  plot_timecourse(decomposed, 1)
#' # method = "ress" returns spatially but not temporally filtered timecourses.
#'  with_RESS <-
#'    eeg_decompose(demo_epochs,
#'                  sig_range = c(9, 11),
#'                  noise_range = c(8, 12),
#'                  method = "ress")
#'  plot_psd(with_RESS)
#'  # The topographical plots are identical to those using "ssd", as the
#'  # spatial filters are the same.
#'  topoplot(with_RESS, 1:2)
#'  plot_timecourse(with_RESS, 1)
#' @family decompositions
#' @export
#' @references Cohen, M. X., & Gulbinate, R. (2017). Rhythmic entrainment source
#'   separation: Optimizing analyses of neural responses to rhythmic sensory
#'   stimulation. NeuroImage, 147, 43-56.
#'   https://doi.org/10.1016/j.neuroimage.2016.11.036
#'
#'   Haufe, S., Dähne, S., & Nikulin, V. V. (2014). Dimensionality reduction for
#'   the analysis of brain oscillations. NeuroImage, 101, 583–597.
#'   https://doi.org/10.1016/j.neuroimage.2014.06.073
#'
#'   Nikulin, V. V., Nolte, G., & Curio, G. (2011). A novel method for reliable
#'   and fast extraction of neuronal EEG/MEG oscillations on the basis of
#'   spatio-spectral decomposition. NeuroImage, 55(4), 1528–1535.
#'   https://doi.org/10.1016/j.neuroimage.2011.01.057

eeg_decompose <- function(data, ...) {
  UseMethod("eeg_decompose", data)
}

#' @export
eeg_decompose.default <- function(data, ...) {
  stop("Not implemented for objects of class ", class(data))
}

#' @param sig_range Vector with two inputs, the lower and upper bounds of the frequency range of interest
#' @param noise_range Range of frequencies to be considered noise (e.g. bounds of flanker frequencies)
#' @param method Type of decomposition to apply. Currently only "ssd" is supported.
#' @param verbose Informative messages printed to console. Defaults to TRUE.
#' @param order Filter order for filter applied to signal/noise
#' @describeIn eeg_decompose method for `eeg_epochs` objects
#' @export
eeg_decompose.eeg_epochs <- function(data,
                                  sig_range,
                                  noise_range,
                                  method = "ssd",
                                  verbose = TRUE,
                                  order = 2,
                                  ...) {

  if (verbose) {
    message("Performing ", method, "...")
  }

  data <- switch(method,
                 "ssd" = run_SSD(data,
                                 sig_range,
                                 noise_range,
                                 verbose = verbose,
                                 order = order),
                 "ress" = run_SSD(data,
                                  sig_range,
                                  noise_range,
                                  RESS = TRUE,
                                  verbose = verbose,
                                  order = order))
  class(data) <- c("eeg_ICA", "eeg_epochs")
  data
}

#' Internal function for running SSD algorithm
#'
#' @param data `eeg_epochs` object to be decomposed
#' @param sig_range Frequency range of the signal of interest
#' @param noise_range Frequency range of the noise
#' @param RESS Run RESS rather than SSD. Defaults to FALSE.
#' @param verbose Informative messages in consoles. Defaults to TRUE.
#' @param order filter order for IIR filters
#' @keywords internal

run_SSD <- function(data,
                    sig_range,
                    noise_range,
                    RESS = FALSE,
                    verbose = TRUE,
                    order = 2) {

  if (!requireNamespace("geigen",
                        quietly = TRUE)) {
    stop("Package \"geigen\" needed for SSD. Please install it.",
         call. = FALSE)
  }

  # modify to allow gaussian filter?
  signal <- eeg_filter(data,
                       low_freq = sig_range[1],
                       high_freq = sig_range[2],
                       filter_order = order,
                       method = "iir")

  noise <- eeg_filter(data,
                      low_freq = noise_range[1],
                      high_freq = noise_range[2],
                      filter_order = order,
                      method = "iir")

  noise <- eeg_filter(noise,
                      low_freq = (sig_range[2] + noise_range[2]) / 2,
                      high_freq = (sig_range[1] + noise_range[1]) / 2,
                      filter_order = order,
                      method = "iir")

  # Calculate covariance respecting the epoching structure of the data
  cov_sig <- cov_epochs(signal)
  cov_noise <- cov_epochs(noise)



  eig_sigs <- base::eigen(cov_sig)
  # Get the rank of the covariance matrix and select only as many components as
  # there are ranks
  rank_sig <- Matrix::rankMatrix(cov_sig)

  if (verbose) {
    if (rank_sig < ncol(cov_sig)) {
      message("Input data is not full rank; returning ",
              rank_sig,
              "components")
      M <- eig_sigs$vectors[, 1:rank_sig] %*% (diag(eig_sigs$values[1:rank_sig] ^ -0.5))
    } else {
      M <- diag(ncol(cov_sig))
    }
  }

  C_s_r <- crossprod(M, cov_sig) %*% M
  C_n_r <- crossprod(M, cov_noise) %*% M
  # this is the generalized eigenvalue decomp with sig vs
  # sig+noise, Cohen uses avg of flanking freqs?
  ged_v <- geigen::geigen(C_s_r, C_s_r + C_n_r) # this one needs to be sorted
  lambda <- sort(ged_v$values, decreasing = TRUE) # return lambda?

  W <- ged_v$vectors[, order(ged_v$values, decreasing = TRUE)]
  W <- M %*% W

  # Alternatively could just invert W?
  data$mixing_matrix <- (cov_sig %*% W) %*% solve(crossprod(W, cov_sig) %*% W)

  # sort by variance explained
  vaf_idx <-
    sort(vaf_mix(data$mixing_matrix),
         decreasing = TRUE,
         index.return = TRUE)$ix

  data$mixing_matrix <- data$mixing_matrix[, vaf_idx]
  data$unmixing_matrix <- as.data.frame(MASS::ginv(data$mixing_matrix, tol = 0))

  data$mixing_matrix <- as.data.frame(data$mixing_matrix)
  names(data$mixing_matrix) <- sprintf("Comp%03d", 1:ncol(data$mixing_matrix))
  data$mixing_matrix$electrode <- names(data$signals)

  names(data$unmixing_matrix) <- data$mixing_matrix$electrode
  data$unmixing_matrix$Component <- sprintf("Comp%03d", 1:ncol(W))

  # RESS applies weights to unfiltered original data
  if (RESS) {
    data$signals <- as.data.frame(as.matrix(data$signals) %*% W)
    names(data$signals) <- sprintf("Comp%03d", 1:ncol(W))
    return(data)
  }

  data$signals <- as.data.frame(as.matrix(signal$signals) %*% W)
  names(data$signals) <- sprintf("Comp%03d", 1:ncol(W))
  data

}

#' Covariance of epoched data
#'
#' Calculate covariance of each epoch, then average
#'
#' @param data epoched data to calculate covariance for
#' @keywords internal

cov_epochs <- function(data) {

  if (!is.eeg_epochs(data)) {
    stop("This is not an eeg_objects object.")
  }
  # Data is converted to a 3D matrix (n_times X n_epochs X n_channels),
  # covariance is calculated for each epoch then averaged over
  full_cov <- rowMeans(apply(conv_to_mat(data),
                             2,
                             stats::cov))
  dim(full_cov) <- c(ncol(data$signals),
                     ncol(data$signals))
  as.matrix(full_cov)
}
