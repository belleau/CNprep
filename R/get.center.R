#' @title Group clusters together until the main cluster contain the
#' minimum required ratio of data.
#' 
#' @description The function groups clusters with the mean value closer to z
#' zero together until the main cluster contain the minimum required ratio 
#' of data, as specified by the user.
#' 
#' @param emfit a \code{list} containing information about the current 
#' clusters obtained from a mixture model estimation:
#' \itemize{
#' \item \code{mu} a \code{numeric} \code{vector} representing the mean 
#'     for each component. If there is more than one component, the 
#'     \emph{k}th element is the mean of the \emph{k}th component of the 
#'     mixture model.
#' \item \code{pro} a \code{vector} whose \emph{k}th component is the mixing 
#'     proportion for the \emph{k}th component of the mixture model. If 
#'     missing, equal proportions are assumed.
#' \item \code{z} a \code{numeric} \code{matrix} whose \emph{[i,k]}th entry 
#'     is the probability that observation \emph{i} in the test data belongs 
#'     to the \emph{k}th class.
#' \item \code{groups} a \code{matrix} with the number of rows corresponding
#'     to the current number of clusters while the number of columns is 
#'     corresponding to the initial number of clusters. The presence of 
#'     \code{1} in position \emph{[i,k]} indicates that the initial 
#'     \emph{i}th cluster is now part of the new \emph{k}th cluster.
#' \item \code{ngroups} a \code{numeric}, used as an integer, giving the final
#'     number of clusters.
#' \item \code{sigmasq}  a \code{numeric} \code{vector} giving the common 
#'     variance for each component in the mixture model "E".
#' }
#' 
#' @param minCenter a single \code{numeric} value between \code{0} and \code{1} 
#' specifying the minimal share of the central cluster in each profile.
#' 
#' @return a \code{list} containing information about the current 
#' clusters obtained from a mixture model estimation:
#' \itemize{
#' \item \code{mu} a \code{numeric} \code{vector} representing the mean 
#'     for each component. If there is more than one component, the 
#'     kth element is the mean of the kth component of the mixture model.
#' \item \code{pro} a \code{vector} whose \emph{k}th component is the mixing 
#'     proportion for the \emph{k}th component of the mixture model. If 
#'     missing, equal proportions are assumed.
#' \item \code{z} a \code{numeric} \code{matrix} whose \emph{[i,k]}th entry 
#'     is the probability that observation \emph{i} in the test data belongs 
#'     to the \emph{k}th class.
#' \item \code{groups} a \code{matrix} with the number of rows corresponding
#'     to the current number of clusters while the number of columns is 
#'     corresponding to the initial number of clusters. The presence of 
#'     \code{1} in position [k,i] indicates that the initial \emph{i}th cluster
#'     is now part of the new \emph{k}th cluster.
#' \item \code{ngroups} a \code{numeric}, used as an integer, giving the final
#'     number of clusters.
#' \item \code{sigmasq}  a \code{numeric} \code{vector} giving the common 
#'     variance for each component in the mixture model "E".
#' \item \code{center} a \code{numeric}, used as an integer, indicating the
#'     cluster that has the mean closest to zero.
#' }
#' 
#' @examples
#'
#' ## Create a list with mixture model estimation data containing 5 clusters
#' demoEM <- list()
#' demoEM[["mu"]] <- c(-0.23626, -0.08108, -0.02205, 0.03059, 0.24482)
#' demoEM[["pro"]] <- rep(0.2, 5)
#' demoEM[["z"]] <- matrix(data=c(1.19e-118, 2.81e-25, 5.87e-08, 9.99e-1,  
#'     1.86e-52, 2.03e-117, 9.19e-25, 1.02e-07, 9.99e-01, 1.92e-53, 1.00e+0, 
#'     1.34e-23, 1.72e-50, 1.08e-82, 6.45e-295, 1.00e+00, 1.39e-20, 2.51e-46, 
#'     1.67e-77, 1.47e-285, 8.86e-63, 1.21e-04, 9.99e-01, 1.89e-05, 7.93e-106,
#'     7.59e-60, 7.76e-04, 9.99e-01, 3.60e-06, 1.75e-109, 0.00e+0, 1.61e-147, 
#'     1.08e-98, 2.31e-63, 1.00e+0, 0.00e+0, 1.18e-147, 8.37e-99, 1.88e-63, 
#'     1.00e+0, 3.51e-75, 9.79e-01, 4.55e-08, 2.06-02, 2.14e-90, 7.07e-79,
#'     8.58e-01, 3.96e-09,  1.41e-01, 6.42e-86), ncol=5, byrow=TRUE)
#' demoEM[["groups"]] <- diag(x=1, nrow=5, ncol=5, names=TRUE)
#' demoEM[["ngroups"]] <- 5
#' demoEM[["sigmasq"]] <- rep(1.533e-3, 5)
#' 
#' ## Group clusters until the minimum proportion of 40% of the data is in
#' ## the main cluster. The main cluster being defined as the one closer to
#' ## a value of zero.
#' result <- CNprep:::get.center(emfit=demoEM, minCenter=0.4)
#' 
#' ## The result contain only 4 clusters as the clusters 3 and 4 have been
#' ## grouped together to form a cluster that includes 40% of the data (group 3)
#' result$ngroups
#' result$pro
#' 
#' @author Alexander Krasnitz, Guoli Sun
#' @keywords internal
get.center <- function(emfit, minCenter) 
{
    #emfit must have come out of consolidate! 
    newem<-list(mu=emfit$mu, pro=emfit$pro, z=emfit$z, 
                    groups=emfit$groups, ngroups=emfit$ngroups, 
                    sigmasq=emfit$sigmasq, center=which.min(abs(emfit$mu)))
    
    while (newem$ngroups > 1) {
        omu <- order(abs(newem$mu))
        if (newem$pro[omu[1]] < minCenter) {
            gl <- min(omu[seq_len(2)])
            gr <- max(omu[seq_len(2)])
            newem$z[,gl] <- newem$z[, gl] + newem$z[, gr]
            newem$z <- newem$z[, -gr, drop=FALSE]
            numu <- (newem$mu[gl] * newem$pro[gl] + 
                            newem$mu[gr] * newem$pro[gr])/
                            (newem$pro[gl] + newem$pro[gr])
            newem$sigmasq[gl] <- (newem$pro[gl] * (newem$sigmasq[gl] + 
                    newem$mu[gl]^2) + newem$pro[gr] * (newem$sigmasq[gr] + 
                                                        newem$mu[gr]^2))/
                    (newem$pro[gl]+newem$pro[gr])-numu^2
            newem$mu[gl] <- numu
            newem$mu <- newem$mu[-gr]
            newem$sigmasq <- newem$sigmasq[-gr]
            newem$pro[gl] <- newem$pro[gl] + newem$pro[gr]
            newem$pro <- newem$pro[-gr]
            newem$groups[gl,] <- newem$groups[gl,] + newem$groups[gr,]
            newem$groups <- newem$groups[-gr, , drop=FALSE]
            newem$ngroups <- newem$ngroups - 1
            newem$center <- gl
        }
        else break
    }
    return(newem)
}
