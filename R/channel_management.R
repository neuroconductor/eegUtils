#' Import channel locations from various file formats
#'
#' Currently only ASA `.elc` format with Cartesian x-y-z coordinates is
#' supported.
#'
#' @author Matt Craddock \email{matt@@mattcraddock.com}
#' @param file_name Name and full path of file to be loaded.
#' @param format If the file is not `.elc` format, "spherical", "geographic".
#'   Default is "spherical".
#' @param file_format Default is `auto`, which will use the file extension to
#'   determine file format. Other options include `ced`, `besa`, `elp`, `elc`
#' @return A `tibble` containing electrode names and locations in several
#'   different coordinate systems.
#' @export

import_chans <- function(file_name,
                         format = "spherical",
                         file_format = "auto") {

  if (identical(file_format, "auto")) {
    file_type <- tools::file_ext(file_name)
  } else {
    file_type <-
      switch(file_format,
             ced = "ced",
             besa = "elp",
             file_format)
  }


  chan_locs <-
    switch(file_type,
           elc = import_elc(file_name),
           txt = switch(format,
                        spherical = import_txt(file_name)),
           elp = import_elp(file_name),
           ced = import_ced(file_name),
           stop("File type ", file_type, " is unknown.")
           )

  chan_locs <- validate_channels(chan_locs)
  chan_locs
}

#' Import ASA '.elc' electrode location files
#'
#' Loads and process ASA electrode locations.
#' ASA electrode locations are given as Cartesian XYZ.
#'
#' @param file_name file name
#' @keywords internal

import_elc <- function(file_name) {
  raw_locs <- readLines(file_name,
                        n = -1)
  n_elecs <- grep("NumberPositions",
                  raw_locs)
  n_elecs <-
    as.numeric(unlist(strsplit(raw_locs[n_elecs], "\t"))[2])
  pos_loc <- grep("^Positions", raw_locs)
  pos <- raw_locs[seq(pos_loc + 1,
                      pos_loc + n_elecs)]
  labs_loc <- grep("Labels", raw_locs)
  labs <- raw_locs[seq(labs_loc + 1,
                       labs_loc + n_elecs)]

  pos <- strsplit(pos, " ")
  pos <- lapply(pos,
                function(x)
                  as.numeric(x[!x == ""]))
  pos <- as.data.frame(do.call("rbind", pos))

  sph_pos <- cart_to_spherical(norm_sphere(pos))

  names(pos) <- c("cart_x",
                  "cart_y",
                  "cart_z")

  final_locs <- data.frame(electrode = labs,
                           sph_pos,
                           round(pos, 2))

  xy <- project_elecs(final_locs,
                      method = "stereographic")
  final_locs <- cbind(final_locs,
                      xy)

  tibble::as_tibble(final_locs)
}

#' Import electrode locations from text
#'
#' Currently only supports locations given in spherical coordinates. Will
#' attempt to check if the file is from EEGLAB
#'
#' @param file_name file name of .txt electrode locations to import.
#' @return A data frame containing standard channel_info
#' @keywords internal
import_txt <- function(file_name) {

  raw_locs <- utils::read.delim(file_name,
                                stringsAsFactors = FALSE)

  if (any(names(raw_locs) %in% expected)) {
    message("Possibly EEGLAB channel info, attempting import...")
    final_locs <- parse_chaninfo(raw_locs)
    return(final_locs)
  }

  elec_labs <- grepl("electrode",
                     names(raw_locs),
                     ignore.case = TRUE)
  theta_col <- grepl("theta",
                     names(raw_locs),
                     ignore.case = TRUE)
  phi_col <- grepl("phi",
                   names(raw_locs),
                   ignore.case = TRUE)
  cart_xyz <- sph_to_cart(raw_locs[, theta_col],
                          raw_locs[, phi_col])
  final_locs <-
    tibble::tibble(
      electrode = as.character(raw_locs[, elec_labs]),
      radius = 1,
      theta = raw_locs[, theta_col],
      phi = raw_locs[, phi_col]
    )
  xy <- project_elecs(final_locs,
                      method = "stereographic")
  final_locs <- cbind(final_locs,
                      cart_xyz,
                      xy)
  tibble::as_tibble(final_locs)
}


