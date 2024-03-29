% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/baseline_correction.R
\name{rm_baseline}
\alias{rm_baseline}
\alias{rm_baseline.eeg_data}
\alias{rm_baseline.eeg_epochs}
\alias{rm_baseline.data.frame}
\alias{rm_baseline.eeg_tfr}
\alias{rm_baseline.eeg_evoked}
\title{Baseline correction}
\usage{
rm_baseline(data, time_lim = NULL, ...)

\method{rm_baseline}{eeg_data}(data, time_lim = NULL, verbose = TRUE, ...)

\method{rm_baseline}{eeg_epochs}(data, time_lim = NULL, verbose = TRUE, ...)

\method{rm_baseline}{data.frame}(data, time_lim = NULL, verbose = TRUE, ...)

\method{rm_baseline}{eeg_tfr}(data, time_lim = NULL, type = "divide", verbose = TRUE, ...)

\method{rm_baseline}{eeg_evoked}(data, time_lim = NULL, verbose = TRUE, ...)
}
\arguments{
\item{data}{Data to be baseline corrected.}

\item{time_lim}{Numeric character vector (e.g. time_lim <- c(-.1, 0))
defining the time period to use as a baseline. If the value is NULL, it
uses the mean of the whole of each epoch if the data is epoched, or the
channel mean if the data is continuous.}

\item{...}{other parameters to be passed to functions}

\item{verbose}{Defaults to TRUE. Output descriptive messages to console.}

\item{type}{Type of baseline correction to apply. Options are ("divide",
"ratio", "absolute", "db", and "pc")}
}
\value{
An \code{eegUtils} object or a \code{data.frame}, depending on the input.
}
\description{
Used to correct data using the mean of a specified time period. For
time-domain data, this will subtract the mean from all data. For \code{eeg_tfr}
objects, a variety of methods are available, including subtraction, and
conversion to "dB" change. With a data frame, it will search for "electrode"
and "epoch" columns, and groups on these when found. An electrode column is
always required; an epoch column is not. Note that baseline correction is
always applied on single-trial basis. For baseline correction based on
subtraction, this makes no difference compared to averaging first and then
baseline correcting, but for divisive measures used with time-frequency data,
this distinction can be very important, and can lead to counterintuitive
results.
}
\section{Methods (by class)}{
\itemize{
\item \code{eeg_data}: remove baseline from continuous \code{eeg_data}

\item \code{eeg_epochs}: Remove baseline from \code{eeg_epochs}

\item \code{data.frame}: Legacy method for data.frames

\item \code{eeg_tfr}: Method for \code{eeg_tfr} objects

\item \code{eeg_evoked}: Method for \code{eeg_evoked} objects
}}

\examples{
rm_baseline(demo_epochs)
rm_baseline(demo_epochs, c(-.1, 0))
}
\author{
Matt Craddock \email{matt@mattcraddock.com}
}
