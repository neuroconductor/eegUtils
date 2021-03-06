% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/channel_management.R
\name{stereo_norm}
\alias{stereo_norm}
\title{Stereographic electrode projection}
\usage{
stereo_norm(chan_info)
}
\arguments{
\item{chan_info}{Channel information from an eegUtils objects}
}
\value{
A data.frame with x and y columns indictating electrode positions in
degrees
}
\description{
Produce a set of x and y coordinates for plotting from 3D Cartesian
coordinates. This is a stereographic projection of the 3D coordinates, which
compensates for the distance of the electrode from the projecting point and
flattens out the scalp.
}
\keyword{internal}