#' Import electrode locations from '.elp' file
#'
#' '.elp' files are from BESA.
#'
#' @param file_name file name of '.elp' electrode locations to import.
#' @return A tibble containing channel locations.
#' @keywords internal
import_elp <- function(file_name) {
  raw_locs <- utils::read.delim(
    file_name,
    skip = 1,
    header = FALSE,
    stringsAsFactors = FALSE,
    strip.white = TRUE
  )
  colnames(raw_locs) <- c("chantype",
                          "electrode",
                          "theta",
                          "phi",
                          "circumference")
  elec_labs <- grepl("electrode",
                     names(raw_locs),
                     ignore.case = TRUE)
  theta_col <- grepl("theta",
                     names(raw_locs),
                     ignore.case = TRUE)
  phi_col <- grepl("phi",
                   names(raw_locs),
                   ignore.case = TRUE)
  cart_xyz <- sph_to_cart(raw_locs[, theta_col],
                          raw_locs[, phi_col])
  final_locs <-
    tibble::tibble(
      electrode = as.character(raw_locs[, elec_labs]),
      radius = 1,
      theta = raw_locs[, theta_col],
      phi = raw_locs[, phi_col]
    )
  xy <- project_elecs(final_locs,
                      method = "stereographic")
  final_locs <- cbind(final_locs,
                      cart_xyz,
                      xy)
  tibble::as_tibble(final_locs)
}

import_ced <- function(file_name) {
  raw_locs <- utils::read.delim(file_name,
                                stringsAsFactors = FALSE)
  expected_ced <-
    c("Number", "labels", "theta", "radius",
      "X", "Y", "Z", "sph_theta",
      "sph_phi", "sph_radius", "type")
  raw_locs <- raw_locs[expected_ced]
  names(raw_locs) <- c("number", "electrode",
                       "theta", "radius",
                       "cart_x", "cart_y",
                       "cart_z", "sph_theta",
                       "sph_phi", "sph_radius", "type")
  chan_info <- raw_locs[c("electrode",
                         "cart_x",
                         "cart_y",
                         "cart_z")]
  # in EEGLAB, + y is towards left ear, + x towards nose + z towards vertex
  # we want + y to be towards nose, + x to be towards right ear
  names(chan_info) <- names(chan_info)[c(1, 3, 2, 4)]
  chan_info <- chan_info[, c(1, 3, 2, 4)]
  chan_info$cart_x <- -chan_info$cart_x
  sph_coords <- cart_to_spherical(chan_info[, c("cart_x", "cart_y", "cart_z")])
  xy <- project_elecs(sph_coords)
  chan_info <- dplyr::bind_cols(electrode = as.character(chan_info$electrode),
                                sph_coords,
                                chan_info[, 2:4],
                                xy)
  chan_info

}

#' Convert topographical 2d to cartesian 2d
#'
#' Expects input to be in degrees
#'
#' @param angle Angle
#' @param radius Radius
#' @keywords internal

topo_norm <- function(angle, radius) {
  x <- radius * cos(angle * pi / 180)
  y <- radius * sin(angle * pi / 180)
  data.frame(x, y)
}

#' Rotate channel locations
#'
#' On import, channel locations may be rotated (e.g. Fpz pointing towards ears.)
#' @examples
#'
#' plot_electrodes(demo_epochs)
#' channels(demo_epochs) <- rotate_angle(channels(demo_epochs), 90)
#' plot_electrodes(demo_epochs)
#'
#' @param chan_info channel information structure
#' @param degrees degrees by which to rotate
#' @examples
#' rotate_angle(channels(demo_epochs), 90)
#' @return A `tibble()`
#' @export

