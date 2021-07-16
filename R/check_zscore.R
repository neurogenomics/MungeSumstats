#' Check for Z-score column
#' 
#' The following ensures that a Z-score column is present.
#' The Z-score formula we used here is a R implementation of the formula
#' used in \href{https://github.com/bulik/ldsc/blob/aa33296abac9569a6422ee6ba7eb4b902422cc74/munge_sumstats.py#L363}{LDSC's munge_sumstats.py}: 
#' 
#' \code{np.sqrt(chi2.isf(P, 1))} 
#' 
#' The R implementation is adapted from the \code{GenomicSEM::munge} function, 
#' after optimizing for speed using \code{data.table}: 
#' 
#' \code{sumstats_dt[,Z:=sign(BETA)*sqrt(stats::qchisq(P,1,lower=FALSE))]} 
#' 
#' \emph{NOTE}: \code{compute_z} is set to \code{TRUE} by default to ensure standardisation
#' of the "Z" column (which can be computed differently in different datasets).
#' 
#' @return \code{list("sumstats_dt"=sumstats_dt)}
#' 
#' @param sumstats_dt data table obj of the summary statistics file for the GWAS.
#' @param compute_z Whether to include/compute Z-score in \code{sumstats_dt}.
#' @param force_new Z-score will be computed from "P" by default (\code{TRUE}).
#' To use an existing Z column instead, set to \code{FALSE}. 
#' @param standardise_headers Run \code{standardise_sumstats_column_headers_crossplatform} first.  
#' 
#' @keywords internal
#' @importFrom stats qchisq
#' @examples 
#' path <- system.file("extdata","eduAttainOkbay.txt", package="MungeSumstats")
#' sumstats_dt <- MungeSumstats::read_sumstats(path = path)
#' sumstats_return <- check_zscore(sumstats_dt=sumstats_dt, 
#'                                 standardise_headers=TRUE)
check_zscore <- function(sumstats_dt,  
                         compute_z=TRUE,
                         force_new=TRUE,
                         standardise_headers=FALSE){ 
    ## Set variables to be used in inplace data.table functions to NULL 
    ## to avoid confusing BiocCheck.
    Z = BETA = P = NULL;
    
    if(standardise_headers){
        sumstats_dt <- standardise_sumstats_column_headers_crossplatform(sumstats_dt = sumstats_dt)[["sumstats_dt"]]
    }
    
    if(compute_z){
        # message("Checking Z-score.") 
        col_headers <- names(sumstats_dt)
        if("Z" %in% col_headers && (!force_new)){
            message("Keeping existing Z-score column.") 
        } else{
            message("Computing Z-score from P using formula: `sign(BETA)*sqrt(stats::qchisq(P,1,lower=FALSE)`")
            sumstats_dt[,Z:=sign(BETA)*sqrt(stats::qchisq(P,1,lower=FALSE))] 
        }
    } 
    return(list("sumstats_dt"=sumstats_dt))
}