compose_ggplot <- function(
    geom_positions,
    expand) {
  # start ggplot
  g <-
    ggplot() +
    coord_equal(expand = FALSE) +
    scale_alpha_identity() +
    scale_colour_identity() +
    scale_fill_identity() +
    scale_size_identity() +
    scale_linetype_identity() +
    cowplot::theme_nothing()

  # PLOT ROW BACKGROUNDS
  df <- geom_positions$row_pos %>% filter(.data$colour_background)
  if (nrow(df) > 0) {
    g <- g + geom_rect(
      aes(
        xmin = min(geom_positions$column_pos$xmin) - .25,
        xmax = max(geom_positions$column_pos$xmax) + .25,
        ymin = .data$ymin - (geom_positions$viz_params$row_space / 2),
        ymax = .data$ymax + (geom_positions$viz_params$row_space / 2)
      ),
      df,
      fill = "#DDDDDD"
    )
  }

  # PLOT SEGMENTS
  if (nrow(geom_positions$segment_data) > 0) {
    # add defaults for optional values
    geom_positions$segment_data <- geom_positions$segment_data %>% add_column_if_missing(
      size = .5,
      colour = "black",
      linetype = "solid"
    )

    g <- g + geom_segment(
      aes(
        x = .data$x,
        xend = .data$xend,
        y = .data$y,
        yend = .data$yend,
        size = .data$size, # todo: update to linewidth
        colour = .data$colour,
        linetype = .data$linetype
      ),
      geom_positions$segment_data
    )
  }

  # PLOT RECTANGLES
  if (nrow(geom_positions$rect_data) > 0) {
    # add defaults for optional values
    geom_positions$rect_data <- geom_positions$rect_data %>%
      add_column_if_missing(
        alpha = 1,
        border = TRUE,
        border_colour = "black"
      ) %>%
      mutate(
        border_colour = ifelse(.data$border, .data$border_colour, NA_character_)
      )

    g <- g + geom_rect(
      aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = .data$ymin,
        ymax = .data$ymax,
        fill = .data$colour,
        colour = .data$border_colour,
        alpha = .data$alpha
      ),
      geom_positions$rect_data,
      size = .25
    )
  }

  # PLOT CIRCLES
  if (nrow(geom_positions$circle_data) > 0) {
    g <- g + ggforce::geom_circle(
      aes(
        x0 = .data$x0,
        y0 = .data$y0,
        fill = .data$colour,
        r = .data$r
      ),
      geom_positions$circle_data,
      size = .25
    )
  }

  # PLOT FUNKY RECTANGLES
  if (nrow(geom_positions$funkyrect_data) > 0) {
    g <- g + geom_rounded_rect(
      aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = .data$ymin,
        ymax = .data$ymax,
        radius = .data$corner_size,
        fill = .data$colour
      ),
      geom_positions$funkyrect_data,
      size = .25,
      colour = "black"
    )
  }

  # PLOT PIES
  if (nrow(geom_positions$pie_data) > 0) {
    g <- g + ggforce::geom_arc_bar(
      aes(
        x0 = .data$x0,
        y0 = .data$y0,
        r0 = .data$r0,
        r = .data$r,
        start = .data$rad_start,
        end = .data$rad_end,
        fill = .data$colour
      ),
      data = geom_positions$pie_data,
      size = .25
    )
  }
  # PLOT IMAGES
  if (nrow(geom_positions$img_data) > 0) {
    for (r in seq_len(nrow(geom_positions$img_data))) {
      g <- g + cowplot::draw_image(
        geom_positions$img_data[r, "path"],
        x = geom_positions$img_data[r, "xmin"],
        y = geom_positions$img_data[r, "ymin"]
      )
    }
  }

  # PLOT TEXT
  if (nrow(geom_positions$text_data) > 0) {
    # add defaults for optional values
    geom_positions$text_data <- geom_positions$text_data %>%
      add_column_if_missing(
        hjust = .5,
        vjust = .5,
        size = 4,
        fontface = "plain",
        colour = "black",
        lineheight = 1,
        angle = 0
      ) %>%
      mutate(
        angle2 = .data$angle / 360 * 2 * pi,
        cosa = cos(.data$angle2) %>% round(2),
        sina = sin(.data$angle2) %>% round(2),
        alphax =
          ifelse(.data$cosa < 0, 1 - .data$hjust, .data$hjust) * abs(.data$cosa) +
            ifelse(.data$sina > 0, 1 - .data$vjust, .data$vjust) * abs(.data$sina),
        alphay =
          ifelse(.data$sina < 0, 1 - .data$hjust, .data$hjust) * abs(.data$sina) +
            ifelse(.data$cosa < 0, 1 - .data$vjust, .data$vjust) * abs(.data$cosa),
        x = (1 - .data$alphax) * .data$xmin + .data$alphax * .data$xmax,
        y = (1 - .data$alphay) * .data$ymin + .data$alphay * .data$ymax
      ) %>%
      filter(.data$label_value != "")

    g <- g + geom_text(
      aes(
        x = .data$x,
        y = .data$y,
        label = .data$label_value,
        colour = .data$colour,
        hjust = .data$hjust,
        vjust = .data$vjust,
        size = .data$size,
        fontface = .data$fontface,
        angle = .data$angle
      ),
      data = geom_positions$text_data
    )
  }

  # todo: need a generic solution
  # # PLOT TRAJ TYPES
  # if (nrow(trajd) > 0) {
  #   g <-
  #     plot_trajectory_types(
  #       plot = g,
  #       trajectory_types = trajd$topinf,
  #       xmins = trajd$xmin,
  #       xmaxs = trajd$xmax,
  #       ymins = trajd$ymin,
  #       ymaxs = trajd$ymax,
  #       node_colours = trajd$colour,
  #       edge_colours = trajd$colour,
  #       size = 1,
  #       geom = "circle",
  #       circ_size = .1
  #     )
  # }


  # ADD SIZE
  # reserve a bit more room for text that wants to go outside the frame
  expand_li <- as.list(expand)
  minimum_x <- geom_positions$bounds$minimum_x - (expand_li$xmin %||% 0)
  maximum_x <- geom_positions$bounds$maximum_x + (expand_li$xmax %||% 0)
  minimum_y <- geom_positions$bounds$minimum_y - (expand_li$ymin %||% 0)
  maximum_y <- geom_positions$bounds$maximum_y + (expand_li$ymax %||% 0)
  g <- g + expand_limits(
    x = c(minimum_x, maximum_x),
    y = c(minimum_y, maximum_y)
  )

  # store dimensions
  g$minimum_x <- minimum_x
  g$maximum_x <- maximum_x
  g$minimum_y <- minimum_y
  g$maximum_y <- maximum_y
  g$width <- (maximum_x - minimum_x) / 4
  g$height <- (maximum_y - minimum_y) / 4

  # return plot
  g
}