rotate_angle <- function(chan_info,
                         degrees) {

  degrees <- degrees * pi / 180
  if ("CZ" %in% chan_info$electrode) {
    cent_x <- chan_info[toupper(chan_info$electrode) == "CZ", ]$x
    cent_y <- chan_info[toupper(chan_info$electrode) == "CZ", ]$y
  } else {
    cent_x <- 0
    cent_y <- 0
  }

  chan_info$x <- chan_info$x - cent_x
  chan_info$y <- chan_info$y - cent_y
  rot_x <- cent_x + cos(degrees) * chan_info$x - sin(degrees) * chan_info$y
  rot_y <- cent_y + sin(degrees) * chan_info$x + cos(degrees) * chan_info$y
  chan_info$x <- rot_x
  chan_info$y <- rot_y
  chan_info
}

#' Flip x-axis coords
#'
#' @param chan_info chan-info structure
#' @keywords internal

flip_x <- function(chan_info) {
  chan_info$cart_x <- chan_info$cart_x * -1
  chan_info$cart_y <- chan_info$cart_y * -1
  chan_info$x <- chan_info$x * -1
  chan_info$angle <- chan_info$angle * -1
  chan_info$sph_theta <- chan_info$sph_theta * -1
  chan_info
}

#' Get standard electrode locations
#'
#' Joins standard electrode locations to EEG data from `eegUtils` internal
#' data.
#'
#' The standard locations are from the 10-05 system derived by Oostenveld &
#' Praamstra (2001). In addition, there are multiple specific montages for
#' BioSemi systems included. These can be added using the montage parameter:
#' "biosemi16", "biosemi32", biosemi64", "biosemi64alpha", "biosemi128",
#' "biosemi160", "biosemi256"
#'
#' @references Oostenveld, R. & Praamstra, P. (2001). The five percent electrode
#'   system for high-resolution EEG and ERP measurements. Clinical
#'   Neurophysiology, 112, 4, 713-719
#' @param data An EEG dataset.
#' @param ... Passed to S3 methods.
#' @examples
#' channels(demo_epochs)
#' electrode_locations(demo_epochs, overwrite = TRUE, montage = "biosemi64alpha")
#' @export

electrode_locations <- function(data, ...) {
  UseMethod("electrode_locations")
}

#' @param electrode The column name containing electrode names in data.
#'   (Defaults to "electrode").
#' @param drop Should electrodes in `data` for which default locations are
#'   not available be removed? (Defaults to FALSE).
#' @param montage Name of an existing montage set. Defaults to NULL.
#' @importFrom dplyr inner_join pull left_join distinct
#' @importFrom tibble is_tibble
#' @describeIn electrode_locations Adds standard locations to a data frame in
#'   long format
#' @return A tibble (or data.frame), or ggplot2 object if `plot = TRUE`.
#' @export

electrode_locations.data.frame <- function(data,
                                           electrode = "electrode",
                                           drop = FALSE,
                                           montage = NULL,
                                           ...) {

  #if a montage supplied, check if it matches known montages
  if (!is.null(montage)) {
    electrodeLocs <- montage_check(montage)
  }

  data[, electrode] <- toupper(data[[electrode]])
  electrodeLocs[, electrode] <- toupper(electrodeLocs[[electrode]])

  if (tibble::is_tibble(data)) {
    elecs <-
      dplyr::pull(unique(data[, electrode])) %in%
      dplyr::pull(electrodeLocs[, electrode])

    if (!all(elecs)) {
      message(paste("Electrode locations not found: ",
                    paste(unique(data[, electrode])[!elecs, ],
                          sep = ",")))
    } else if (!any(elecs)) {
      stop("No matching electrode locations found.")
    }
  } else {
    elecs <-
      unique(data[, electrode]) %in% electrodeLocs[, electrode,
                                                   drop = TRUE]
    if (!all(elecs)) {
      message("Electrodes locations not found: ",
              paste(unique(data[, electrode])[!elecs], collapse = " "))
    } else if (!any(elecs)) {
      stop("No matching electrode locations found.")
    }

  }

  if (drop) {
    data <- dplyr::inner_join(data,
                              electrodeLocs,
                              by = electrode)
  } else {
    data <- dplyr::left_join(data,
                             electrodeLocs,
                             by = electrode)
  }

  data
}

