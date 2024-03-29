% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/check_items.R
\name{label_check}
\alias{label_check}
\title{Check consistency of labels}
\usage{
label_check(cond_labs, data_labs)
}
\arguments{
\item{cond_labs}{labels submitted by the user}

\item{data_labs}{labels from the actual data}
}
\description{
Internal function for checking 1) whether the labels submitted are a mixture
of hierarchical and non-hierarchical types 2) whether the labels submitted
are present in the data
}
\author{
Matt Craddock \email{matt@mattcraddock.com}
}
\keyword{internal}
