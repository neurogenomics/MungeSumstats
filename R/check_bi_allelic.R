#' Remove non-biallelic SNPs
#'
#' @param sumstats_file The summary statistics file for the GWAS
#' @param path Filepath for the summary statistics file to be formatted
#' @param ref_genome name of the reference genome used for the GWAS (GRCh37 or GRCh38). Default is GRCh37.
#' @param bi_allelic_filter Binary Should non-biallelic SNPs be removed. Default is TRUE
#' @param rsids datatable of snpsById, filtered to SNPs of interest if loaded already. Or else NULL
#' @return The modified sumstats_file
#' @importFrom data.table setDT
#' @importFrom data.table setkey
#' @importFrom data.table :=
#' @importFrom data.table copy
#' @importFrom Biostrings IUPAC_CODE_MAP
check_bi_allelic <- 
  function(sumstats_file, path, ref_genome, bi_allelic_filter, rsids){
    CHR = alleles_as_ambig = SNP = NULL
    # If SNP present and user specified to remove
    col_headers <- names(sumstats_file)
    if("SNP" %in% col_headers && !isFALSE(bi_allelic_filter)){
      if(is.null(rsids)){
        rsids <- load_ref_genome_data(copy(sumstats_file$SNP), ref_genome)
        #Save to parent environment so don't have to load again
        assign("rsids", rsids, envir = parent.frame())
      }
      #get chars for SNPs not bi/tri allelic or strand ambig from IUPAC_CODE_MAP
      nonambig_IUPAC_CODE_MAP <- 
        names(Biostrings::IUPAC_CODE_MAP[nchar(Biostrings::IUPAC_CODE_MAP)<3])
      num_bad_ids <- nrow(rsids[!alleles_as_ambig %in% nonambig_IUPAC_CODE_MAP])
      #check for SNPs not on ref genome
      if(num_bad_ids>0){
        msg <- paste0(num_bad_ids, " SNPs are non-biallelic. ",
                      " These will be removed")
        message(msg)
        # join using SNP
        data.table::setkey(sumstats_file,SNP)
        keep_snps <- rsids[alleles_as_ambig %in% nonambig_IUPAC_CODE_MAP]$SNP
        #remove rows missing from the reference genome
        sumstats_file <- sumstats_file[keep_snps,]
      }
      return(sumstats_file)
    }
    else{
      return(sumstats_file)
    }
  }