#' @param overwrite Overwrite existing channel info. Defaults to FALSE.
#' @describeIn electrode_locations Adds standard locations to the chan_info field of an eeg_data object.
#' @export

electrode_locations.eeg_data <- function(data,
                                         drop = FALSE,
                                         montage = NULL,
                                         overwrite = FALSE,
                                         ...) {

  add_elocs(data,
            drop = drop,
            montage = montage,
            overwrite = overwrite)
}

#' @describeIn electrode_locations Adds standard locations to the chan_info field of an `eeg_data` object.
#' @export

electrode_locations.eeg_epochs <- function(data,
                                           drop = FALSE,
                                           montage = NULL,
                                           overwrite = FALSE,
                                           ...) {

  add_elocs(data,
            drop = drop,
            montage = montage,
            overwrite = overwrite)
}

#' @describeIn electrode_locations Adds standard locations to the chan_info field of an `eeg_tfr` object.
#' @export
electrode_locations.eeg_tfr <- function(data,
                                        drop = FALSE,
                                        montage = NULL,
                                        overwrite = FALSE,
                                        ...) {

  add_elocs(data,
            drop = drop,
            montage = montage,
            overwrite = overwrite)
}

#' @keywords internal
add_elocs <- function(data,
                      drop = FALSE,
                      montage = NULL,
                      overwrite = FALSE,
                      ...) {

  chan_info <- channels(data)
  chan_names <- channel_names(data)

  if (!is.null(chan_info) & !overwrite) {
    stop("Channel info already present, set overwrite to TRUE to replace.")
  }

  if (!is.null(montage)) {
    electrodeLocs <- montage_check(montage)
  }

  elec_names <- toupper(chan_names)
  electrodeLocs$electrode <- toupper(electrodeLocs$electrode)

  matched_els <- electrodeLocs$electrode %in% elec_names
  missing_els <- !elec_names %in% electrodeLocs$electrode

  if (!any(matched_els)) {
    stop("No matching electrodes found.")
  } else if (any(missing_els)) {
    message("Electrodes not found: ",
            paste(chan_names[missing_els],
                  collapse = " "))
  }

  chan_info <- electrodeLocs[matched_els, ]

  if (drop) {
     data <- select_elecs(data,
                          chan_names[missing_els],
                          keep = FALSE)
  }

  channels(data) <- validate_channels(chan_info,
                                      channel_names(data))
  data
}


#' Plot electrode locations
#'
#' Produces either a 2D plot of the electrode locations or an interactive plot
#' of electrode locations in 3D space.
#'
#' @examples
#'
#' plot_electrodes(demo_epochs)
#'
#' @author Matt Craddock \email{matt@@mattcraddock.com}
#'
#' @param data Data with associated electrode locations to be plotted.
#' @param interact Choose 2D cartesian layout, or, if set to TRUE, an
#'   interactive 3D plot of electrode locations. Defaults to FALSE.
#' @return A `ggplot` or `plotly` figure showing the locations of the
#'   electrodes
#' @export

plot_electrodes <- function(data,
                            interact = FALSE) {
  UseMethod("plot_electrodes", data)
}

#' @import ggplot2
#' @describeIn plot_electrodes generic plot electrodes function
#' @export

