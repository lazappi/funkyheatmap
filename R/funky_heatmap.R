#' Generate a funky heatmaps for benchmarks
#'
#' Allows generating heatmap-like visualisations for benchmark data
#' frames. Funky heatmaps can be fine-tuned by providing annotations of the
#' columns and rows, which allows assigning multiple palettes or geometries
#' or grouping rows and columns together in categories.
#'
#' @param data A data frame with items by row and features in the columns.
#' Must contain one column named `"id"`.
#'
#' @param column_info A data frame describing which columns in `data` to
#' plot. This data frame should contain the following columns:
#'
#' * `id` (`character`): The corresponding column name in `data`.
#'
#' * `name` (`character`): A label for the column. If `NA` or `""`,
#'   no label will be plotted. If this column is missing, `id` will
#'   be used to generate the `name` column.
#'
#' * `geom` (`character`): The geom of the column. Must be one of:
#'   `"funkyrect"`, `"circle"`, `"rect"`, `"bar"`, `"pie"`, `"text"` or `"image"`.
#'   For `"text"`, the corresponding column in `data` must be a `character`.
#'   For `"pie"`, the column must be a list of named numeric vectors.
#'   For all other geoms, the column must be a `numeric`.
#'
#' * `group` (`character`): The grouping id of each column, must match with
#'   `column_groups$group`. If this column is missing or all values are `NA`,
#'   columns are assumed not to be grouped.
#'
#' * `palette` (`character`): Which palette to colour the geom by.
#'   Each value should have a matching value in `palettes$palette`.
#'
#' * `width`: Custom width for this column (default: 1).
#'
#' * `overlay`: Whether to overlay this column over the previous column.
#'     If so, the width of that column will be inherited.
#'
#' * `legend`: Whether or not to add a legend for this column.
#'
#' * `hjust`: Horizontal alignment of the bar, must be between \[0,1\]
#'     (only for `geom = "bar"`).
#'
#' * `hjust`: Horizontal alignment of the label, must be between \[0,1\]
#'     (only for `geom = "text"`).
#'
#' * `vjust`: Vertical alignment of the label, must be between \[0,1\]
#'     (only for `geom = "text"`).
#'
#' * `size`: Size of the label, must be between \[0,1\]
#'     (only for `geom = "text"`).
#'
#' * `label`: Which column to use as a label (only for `geom = "text"`).
#'
#' * `directory`: Which directory to use to find the images (only for `geom = "image"`).
#'
#' * `extension`: The extension of the images (only for `geom = "image"`).
#'
#' * `options` (`list` or `json`): Any of the options above. Any values in this
#'   column will be spread across the other columns. This is useful for
#'   not having to provide a data frame with 1000s of columns.
#'   This column can be a json string.
#'
#' @param row_info A data frame describing the rows of `data`.
#' This data should contain two columns:
#'
#' * `id` (`character`): Corresponds to the column `data$id`.
#'
#' * `group` (`character`): The group of the row.
#'   If all are `NA`, the rows will not be split up into groups.
#'
#' @param column_groups A data frame describing of how to group the columns
#' in `column_info`. Can consist of the following columns:
#'
#' * `group` (`character`): The corresponding group in `column_info$group`.
#' * `palette` (`character`, optional): The palette used to colour the
#'   column group backgrounds.
#' * `level1` (`character`): The label at the highest level.
#' * `level2` (`character`, optional): The label at the middle level.
#' * `level3` (`character`, optional): The label at the lowest level
#'   (not recommended).
#'
#' @param row_groups A data frame describing of how to group the rows
#' in `row_info`. Can consist of the following columns:
#'
#' * `group` (`character`): The corresponding group in `row_info$group`.
#' * `level1` (`character`): The label at the highest level.
#' * `level2` (`character`, optional): The label at the middle level.
#' * `level3` (`character`, optional): The label at the lowest level
#'   (not recommended).
#'
#' @param palettes A named list of palettes. Each entry in `column_info$palette`
#' should have an entry in this object. If an entry is missing, the type
#' of the column will be inferred (categorical or numerical) and one of the
#' default palettes will be applied. Alternatively, the name of one of the
#' standard palette names can be used:
#'
#' * `numerical`: `"Greys"`, `"Blues"`, `"Reds"`, `"YlOrBr"`, `"Greens"`
#' * `categorical`: `"Set3"`, `"Set1"`, `"Set2"`, `"Dark2"`
#'
#'
#' @param scale_column Whether or not to apply min-max scaling to each
#' numerical column.
#'
#' @param add_abc Whether or not to add subfigure labels to the different
#' columns groups.
#'
#' @param col_annot_offset How much the column annotation will be offset by.
#' @param col_annot_angle The angle of the column annotation labels.
#' @param removed_entries Which methods to not show in the rows. Missing methods
#' are replaced by a "Not shown" label.
#'
#' @param expand A list of directions to expand the plot in.
#'
#' @importFrom ggforce geom_arc_bar geom_circle geom_arc
#' @importFrom cowplot theme_nothing
#'
#' @returns A ggplot. `.$width` and `.$height` are suggested dimensions for
#' storing the plot with [ggsave()].
#'
#' @export
#'
#' @examples
#' library(tibble, warn.conflicts = FALSE)
#'
#' data("mtcars")
#'
#' data <- rownames_to_column(mtcars, "id")
#'
#' funky_heatmap(data)
funky_heatmap <- function(
    data,
    column_info = NULL,
    row_info = NULL,
    column_groups = NULL,
    row_groups = NULL,
    palettes = NULL,
    scale_column = TRUE,
    add_abc = TRUE,
    col_annot_offset = 3,
    col_annot_angle = 30,
    removed_entries = NULL,
    expand = c(xmin = 0, xmax = 2, ymin = 0, ymax = 0)) {
  # validate input objects
  data <- verify_data(data)
  column_info <- verify_column_info(column_info, data)
  row_info <- verify_row_info(row_info, data)
  column_groups <- verify_column_groups(column_groups, column_info)
  row_groups <- verify_row_groups(row_groups, row_info)
  palettes <- verify_palettes(palettes, column_info, data)
  # todo: add column groups to verify_palettes

  geom_positions <- calculate_geom_positions(
    data,
    column_info,
    row_info,
    column_groups,
    row_groups,
    palettes,
    scale_column,
    add_abc,
    col_annot_offset,
    col_annot_angle,
    removed_entries
  )

  compose_ggplot(
    geom_positions,
    expand
  )
}
