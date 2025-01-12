#' join omop concept name onto a dataframe with a *_concept_id column
#'
#' adds (namestart)_name based on (namestart)_concept_id
#' e.g. drug_concept_id to get drug_name
#'
#' @param df dataframe
#' @param namestart start of *_concept_id column, if "" will join on concept_name, ignored if namefull used
#' @param namefull optional full name of concept_id column, if default "" namestart used
#' @param domain whether to add domain_id column, default FALSE
#' @param vocabulary whether to add vocabulary_id column, default FALSE
#' @param concept_class whether to add concept_class_id column, default FALSE
#' @export
#' @examples
#' data.frame(concept_id=(c(3571338L,4002075L))) |> omop_join_name()
#' data.frame(drug_concept_id=(c(4000794L,4002592L))) |> omop_join_name(namestart="drug")
#' #if drug_exposure loaded:
#' #df2 <- drug_exposure |> distinct(route_concept_id) |> omop_join_name(namestart="route")
#' #df3 <- omop_concept_relationship() |> head() |>
#' #       dplyr::collect() |> omop_join_name(namefull="concept_id_1")
omop_join_name <- function(df,
                           namestart = "",
                           namefull = "",
                           domain = FALSE,
                           vocabulary = FALSE,
                           concept_class = FALSE
                           #todo can add standard_concept & concept_code
                           ) {

  #"" is to cope with concept_id from omop_join_name_all()
  if (namefull != "") id_col_name <- namefull
  else if (namestart == "") id_col_name <- "concept_id"
  else id_col_name  <- paste0(namestart,"_concept_id")

  #e.g. ancestor_concept_id to ancestor_name
  name_col_name <- sub("_id","_name",id_col_name)
  #maybe offer an option of
  #name_col_name <- sub("_concept_id","_name",id_col_name)

  #beware rename concept_name column before joining in case
  #there is already a concept_name column in df

  columns2join <- c("concept_id","concept_name")

  #2023-10-05 optionally include vocabulary_id and domain_id
  #protect against problem if more than 1 id column it can become .x,.y etc.
  if (domain == TRUE & !("domain_id" %in% names(df)))
    columns2join <- c(columns2join, "domain_id")
  if (vocabulary == TRUE & !("vocabulary_id" %in% names(df)))
    columns2join <- c(columns2join, "vocabulary_id")
  if (concept_class == TRUE & !("concept_class_id" %in% names(df)))
    columns2join <- c(columns2join, "concept_class_id")

  id_and_name <- omopcept::omop_concept() |>
    select(any_of(columns2join)) |>
    #change concept_name to the full name
    rename_with(~name_col_name, concept_name)

  #TODO can I make this faster by replacing the copy=TRUE
  #with some filter & collect ?

  df |>
    left_join(id_and_name, by = dynamic_by(id_col_name,"concept_id"), copy = TRUE) |>
    #move name column next to id to make output more readable
    dplyr::relocate(name_col_name, .after=id_col_name)

#TODO maybe add option to deselect some table columns to make more readable

}


#' super short name func to join concept_names on
#' @rdname omop_join_name
#' @export
#' @examples
#' data.frame(drug_concept_id=(c(4000794L,4002592L))) |> ojoin(namestart="drug")
ojoin <- omop_join_name


#' join omop concept names onto all *_concept_id columns in a dataframe
#'
#' adds \\*_name based on \\*_concept_id
#' e.g. drug_concept_id to get drug_name etc.
#'
#' @param df dataframe
#' @param domain whether to add domain_id column, default FALSE
#' @param vocabulary whether to add vocabulary_id column, default FALSE
#' @param concept_class whether to add concept_class_id column, default FALSE
#'
#' @return dataframe based on input df with 1 extra column added for each concept_id column
#' @export
#' @examples
#' data.frame(concept_id=(c(3571338L,3655355L)),
#'            drug_concept_id=(c(4000794L,35628998L))) |>
#'            omop_join_name_all()
#' #examples commented for now mostly to speed package build
#' #data.frame(route_concept_id=(c(4132161L,	4171047L)),
#' #          drug_concept_id=(c(1550560L,	35780880L))) |>
#' #          omop_join_name_all()
#' #df2 <- drug_exposure |>
#' #       head(100)) |>
#' #       omop_join_name_all()
#' #df3 <- omop_concept_relationship() |> head() |>
#' #          dplyr::collect() |> omop_join_name_all()
omop_join_name_all <- function(df,
                               domain = FALSE,
                               vocabulary = FALSE,
                               concept_class = FALSE) {

  #logic
  #if colname contains *_concept_id do omop_join_name(namestart=*)
  #else if colname contains concept_id do omop_join_name(namefull=colname)

  colnames <- df |>
    select(contains("concept_id")) |>
    names() |>
    stringr::str_remove("_concept_id")


  for(cname in colnames)
  {
    if (str_detect(cname,"concept_id")) {
          df <- df |> omop_join_name(namefull=cname, domain=domain, vocabulary=vocabulary, concept_class=concept_class )
    } else
          df <- df |> omop_join_name(namestart=cname, domain=domain, vocabulary=vocabulary, concept_class=concept_class )
  }

  return(df)
}

#' super short name func to join all concept_names to a table
#' @rdname omop_join_name_all
#' @export
#' @examples
#' data.frame(concept_id=(c(3571338L,3655355L)),
#'            drug_concept_id=(c(4000794L,35628998L))) |>
#'            ojoinall()
ojoinall <- omop_join_name_all