plot_electrodes.default <- function(data,
                                    interact = FALSE) {

  if ("electrode" %in% names(data)) {
    data <- data.frame(electrode = unique(data$electrode))
    data <- electrode_locations(data)

    if (interact) {
      if (!requireNamespace("plotly", quietly = TRUE)) {
        stop("Package \"plotly\" needed for interactive electrode plots. Please install it.",
             call. = FALSE)
      }
      plotly::plot_ly(data,
                      x = ~cart_x,
                      y = ~cart_y,
                      z = ~cart_z,
                      text = ~electrode,
                      type = "scatter3d",
                      mode = "text+markers")
    } else {
      ggplot2::ggplot(data,
                      ggplot2::aes(x = x,
                                   y = y,
                                   label = electrode)) +
        ggplot2::geom_text() +
        ggplot2::theme_minimal() +
        ggplot2::coord_equal() +
        ggplot2::labs(x = "x (mm)",
                      y = "y (mm)")
    }
  } else {
    stop("No electrodes found.")
  }
}

#' @describeIn plot_electrodes Plot electrodes associated with an `eeg_data` object.
#' @export
plot_electrodes.eeg_data <- function(data,
                                     interact = FALSE) {

  if (is.null(channels(data))) {
    stop("No channel locations found.")
  }

  if (interact) {
    if (!requireNamespace("plotly", quietly = TRUE)) {
      stop("Package \"plotly\" needed for interactive electrode plots. Please install it.",
           call. = FALSE)
    }

    plotly::plot_ly(data$chan_info,
                    x = ~cart_x,
                    y = ~cart_y,
                    z = ~cart_z,
                    text = ~electrode,
                    type = "scatter3d",
                    mode = "text+markers")
  } else {
    ggplot2::ggplot(data$chan_info,
                    aes(x = x,
                        y = y,
                        label = electrode)) +
      geom_text() +
      theme_minimal() +
      coord_equal() +
      ggplot2::labs(x = "x (mm)",
                    y = "y (mm)")
  }
}

#' @describeIn plot_electrodes Plot electrodes associated with an `eeg_data` object.
#' @export
plot_electrodes.eeg_tfr <- function(data,
                                     interact = FALSE) {

  if (is.null(channels(data))) {
    stop("No channel locations found.")
  }

  if (interact) {
    if (!requireNamespace("plotly", quietly = TRUE)) {
      stop("Package \"plotly\" needed for interactive electrode plots. Please install it.",
           call. = FALSE)
    }

    plotly::plot_ly(data$chan_info,
                    x = ~cart_x,
                    y = ~cart_y,
                    z = ~cart_z,
                    text = ~electrode,
                    type = "scatter3d",
                    mode = "text+markers")
  } else {
    ggplot2::ggplot(data$chan_info,
                    aes(x = x,
                        y = y,
                        label = electrode)) +
      geom_text() +
      theme_minimal() +
      coord_equal() +
      ggplot2::labs(x = "y (mm)",
                    y = "x (mm)")
  }
}

#' Montage check
#'
#' @param montage Name of montage
#' @keywords internal

montage_check <- function(montage) {

  elocs <-
    switch(montage,
           biosemi64 = biosemi64,
           biosemi64alpha = biosemi64alpha,
           biosemi128 = biosemi128,
           biosemi256 = biosemi256,
           biosemi16 = biosemi16,
           biosemi32 = biosemi32)

  if (is.null(elocs)) {
    stop("Unknown montage specified.")
  }
  elocs
}

