#' Inverse Distance Weighting with threshold radius
#'
#' Calculate the inverse distance to all neighbors within distance r of any
#' tract
#'
#' This function uses \code{st_distance} to calculate the distances between all
#' tracts in an sf object, selects the neighbors within radius r (excluding the
#' tract itself), calculates the inverse of the distance + 1 (to avoid dividing
#' by 0), and converts the results into a named list of named lists for use in
#' \code{\link{NP}}.
#'
#' @export
#' @param tracts A spatial object of class \code{sf}
#' @param tracts_ID Character, the name of the ID column in \code{tracts}
#' @param r Number, the maximum threshold within which neighbors are defined
#' @param verbose Logical. Determines whether messages are displayed during processing
#' @return returns a named list of named lists. Each list is named for a tract
#'   in \code{tracts} and contains \code{n} elements. These elements, named for
#'   the \code{n} nearest neighbors, are the inverse of the distance to the
#'   tract plus one.
#' @seealso See \code{\link[sf]{st_distance}} function from package \code{sf}
#' @author Eli Weaverdyck \email{eweaverdyck@@gmail.com}
#' @examples IDW_radius(tracts = tracts, tracts_ID = "UnitID", r = 500)


IDW_radius<-function(tracts, tracts_ID, r, verbose = TRUE){
  checkmate::assert_class(tracts, "sf")
  checkmate::assert_names(tracts_ID, subset.of = names(tracts))
  checkmate::assert_number(r)

  if(verbose == TRUE) message("Calculating distances")
  dist<-sf::st_distance(tracts)
  tracts.df<-tracts
  sf::st_geometry(tracts.df)<-NULL
  colnames(dist)<-tracts.df[, tracts_ID]
  row.names(dist)<-tracts.df[, tracts_ID]
  diag(dist)<-NA

  swm<-matrix(data=NA, nrow=nrow(dist), ncol=ncol(dist))
  colnames(swm)<-colnames(dist)
  row.names(swm)<-row.names(dist)
  if(verbose == TRUE) message(paste("Finding neighbors within",r))
  for(u in tracts.df[,tracts_ID]){
    swm[u,] <- ifelse(
      test=dist[u,]<=units::set_units(r, units(dist), mode="standard"),
      yes=units::set_units(1, units(dist), mode="standard")/(units::set_units(1, units(dist), mode="standard")+dist[u,]),
      no=NA)
  }
  if(verbose == TRUE) message("Converting to list")
  swl<-list()
  length(swl)<-length(sf::st_drop_geometry(tracts)[,tracts_ID])
  names(swl)<-sf::st_drop_geometry(tracts)[,tracts_ID]

  for(u in names(swl)){
    swl[[u]]<-list()
    length(swl[[u]])<-length(which(!is.na(swm[u,])))
    swl[[u]]<-swm[u,which(!is.na(swm[u,]))]
  }
  return(swl)
}
