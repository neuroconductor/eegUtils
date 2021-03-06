% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tfr_analysis.R
\name{compute_itc}
\alias{compute_itc}
\title{Calculate inter-trial coherence}
\usage{
compute_itc(data)
}
\arguments{
\item{data}{An \code{eeg_tfr} object}
}
\value{
An \code{eeg_tfr} object
}
\description{
Calculates inter-trial coherence (ITC), a measure of phase consistency across
single trial data. Input data must be provided as complex Fourier
coefficients within an \code{eeg_tfr} object
}