#' Chan_info checker
#'
#' Performs several checks on the structure of channel info: 1) Checks that
#' "electrode" is character, not factor. 2) rounds any numeric values to 2
#' decimal places. 3) Checks for any missing channels in the chan_info if signal
#' names are supplied; populates them with NA if it finds any.
#'
#' @param chan_info A channel info structure
#' @param sig_names signal names from eegUtils signals
#' @keywords internal
validate_channels <- function(chan_info,
                              sig_names = NULL) {

  if (!is.null(sig_names)) {
    #use toupper to ensure matches between added chan_info
    chan_info$electrode <- toupper(chan_info$electrode)
    missing_sigs <- !(toupper(sig_names) %in% chan_info$electrode)


    if (any(missing_sigs)) {
      chan_info <- merge(data.frame(electrode = toupper(sig_names)),
                         chan_info,
                         all.x = TRUE,
                         sort = FALSE)
    }
    # make sure chan_info is in the same order as the signal names
    chan_info <- chan_info[match(toupper(sig_names),
                                 chan_info$electrode), ]
    # make sure chan_info electrode is the same case as the signal names
    chan_info$electrode <- sig_names
  }

  # merge always converts strings to factors,
  # so also make sure electrode is not a factor
  chan_info$electrode <- as.character(chan_info$electrode)
  num_chans <- sapply(chan_info,
                      is.numeric)
  chan_info[, num_chans] <- round(chan_info[, num_chans], 2)

  required_cols <- c("electrode",
                     "radius",
                     "theta",
                     "phi",
                     "cart_x",
                     "cart_y",
                     "cart_z",
                     "x",
                     "y")

  missing <- setdiff(required_cols,
                     names(chan_info))
  chan_info[missing] <- NA
  chan_info <- chan_info[required_cols]

  tibble::as_tibble(chan_info)
}

#' Modify channel information
#'
#' Get or set the contents of the channel information inside `eegUtils` objects.
#'
#' @examples
#' channels(demo_epochs)
#'
#' @author Matt Craddock \email{matt@@mattcraddock.com}
#' @param .data `eegUtils` object to view
#' @export
channels <- function(.data) {
  UseMethod("channels", .data)
}

#' @export
channels.eeg_epochs <- function(.data) {
  .data$chan_info
}

#' @export
channels.eeg_tfr <- function(.data) {
  .data$chan_info
}

#' @export
channels.eeg_data <- function(.data) {
  .data$chan_info
}

#' @export
channels.eeg_ICA <- function(.data) {
  .data$chan_info
}

#' @export
channels.eeg_evoked <- function(.data) {
  .data$chan_info
}

#' @export
channels.eeg_stats <- function(.data) {
  .data$chan_info
}

#' @param value Value to replace `chan_info` structure with.
#' @rdname channels
#' @export
`channels<-` <- function(.data, value) {
  UseMethod("channels<-", .data)
}

#' @export
`channels<-.eeg_epochs` <- function(.data, value) {
  .data$chan_info <- value
  .data
}

#' @export
`channels<-.eeg_data` <- function(.data, value) {
  .data$chan_info <- value
  .data
}

#' @export
`channels<-.eeg_tfr` <- function(.data, value) {
  .data$chan_info <- value
  .data
}

#' @export
`channels<-.eeg_ICA` <- function(.data, value) {
  .data$chan_info <- value
  .data
}

#' @export
`channels<-.eeg_evoked` <- function(.data, value) {
  .data$chan_info <- value
  .data
}

#' @export
`channels<-.eeg_stats` <- function(.data, value) {
  .data$chan_info <- value
  .data
}

#' Retrieve signal/channel names
#'
#' Get the names of the `signals` element of `eegUtils` objects.
#'
#' @examples
#' channel_names(demo_epochs)
#'
#' @param .data `eegUtils object`
#' @export
channel_names <- function(.data) {
  if (is.eeg_tfr(.data)) {
    return(dimnames(.data$signals)$electrode)
  }
  names(.data$signals)
}

#' Normalize 3d Cartesian co-ordinates to unit sphere
#'
#' @param xyz_coords 3D Cartesian electrode locations
#' @keywords internal
norm_sphere <- function(xyz_coords) {

  circ <- sqrt(rowSums(xyz_coords ^ 2))
  xyz_coords <- xyz_coords / circ
  names(xyz_coords) <- c("cart_x", "cart_y", "cart_z")
  xyz_coords
}

#' Convert 3D Cartesian coordinates to spherical coordinates
#'
#' Output theta and phi are in degrees.
#'
#' @param xyz_coords 3D Cartesian electrode locations
#' @keywords internal
cart_to_spherical <- function(xyz_coords) {


  radius <- sqrt(rowSums(xyz_coords ^ 2))
  phi <- rad2deg(atan(xyz_coords$cart_y / xyz_coords$cart_x))
  theta <- rad2deg(acos(xyz_coords$cart_z / radius))
  theta <- ifelse(xyz_coords$cart_x >= 0, theta, -theta)
  #phi <- ifelse(xyz_coords$cart_x == 0, -phi, phi) why is this here?
  phi <- ifelse(is.nan(phi), 0, phi)
  data.frame(radius = 1,
             theta = round(theta),
             phi = round(phi))
}

