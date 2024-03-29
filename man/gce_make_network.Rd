% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/networks.R
\name{gce_make_network}
\alias{gce_make_network}
\title{Make a network interface for instance creation}
\usage{
gce_make_network(
  network = "default",
  name = NULL,
  subnetwork = NULL,
  externalIP = NULL,
  project = gce_get_global_project()
)
}
\arguments{
\item{network}{Name of network resource}

\item{name}{Name of the access config}

\item{subnetwork}{A subnetwork name if its exists

You need to provide accessConfig explicitly if you want an ephemeral IP assigned, see \code{https://cloud.google.com/compute/docs/vm-ip-addresses}}

\item{externalIP}{An external IP you have created previously, leave NULL to have one assigned or "none" for none}

\item{project}{Project ID for this request}
}
\value{
A Network object
}
\description{
Make a network interface for instance creation
}
