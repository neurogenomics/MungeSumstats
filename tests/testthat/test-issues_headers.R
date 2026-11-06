# Backported regression tests from Al-Murphy/MungeSumstats 1bbd148.
# Calls use the 1.13.4 API; tests for excluded features are omitted.
hdr_combns <- if (exists("get_eff_frq_allele_combns",
                         envir = asNamespace("MungeSumstats"),
                         inherits = FALSE)) {
    MungeSumstats:::get_eff_frq_allele_combns()
}

std <- function(dt, ...) {
    run <- function() {
        suppressMessages(MungeSumstats::standardise_header(
            sumstats_dt = data.table::copy(dt), return_list = FALSE, ...
        ))
    }
    if (is.null(hdr_combns)) return(run())
    keep <- c(toupper(names(dt)), as.character(unlist(list(...)$mapping_file)),
              MungeSumstats:::sumstatsColHeaders$Corrected,
              hdr_combns$CORRECTED)
    testthat::with_mocked_bindings(
        run(),
        get_eff_frq_allele_combns = function(...) {
            hdr_combns[hdr_combns$UNCORRECTED %in% keep, ]
        },
        .package = "MungeSumstats"
    )
}

test_that("#45/#142: a user-supplied mapping_file is applied", {
    # #45: a stand-alone user map (upper-case Uncorrected, as format_sumstats
    # would pass it)
    m <- data.frame(Uncorrected = c("MYSNP", "MYEFF", "MYREF"),
                    Corrected = c("SNP", "A2", "A1"))
    out <- std(data.table::data.table(mySNP = "rs1", myEff = "T", myRef = "C"),
               mapping_file = m)
    expect_equal(names(out), c("SNP", "A2", "A1"))
    expect_equal(c(out$A2, out$A1), c("T", "C"))
    # #142: a row appended to the default map is honoured
    m <- rbind(MungeSumstats:::sumstatsColHeaders,
               data.frame(Uncorrected = "MY_BP_COL", Corrected = "BP"))
    dt <- data.table::data.table(SNP = "rs1", CHR = 1, MY_BP_COL = 100)
    expect_equal(names(std(dt, mapping_file = m)), c("SNP", "CHR", "BP"))
    expect_equal(names(std(dt)), c("SNP", "CHR", "MY_BP_COL"))
})

test_that("#142: in a full REGENIE header A1FREQ, not MAF, becomes FRQ", {
    dt <- data.table::data.table(
        CHROM = 1L, GENPOS = 8490603L, ID = "rs301800", ALLELE0 = "C",
        ALLELE1 = "T", A1FREQ = 0.18, INFO = 1, N = 1000L, TEST = "ADD",
        BETA = 0.019, SE = 0.003, CHISQ = 30, LOG10P = 7.7, P = 1.8e-8,
        MAF = 0.17
    )
    out <- std(dt)
    expect_equal(out$FRQ, 0.18)
    expect_true("MAF" %in% names(out))
})

test_that("#174/#175: format_sumstats normalises a custom mapping_file", {
    # ~9 s: one reference run plus the two custom-map variants (spec needs all 3)
    skip_if_not_installed("SNPlocs.Hsapiens.dbSNP144.GRCh37")
    skip_if_not_installed("BSgenome.Hsapiens.1000genomes.hs37d5")
    run <- function(...) {
        MungeSumstats::format_sumstats(
            path = system.file("extdata", "eduAttainOkbay.txt",
                               package = "MungeSumstats"),
            ref_genome = "GRCh37", dbSNP = 144, on_ref_genome = FALSE,
            strand_ambig_filter = FALSE, bi_allelic_filter = FALSE,
            allele_flip_check = FALSE, return_data = TRUE, ...
        )
    }
    ref <- suppressMessages(run())
    # lower-case Uncorrected entries in a data.frame are upper-cased
    m_low <- MungeSumstats:::sumstatsColHeaders
    m_low$Uncorrected <- tolower(m_low$Uncorrected)
    msgs <- testthat::capture_messages(res_low <- run(mapping_file = m_low))
    expect_true(any(grepl("Non-standard mapping file detected", msgs)))
    expect_equal(res_low, ref)
    # a data.table mapping file passes validate_parameters and is converted
    m_dt <- data.table::as.data.table(MungeSumstats:::sumstatsColHeaders)
    expect_no_error(res_dt <- suppressMessages(run(mapping_file = m_dt)))
    expect_equal(res_dt, ref)
})

test_that("#174/#175: exported standardise_header normalises a custom mapping_file", {
    dt <- data.table::data.table(snp = "rs1", pval = 0.1)
    m_dt <- data.table::as.data.table(MungeSumstats:::sumstatsColHeaders)
    expect_equal(names(std(dt, mapping_file = m_dt)), c("SNP", "P"))
    m_low <- MungeSumstats:::sumstatsColHeaders
    m_low$Uncorrected <- tolower(m_low$Uncorrected)
    expect_equal(names(std(dt, mapping_file = m_low)), c("SNP", "P"))
})

