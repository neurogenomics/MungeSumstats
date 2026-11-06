# Bug-fix backports onto MungeSumstats 1.13.4

This branch backports fixes from Al-Murphy/MungeSumstats through 1bbd148 (2 November 2026). It preserves the 1.13.4 function argument names, runtime dependencies and reference-loading API. The `parse_logs()` default filename pattern is corrected to match the files the package writes. It does not include the optional reference cache.

## Scope

- Preserve the existing A1/A2 allele-inference interface. Backport the case handling and allele-name matching fixes without adding A0 inference or `eff_on_minor_alleles`.
- Keep the original OpenGWAS integration. The later `ieugwasr` migration and fixes specific to it are excluded.
- Exclude custom dbSNP archive support and its validation/extraction fixes, including f286888 and f7b6923. Those paths do not exist in 1.13.4.
- Exclude the new liftover `rmv_chr` argument and its #211 fix. Preserve local chain files and improve chain-download fallback through the existing interface.
- Keep the package version, website, workflow files, data mappings and exports unchanged.
- Raise only the testthat minimum in Suggests to 3.1.7, because the upstream regression tests use its mocking API.

## Source fixes

| Upstream commit | Fix |
|---|---|
| [281c715](https://github.com/Al-Murphy/MungeSumstats/commit/281c71599729d0cd136af5dedd501ae294420cd4) | Bug Fix: MT chromosome renamed to MTT in check_chr() (#116, #130, #158) |
| [dcf531d](https://github.com/Al-Murphy/MungeSumstats/commit/dcf531da4d5028afde37ce5cec2544576f3124bf) | Bug Fix: off-reference SNPs not corrected when indels present (#164) |
| [b196b24](https://github.com/Al-Murphy/MungeSumstats/commit/b196b24492f6a68cdc06b2d3a88dfe6ebaecb609) | Bug Fix: check_bp_range() CHR styles and unknown CHR rows (#144, #150) |
| [080e3ac](https://github.com/Al-Murphy/MungeSumstats/commit/080e3acb7abfaffac8188bfbc9687bb677722d33) | Bug Fix: check_no_chr_bp() with pre-loaded rsids (#150) |
| [55bf5b2](https://github.com/Al-Murphy/MungeSumstats/commit/55bf5b23bf6a8dce6a8dcf5b3605ad9153d30650) | Bug Fix: liftover() deleting a gzipped local_chain (#183) |
| [5395be3](https://github.com/Al-Murphy/MungeSumstats/commit/5395be394d21010ada7a4e864f716bdf9d25cfe8) | Bug Fix: write_sumstats() VCF output paths (#216) |
| [91467fd](https://github.com/Al-Murphy/MungeSumstats/commit/91467fd24792ec6a66d95f51a04c60dccffe1e18) | Bug Fix: suffix rewrites changing directory names (#34, #84) |
| [9f2ec34](https://github.com/Al-Murphy/MungeSumstats/commit/9f2ec3475f8a1db6082cb3dfde34bd264b067092) | Bug Fix: logging sinks, connections and appending (#207, #80) |
| [8bad6d8](https://github.com/Al-Murphy/MungeSumstats/commit/8bad6d856321761f43d0dbc72f159716b4dd1286) | Bug Fix: global sumstats_return used for previously formatted file (#24) |
| [5072bd4](https://github.com/Al-Murphy/MungeSumstats/commit/5072bd49885bf9b0c162b8c09ca0ccd62daf94d7) | Bug Fix: parse_logs() default pattern (#68) |
| [3ced25e](https://github.com/Al-Murphy/MungeSumstats/commit/3ced25ef5e7ea34354f28f5f144fabcb0fc0df2c) | Bug Fix: file type detection in read_sumstats() (#155, #91, #154) |
| [a4586a5](https://github.com/Al-Murphy/MungeSumstats/commit/a4586a55c164189117675f18839e23d5614cb0ba) | Bug Fix: read_vcf() with nThread>1 (#21) |
| [4b5f2bc](https://github.com/Al-Murphy/MungeSumstats/commit/4b5f2bc5a2ccaae8e5f1b5e5a4ab2fca8f2ad4ed) | Bug Fix: partial argument match in read_vcf_parallel() |
| [3bb94ea](https://github.com/Al-Murphy/MungeSumstats/commit/3bb94ea1f82b93a257a1d1f94b1bd4198bdecd8f) | Bug Fix: IMPUTATION_n not set by compute_nsize() (#43) |
| [1a2a835](https://github.com/Al-Murphy/MungeSumstats/commit/1a2a835ea844445ad14ae60b1a963898abf43850) | Bug Fix: character N with imputation_ind=TRUE (#26) |
| [d19d136](https://github.com/Al-Murphy/MungeSumstats/commit/d19d13617c06fae91da9a83ec91d496070569a40) | Bug Fix: N_dropNA inverted and NA N disabling N_std (#29) |
| [68c1874](https://github.com/Al-Murphy/MungeSumstats/commit/68c1874b34bf52ea8cde25c73a55fbd85dce0712) | Bug Fix: custom mapping_file as data.table or lower case (#174) |
| [8976603](https://github.com/Al-Murphy/MungeSumstats/commit/8976603d2c8c539dbbcc86f914385158b84c1a8f) | Bug Fix: MAF used over allele frequency for FRQ (#142) |
| [022d0c0](https://github.com/Al-Murphy/MungeSumstats/commit/022d0c0acb1b86282d6e9df1496d5e9ff67c3e3b) | Bug Fix: off-reference SNPs dropped by bi-allelic and flip checks (#139, #140) |
| [22737c4](https://github.com/Al-Murphy/MungeSumstats/commit/22737c4013d2657ef75579bb619d807f2434e769) | Bug Fix: indel count missing from message (#139) |
| [b9775ff](https://github.com/Al-Murphy/MungeSumstats/commit/b9775ff6ff4a6f3498a2a01809a4e684a41f23ca) | Bug Fix: check_ldsc_format() message and vector compute_n (#3) |
| [4bd4230](https://github.com/Al-Murphy/MungeSumstats/commit/4bd42300a68a83d509db1a310c66b9ad5d10ddff) | Bug Fix: multi-RSID removal count (#48) |
| [1bbd148](https://github.com/Al-Murphy/MungeSumstats/commit/1bbd148f46eb8c7d41881efdf7c4a460511ad2f9) | Bug Fix: liftover chain-file fallback when a download leaves no file |
| [cfa3b1c](https://github.com/Al-Murphy/MungeSumstats/commit/cfa3b1c43e4e4547f5bef2d0f0f423d572947131) | Bug Fix: impute z-score when p-vals are 0 |
| [29744c6](https://github.com/Al-Murphy/MungeSumstats/commit/29744c6fc140a410504d45b51aec83f9c3ba5fd7) | Bug Fix: NA p-values in check_zscore() (#212) |
| [c37839b](https://github.com/Al-Murphy/MungeSumstats/commit/c37839b398a83a01ebf62dcffd9e6edc7ab1cf6b) | Bug Fix: infer effect allele |
| [8bad1f2](https://github.com/Al-Murphy/MungeSumstats/commit/8bad1f2d1aa27d62a869eb4e61193519107bd22c) | Bug Fix: infer_effect_column() allele naming (#208) |

## Adaptation and validation

The chromosome fix also carries the earlier numeric 24-to-Y correction. The VCF fix incorporates the earlier bgzip correction (5dfb8a6). The logging fix incorporates the error-cleanup setup from f30feb1. Conflicts were resolved against the older API rather than importing newer arguments.

Regression tests are selected from upstream 1bbd148. Calls omit unsupported `dbSNP_tarball` arguments and explicitly supply the older internal `check_chr` arguments. Tests for excluded features are omitted.

Local source parsing and direct checks of mitochondrial/Y chromosome normalization, mixed-case allele direction and zero/NA p-values pass. Full installed-package testing of this backport is pending. Earlier results for upstream 1.21.3 do not validate this adapted code.
