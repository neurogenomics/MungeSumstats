# Backported regression tests from Al-Murphy/MungeSumstats 1bbd148.
# Calls use the 1.13.4 API; tests for excluded features are omitted.
fresh_chain <- function(f = "GRCh37_to_GRCh38.chain.gz", gunzip = FALSE) {
    d <- tempfile("chain_")
    dir.create(d)
    p <- file.path(d, f)
    file.copy(system.file("extdata", f, package = "MungeSumstats"), p)
    if (gunzip) p <- as.character(R.utils::gunzip(p))
    stopifnot(file.exists(p))
    p
}

edu_dt <- function() {
    dt <- data.table::fread(
        system.file("extdata", "eduAttainOkbay.txt", package = "MungeSumstats"),
        nThread = 1
    )
    data.table::setnames(dt, c("MarkerName", "POS", "EAF", "Beta", "Pval"),
                         c("SNP", "BP", "FRQ", "BETA", "P"))
    dt[, CHR := as.character(CHR)]
    dt
}

no_downloads <- function(env = parent.frame()) {
    testthat::local_mocked_bindings(
        messager = function(..., v = TRUE) {
            msg <- paste(...)
            if (grepl("Downloading", msg)) stop("Download attempted: ", msg)
            if (v) message(msg)
        },
        .package = "MungeSumstats", .env = env
    )
}

lift_msgs <- function(...) {
    out <- NULL
    msgs <- testthat::capture_messages(out <- MungeSumstats::liftover(...))
    list(out = out, msgs = msgs)
}

test_that("get_chain_file uses the bundled chain when a download fails", {
    # A failed download can leave no file behind (Bioc nebbiolo2 vignette
    # build, 2026-10-29); the bundled Ensembl chain must still be used.
    # A missing file:// path makes the download fail without the network.
    real_ens <- MungeSumstats:::.get_ensembl_chain_remote
    real_ucsc <- MungeSumstats:::.get_ucsc_chain_remote
    missing_url <- function(remote) {
        paste0("file://", tempfile("no_such_dir_"), "/", basename(remote))
    }
    local_mocked_bindings(
        .get_ensembl_chain_remote = function(from, to)
            missing_url(real_ens(from, to)),
        .get_ucsc_chain_remote = function(from, to)
            missing_url(real_ucsc(from, to))
    )
    # precondition: this failure leaves nothing to clean up or copy over
    dest <- tempfile(fileext = ".chain.gz")
    try(suppressWarnings(utils::download.file(
        MungeSumstats:::.get_ensembl_chain_remote("hg19", "hg38"), dest,
        quiet = TRUE)), silent = TRUE)
    expect_false(file.exists(dest))
    save_dir <- tempfile("chain_")
    dir.create(save_dir)
    msgs <- capture_messages(suppressWarnings(
        ch <- MungeSumstats:::get_chain_file(from = "hg19", to = "hg38",
                                             chain_source = "ensembl",
                                             save_dir = save_dir)
    ))
    expect_true(any(grepl("failed, using ensembl chain file", msgs)))
    expect_s4_class(ch, "Chain")
    expect_gt(length(ch), 0)
    expect_true(file.exists(file.path(save_dir, "GRCh37_to_GRCh38.chain")))
    # UCSC has no bundled chain: a clear error, not a gunzip failure
    expect_error(
        suppressWarnings(suppressMessages(MungeSumstats:::get_chain_file(
            from = "hg19", to = "hg38", chain_source = "ucsc",
            save_dir = save_dir))),
        "Download of chain file from UCSC Genome Browser failed"
    )
})

test_that("#84/#128: get_chain_file uses an existing chain, no download", {
    no_downloads()
    ens <- fresh_chain(gunzip = TRUE)
    # see the known issue below: a temp path with "<char>gz" in it would
    # hide the cached file
    skip_if(grepl(".gz", dirname(ens)), "temp path matches '.gz'")
    msgs <- testthat::capture_messages(
        ch <- MungeSumstats:::get_chain_file(from = "hg19", to = "hg38",
                                             chain_source = "ensembl",
                                             save_dir = dirname(ens))
    )
    expect_true(any(grepl("Using existing chain file", msgs)))
    expect_false(any(grepl("Downloading", msgs)))
    expect_s4_class(ch, "Chain")
    expect_gt(length(ch), 0)
    # UCSC chains carry a commercial-use licence warning
    ucsc_dir <- tempfile("ucsc_")
    dir.create(ucsc_dir)
    stopifnot(file.copy(ens, file.path(ucsc_dir, "hg19ToHg38.over.chain")))
    msgs <- testthat::capture_messages(
        MungeSumstats:::get_chain_file(from = "hg19", to = "hg38",
                                       chain_source = "ucsc",
                                       save_dir = ucsc_dir)
    )
    expect_true(any(grepl("licence for commercial use", msgs)))
    expect_false(any(grepl("Downloading", msgs)))
})

test_that("#84: get_chain_file finds a cached chain in any save_dir", {
    no_downloads()
    save_dir <- file.path(tempfile("chain_"), "gwas_gz_files")
    dir.create(save_dir, recursive = TRUE)
    stopifnot(file.copy(fresh_chain(gunzip = TRUE),
                        file.path(save_dir, "GRCh37_to_GRCh38.chain")))
    expect_message(
        ch <- MungeSumstats:::get_chain_file(from = "hg19", to = "hg38",
                                             chain_source = "ensembl",
                                             save_dir = save_dir),
        "Using existing chain file"
    )
    expect_s4_class(ch, "Chain")
})

test_that("#183/#184/#197: local_chain .gz is kept, reusable; extra cols", {
    no_downloads()
    dt <- edu_dt()
    dt[, ROW_NUMBER := .I]
    dt[, ANNOTATION := paste0("a", .I)]
    chain_gz <- fresh_chain()
    lift <- function() {
        lift_msgs(sumstats_dt = data.table::copy(dt), ref_genome = "hg19",
                  convert_ref_genome = "hg38", local_chain = chain_gz)
    }
    res1 <- lift()
    expect_true(any(grepl("Using local chain file", res1$msgs)))
    expect_false(any(grepl("Downloading", res1$msgs)))
    out1 <- res1$out
    expect_equal(nrow(out1), nrow(dt))
    expect_setequal(out1$SNP, dt$SNP)
    expect_true(all(out1[order(SNP)]$BP != dt[order(SNP)]$BP))
    expect_true("IMPUTATION_gen_build" %in% names(out1))
    # #197: user columns travel with their rows
    expect_equal(out1[order(SNP)]$ROW_NUMBER, dt[order(SNP)]$ROW_NUMBER)
    expect_equal(out1[order(SNP)]$ANNOTATION, dt[order(SNP)]$ANNOTATION)
    # #183: the user's .gz survives and can be used again
    expect_true(file.exists(chain_gz))
    expect_identical(lift()$out, out1)
    expect_error(MungeSumstats::liftover(sumstats_dt = data.table::copy(dt),
                                         ref_genome = "hg19",
                                         convert_ref_genome = "hg38",
                                         local_chain = tempfile()),
                 "local_chain parameter is invalid")
})