#' Convert spherical co-ordinates to Cartesian 3D co-ordinates

#' @param sph_coords Theta and phi in degrees.
#' @param radius Radius of head (in mm)
#' @keywords internal
sph_to_cart <- function(theta,
                             phi,
                             radius = 85) {
  theta <- deg2rad(theta)
  phi <- deg2rad(phi)
  cart_x <- radius * sin(theta) * cos(phi)
  cart_y <- radius * sin(theta) * sin(phi)
  cart_z <- radius * cos(theta)
  tibble::tibble(cart_x = round(cart_x, 2),
                 cart_y = round(cart_y, 2),
                 cart_z = round(cart_z, 2))
}

#' Convert degrees to radians
#' @param x Degrees to convert
#' @keywords internal
deg2rad <- function(x) {
  x <- x * pi / 180
  x
}

#' Convert radians to degrees
#' @param x Radians to convert
#' @keywords internal
rad2deg <- function(x) {
  x <- x * 180 / pi
  x
}

#' Electrode projection
#'
#' Project a set of 3D Cartesian co-ordinates to a 2D plane for plotting. The
#' projection can be orthographic or stereographic. Orthographic is closer to
#' how the scalp would look from above, since it does not compensate for
#' height/distance from the xy plane. This causes bunching up of electrodes near
#' the limits of the head. Stereographic preserves more of the general shape of
#' the features by "unrolling" the electrode positions.
#'
#' @param chan_info Channel information from an eegUtils object
#' @param method Method of projection. "stereographic" or "orthographic".
#'   Defaults to sterographic.
#' @keywords internal
project_elecs <- function(chan_info,
                          method = "stereographic") {
  switch(method,
         stereographic = stereo_norm(chan_info),
         orthographic = ortho_norm(chan_info))
}

#' Stereographic electrode projection
#'
#' Produce a set of x and y coordinates for plotting from 3D Cartesian
#' coordinates. This is a stereographic projection of the 3D coordinates, which
#' compensates for the distance of the electrode from the projecting point and
#' flattens out the scalp.
#'
#' @param chan_info Channel information from an eegUtils objects
#' @return A data.frame with x and y columns indictating electrode positions in
#'   degrees
#' @keywords internal
stereo_norm <- function(chan_info) {
  x <- deg2rad(chan_info$theta) * cos(deg2rad(chan_info$phi))
  y <- deg2rad(chan_info$theta) * sin(deg2rad(chan_info$phi))
  data.frame(x = round(rad2deg(x), 2),
             y = round(rad2deg(y), 2))
}


#' Orthographic electrode projection
#'
#' Produce a set of x and y coordinates for plotting from 3D Cartesian
#' coordinates. This is an orthographic projection of the 3D coordinates,
#' resulting in bunching up of electrodes at the further reaches of the head.
#'
#' @param chan_info Channel information from an eegUtils objects
#' @return A data.frame with x and y columns indictating electrode positions in
#'   mm
#' @keywords internal
ortho_norm <- function(chan_info) {
  x <- round(chan_info$cart_x, 2)
  y <- round(chan_info$cart_y, 2)
  data.frame(x, y)
}

#' Check if chan_info is in old format
#'
#' @param chan_info Channel info structure
#' @keywords internal

check_ci_str <- function(chan_info) {
  orig_names <- c("chanNo",
                  "theta",
                  "radius",
                  "electrode",
                  "radianTheta",
                  "x",
                  "y")
  if (identical(orig_names, names(chan_info))) {
    stop("New channel locations required - see ?electrode_locations()")
  }
}
