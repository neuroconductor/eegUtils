% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/run_ICA.R
\name{run_ICA}
\alias{run_ICA}
\alias{run_ICA.eeg_epochs}
\title{Independent Component Analysis for EEG data}
\usage{
run_ICA(data, ...)

\method{run_ICA}{eeg_epochs}(
  data,
  method = "sobi",
  maxit = 1000,
  tol = 1e-06,
  pca = NULL,
  centre = TRUE,
  alg = "gradient",
  rateanneal = c(60, 0.9),
  rate = 0.1,
  verbose = TRUE,
  ...
)
}
\arguments{
\item{data}{Data to be ICAed.}

\item{...}{Other parameters passed to function.}

\item{method}{"sobi" (default), "fastica", "infomax", or "imax". "infomax"
uses the implementation from the \code{ica} package, whereas \code{imax} uses the
implementation from the \code{infomax} package, which is based on the \code{EEGLAB}
implementation.}

\item{maxit}{Maximum number of iterations of the Infomax and Fastica ICA
algorithms.}

\item{tol}{Convergence tolerance for fastica and infomax. Defaults to 1e-06.}

\item{pca}{Reduce the number of dimensions using PCA before running ICA.
Numeric,  >1 and < number of channels}

\item{centre}{Defaults to TRUE. Centre the data on zero by subtracting the
column mean. See notes on usage.}

\item{alg}{Use "gradient descent" or "newton" algorithm for extended infomax.
Defaults to "gradient". Ignored if method != "infomax".}

\item{rateanneal}{Annealing rate for extended infomax. Ignored if method !=
"infomax".}

\item{rate}{Learning rate for extended infomax. Ignored if method !=
"infomax".}

\item{verbose}{Print informative messages to console.}
}
\value{
An \code{eeg_ICA} object containing an ICA decomposition
}
\description{
Performs Independent Component Analysis for electroencephalographic data.
Currently only available with on epoched data. Implements three different
methods of ICA - 'fastica', 'extended Infomax', and 'Second-Order Blind
Identification (SOBI)'. The resulting \code{eeg_ICA} objects can be used largely
like \code{eeg_epochs} objects.
}
\section{Methods (by class)}{
\itemize{
\item \code{eeg_epochs}: Run ICA on an \code{eeg_epochs} object
}}

\section{Notes on ICA usage}{


It is recommended to mean-centre your data appropriately before running
ICA. The implementations of FASTICA and extended-Infomax from the \code{ica}
package, and of SOBI ICA have this as an option which is enabled by
default, while the implementation of FASTICA in the fICA package enforces
mean-centring of the columns of the data. With epoched data, it is
recommended to centre each epoch on zero, rather than centre on the overall
channel mean. This can be achieved with the \code{rm_baseline()} function. SOBI
ICA will do this automatically, whereas the other ICA implementations will
centre on the channel means, not the epoch means.

In addition, PCA will be required if the data is not full rank. This is
typical when using average reference, when the data rank will be
n_electrodes - 1.
}

\examples{
sobi_demo <-
  run_ICA(demo_epochs,
          pca = 10)
 sobi_demo
 # We can plot the resulting spatial filters using `topoplot()`
 topoplot(sobi_demo, 1:2)
 \dontrun{ view_ica(sobi_demo) }
}
\seealso{
Other decompositions: 
\code{\link{eeg_decompose}()}
}
\author{
Matt Craddock \email{matt@mattcraddock.com}
}
\concept{decompositions}
