#' Plot Loch Rannoch
#'
#' Returns a ggplot2 object of a map of Loch Rannoch.
#'
#' @param rannoch A data frame of the rannoch polygons with columns Easting and Northing in km.
#' @return A ggplot2 object.
#' @export
#' @examples
#' rannoch <- ggplot2::fortify(ranmrdata::rannoch)
#' rannoch <- dplyr::mutate(rannoch, Easting = long / 1000, Northing = lat / 1000)
#' plot_rannoch(rannoch)
plot_rannoch <- function(rannoch) {
  ggplot2::ggplot(data = rannoch,  ggplot2::aes_string(x = "Easting", y = "Northing")) +
    ggplot2::geom_polygon(fill = "grey70", color = "grey50") +
    ggplot2::coord_equal() + ggplot2::scale_x_continuous("Easting (km)", labels = scales::comma) +
    ggplot2::scale_y_continuous("Northing (km)", labels = scales::comma)
}

#' Plot Mark-Recapture Data
#'
#' Plots mark-recapture data as an x-y scatterplot where consecutive
#' encounters with the same individual are joined by lines.
#' The data must be in the same format as the \code{\link{ferox}}
#' data provided with this package (only the two columns specified in the
#' plot plus the Fish and Date columns are required).
#'
#' @param x A data.frame of the mark-recapture data to plot.
#' @param xcol A string of the column to plot on the x-axis.
#' @param ycol A string of the column to plot on the y-axis.
#' @param xlab A optional string of the x-axis label.
#' @param ylab A optional string of the y-axis label.
#' @param gp An optional ggplot object
#' @return A ggplot object.
#' @seealso \code{\link{ranmr}}
#' @export
#' @examples
#' plot_mr(ranmrdata::ferox@data)
plot_mr <- function(x, xcol = "Length", ycol = "Mass", xlab = NULL, ylab = NULL, gp = NULL) {
  assert_that(is.data.frame(x))
  assert_that(is.string(xcol))
  assert_that(is.string(ycol))
  assert_that(is.null(xlab) || is.string(xlab))
  assert_that(is.null(ylab) || is.string(ylab))
  assert_that(is.null(gp) || ggplot2::is.ggplot(gp))

  check_rows(x)
  check_columns(x, c("Fish", xcol, ycol))

  x <- process_mr_data(x)
  y <- dplyr::filter_(x, ~Fish %in% x$Fish[x$InterRecapture])
  y <- dplyr::arrange_(y, ~Fish, ~Date)
  y$xend <- c(y[[xcol]][-1], NA)
  y$yend <- c(y[[ycol]][-1], NA)
  y <- dplyr::filter_(y, ~!c(diff(Fish), 1))

  if (is.null(gp))
    gp <- ggplot2::ggplot(data = x, ggplot2::aes_string(x = xcol, y = ycol))
  gp <- gp + ggplot2::geom_segment(data = y, ggplot2::aes_string(xend = "xend",
                                                       yend = "yend"))
  gp <- gp + ggplot2::geom_point(data = x, ggplot2::aes_string(color = "InterRecapture",
                                                     shape = "InterRecapture"))
  gp <- gp + ggplot2::scale_color_manual(values = c("black", "red"))
  if (!is.null(xlab))
    gp <- gp + ggplot2::xlab(xlab)
  if (!is.null(ylab))
    gp <- gp + ggplot2::ylab(ylab)
  gp <- gp + ggplot2::theme(legend.position = "none")
  gp
}

#' Plot Mark-Recapture Analysis
#'
#' Plots a mark-recapture analysis as an abundance plot.
#'
#' @param x A jags_analysis object of the mark-recapture analysis to plot.
#' @return A ggplot object.
#' @seealso \code{\link{ranmr}}
#' @export
plot_abundance <- function(x) {
  assert_that(jaggernaut::is.jags_analysis(x))

  abundance <- stats::coef(x, parm = "N")

  abundance$Year <- as.integer(as.character(levels(jaggernaut::dataset(x)$Year)))

  gp <- ggplot2::ggplot(data = abundance, ggplot2::aes_string(y = "estimate", x = "Year"))
  gp <- gp + ggplot2::geom_line()
  gp <- gp + ggplot2::geom_line(ggplot2::aes_string(y = "lower"),
                                linetype = "dotted")
  gp <- gp + ggplot2::geom_line(ggplot2::aes_string(y = "upper"),
                                linetype = "dotted")
  gp <- gp + ggplot2::xlab("Year")
  gp <- gp + ggplot2::ylab("Abundance")
  gp <- gp + ggplot2::expand_limits(y = 0)
  gp
}
