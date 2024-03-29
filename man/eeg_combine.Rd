% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_combine.R
\name{eeg_combine}
\alias{eeg_combine}
\alias{eeg_combine.list}
\alias{eeg_combine.eeg_data}
\alias{eeg_combine.eeg_epochs}
\alias{eeg_combine.eeg_evoked}
\title{Combine \code{eegUtils} objects}
\usage{
eeg_combine(data, ...)

\method{eeg_combine}{list}(data, ...)

\method{eeg_combine}{eeg_data}(data, ..., check_timings = TRUE)

\method{eeg_combine}{eeg_epochs}(data, ..., check_timings = TRUE)

\method{eeg_combine}{eeg_evoked}(data, ...)
}
\arguments{
\item{data}{An \code{eeg_data}, \code{eeg_epochs}, or \code{eeg_evoked} object, or a list of
such objects.}

\item{...}{additional \code{eeg_data} or \code{eeg_epochs} objects}

\item{check_timings}{Check whether sample times / epoch numbers are
continuously ascending; if not, modify so that they are. Useful when, for
example, combining epochs derived from multiple recording blocks. Defaults to TRUE}
}
\value{
If all objects have the same \code{participant_id}, returns an object of
the same class as the original input object. If the objects have different
\code{participant_id} numbers, an object of both class \code{eeg_group} and the same
class as the original input object.
}
\description{
Combine multiple \code{eeg_epochs}, \code{eeg_data}, or \code{eeg_evoked} objects into a
single object. The function will try to check the \code{participant_id} entry in
the \code{epochs} structure to see if the data comes from a single participant or
from multiple participants. If the data is from a single participant, it will
concatenate the objects and attempt to correct them so that the trial numbers
and timings are correct.
}
\section{Methods (by class)}{
\itemize{
\item \code{list}: Method for combining lists of \code{eeg_data} and
\code{eeg_epochs} objects.

\item \code{eeg_data}: Method for combining \code{eeg_data} objects.

\item \code{eeg_epochs}: Method for combining \code{eeg_epochs} objects

\item \code{eeg_evoked}: Method for combining \code{eeg_evoked} objects
}}

\author{
Matt Craddock, \email{matt@mattcraddock.com}
}
