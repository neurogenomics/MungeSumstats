# Backported regression tests from Al-Murphy/MungeSumstats 1bbd148.
# Calls use the 1.13.4 API; tests for excluded features are omitted.
local_fast_combns <- function(headers, env = parent.frame()) {
    cmb <- MungeSumstats:::get_eff_frq_allele_combns()
    cmb <- cmb[cmb$UNCORRECTED %in% toupper(headers), ]
    testthat::local_mocked_bindings(
        get_eff_frq_allele_combns = function(...) data.table::copy(cmb),
        .package = "MungeSumstats", .env = env
    )
}

local_fake_ref <- function(env = parent.frame()) {
    ref <- data.table::data.table(
        seqnames = "1", pos = c(100L, 200L, 300L),
        SNP = c("rs1", "rs2", "rs3"), ref_allele = c("A", "C", "G")
    )
    ref[, alt_alleles := list(list("G", "T", "A"))]
    testthat::local_mocked_bindings(
        load_ref_genome_data = function(...) data.table::copy(ref),
        .package = "MungeSumstats", .env = env
    )
}

infer <- function(dt, ...) {
    MungeSumstats::infer_effect_column(
        sumstats_dt = data.table::copy(dt), nThread = 1,
        return_list = FALSE, ...
    )
}

test_that("#168: check 2 infers the effect allele from column names", {
    dt <- data.table::data.table(
        SNP = c("rs1", "rs2"), CHR = 1L, BP = c(100L, 200L),
        A1 = c("G", "T"), A2 = c("A", "C"), BETA1 = c(0.1, -0.2),
        P = c(0.01, 0.5)
    )
    dt_frq <- data.table::copy(dt)
    data.table::setnames(dt_frq, "BETA1", "A1FRQ")
    dt_frq[, BETA := c(0.1, -0.2)]
    dt_b2 <- data.table::copy(dt)
    data.table::setnames(dt_b2, "BETA1", "BETA2")
    local_fast_combns(c(names(dt), names(dt_frq), names(dt_b2)))
    # BETA1 / A1FRQ: effect is on A1, so A1/A2 are swapped (A2 = effect)
    expect_message(res <- infer(dt, on_ref_genome = FALSE),
                   "relate to A1 in the sumstat")
    expect_equal(res$A2, c("G", "T"))
    expect_equal(res$A1, c("A", "C"))
    expect_message(res <- infer(dt_frq, on_ref_genome = FALSE),
                   "relate to A1 in the sumstat")
    expect_equal(res$A2, c("G", "T"))
    # BETA2: effect already on A2, nothing swapped
    expect_message(res <- infer(dt_b2, on_ref_genome = FALSE),
                   "relate to A2 in the sumstat")
    expect_equal(res$A1, c("G", "T"))
    expect_equal(res$A2, c("A", "C"))
    # opt-out leaves the data untouched
    expect_no_message(
        res <- infer(dt, on_ref_genome = FALSE, infer_eff_direction = FALSE)
    )
    expect_equal(res, dt)
    # unambiguous allele headers are never re-inferred
    dt_un <- data.table::copy(dt)
    data.table::setnames(dt_un, c("A1", "A2"),
                         c("NON_EFFECT_ALLELE", "EFFECT_ALLELE"))
    expect_no_message(res <- infer(dt_un, on_ref_genome = FALSE),
                      message = "ambiguous")
    expect_equal(res, dt_un)
    # ambiguous alleles, plain BETA and no reference check: left as is
    dt_amb <- data.table::copy(dt)
    data.table::setnames(dt_amb, "BETA1", "BETA")
    expect_message(res <- infer(dt_amb, on_ref_genome = FALSE),
                   "Can't infer allele columns from sumstats")
    expect_equal(res, dt_amb)
})

test_that("#186: EA/OA allele headers are not treated as ambiguous", {
    input <- data.table::data.table(
        RSID = c("rs1", "rs2"), BETA = c(-0.013, 0.007), SE = c(0.106, 0.10),
        CHISQ = c(0.04, 0.03), P = c(0.77, 0.88), EA = c("A", "T"),
        OA = c("T", "A"), LOG10P = c(0.12, 0.05)
    )
    expect_no_message(res <- infer(input, on_ref_genome = FALSE),
                      message = "ambiguous")
    expect_equal(res, input)
})

test_that("#188/#208: check 3 makes the reference allele the non-effect A1", {
    ss <- data.table::data.table(
        SNP = c("rs1", "rs2", "rs3"), CHR = 1L, BP = c(100L, 200L, 300L),
        Allele1 = c("A", "C", "G"), Allele2 = c("G", "T", "A"),
        FRQ = c(0.1, 0.2, 0.3), BETA = c(0.1, -0.2, 0.3), SE = 0.01, P = 0.5
    )
    local_fast_combns(names(ss))
    local_fake_ref()
    # Allele1 matches the reference: already A1 = non-effect, no swap
    expect_message(out <- infer(ss, ref_genome = "GRCh37", dbSNP = 144),
                   "relate to A2 in the inputted sumstats")
    expect_equal(names(out), names(ss))
    expect_equal(out$Allele1, ss$Allele1)
    # Allele2 matches the reference: swap so A2 holds the effect allele
    # (#188: the direction of this decision used to be inverted)
    ss_sw <- data.table::copy(ss)
    ss_sw[, c("Allele1", "Allele2") := list(Allele2, Allele1)]
    expect_message(out <- infer(ss_sw, ref_genome = "GRCh37", dbSNP = 144),
                   "relate to A1 in the inputted sumstats")
    expect_equal(out$A2, c("G", "T", "A"))
    expect_equal(out$A1, c("A", "C", "G"))
    # #208: lower-case alleles must still match the reference
    ss_lc <- data.table::copy(ss_sw)
    ss_lc[, c("Allele1", "Allele2") := list(tolower(Allele1),
                                            tolower(Allele2))]
    expect_message(out <- infer(ss_lc, ref_genome = "GRCh37", dbSNP = 144),
                   "relate to A1 in the inputted sumstats")
    expect_equal(out$A2, c("g", "t", "a"))
    expect_equal(out$A1, c("a", "c", "g"))
})

test_that("#208: raw METAL headers (Freq1) mark Allele1 as the effect", {
    x <- data.table::data.table(
        Chr = 1L, Pos_b37 = c(693731L, 723891L),
        RSID = c("rs12238997", "rs2977670"), Allele1 = c("a", "c"),
        Allele2 = c("g", "g"), Freq1 = c(0.87, 0.86),
        Effect = c(0.0088, -0.0388), StdErr = c(0.0196, 0.0393),
        "P-value" = c(0.6531, 0.3236), n_total_sum = c(334575L, 119680L)
    )
    local_fast_combns(names(x))
    # METAL: Allele1 is the effect allele and Freq1 is its frequency
    expect_message(out <- infer(x, ref_genome = "GRCh37",
                                on_ref_genome = FALSE),
                   "relate to A1 in the sumstat")
    expect_equal(out$A2, c("a", "c"))
    expect_equal(out$A1, c("g", "g"))
})

