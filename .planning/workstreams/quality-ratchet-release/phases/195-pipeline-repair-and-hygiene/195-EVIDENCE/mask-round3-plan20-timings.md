# Plan 195-20: bounded masking evidence

Code ref: fix/secret-mask-structural. Code head: 8c519bfff50ef46eb62c58ae140eb68f9b6130b7. Plan base: b0233b8e29f0465dd158ec67732a97145cdf635d. Origin/main base: 7621c0ce0c38edec76cc54209eccf5acf40feddf.

## Verification

- Committed-head masking file: 181/181, 28686.685 ms.
- Committed-head full JavaScript suite: 318/318, 32695.886 ms.
- Live workflow census: 94 reference-bearing lines; 30 secret-bound aliases across files; 2 derived assignments; 0 violations.
- Required stdout/rejected-context/reference TAP families: 3; zero-selection and all 3 omitted-family controls rejected.
- Raw-window controls: line cap, byte cap, removed mask, empty inventory and all 3 omitted groups rejected; deliberate byte-cut fragment was visible before masking.
- Isolated quadratic copy rejected by the 2000 ms child deadline.

## Independent timing rows

Each row runs in an isolated child, accepts input on stdin, uses a fresh minimum of three equal-length plain-prose samples and the fastest of three candidate samples, and requires candidate <= max(250 ms, 10 times baseline). Each child has a 2000 ms deadline; each named group has a 55000 ms budget. Values below are milliseconds, rounded to three decimals only for reporting. 202 rows; 18 advisory alerts above 25 ms; maximum candidate 61.568 ms. No row exceeded its bound. The 250 ms floor does not detect every possible bounded-window constant regression.

| Row | Input units | Baseline ms | Candidate ms | Bound ms | Advisory >25 ms |
|---|---:|---:|---:|---:|---|
| token/space/10000 | 10007 | 0.390 | 0.239 | 250.000 | no |
| token/space/20000 | 20007 | 0.810 | 0.402 | 250.000 | no |
| token/space/40000 | 40007 | 1.425 | 0.707 | 250.000 | no |
| token/space/200000 | 200007 | 7.105 | 3.679 | 250.000 | no |
| token/tab/10000 | 10007 | 0.454 | 0.276 | 250.000 | no |
| token/tab/20000 | 20007 | 0.756 | 0.439 | 250.000 | no |
| token/tab/40000 | 40007 | 1.586 | 0.854 | 250.000 | no |
| token/tab/200000 | 200007 | 7.817 | 4.047 | 250.000 | no |
| token/mixed/10000 | 10007 | 0.424 | 0.333 | 250.000 | no |
| token/mixed/20000 | 20007 | 0.831 | 0.515 | 250.000 | no |
| token/mixed/40000 | 40007 | 1.808 | 0.939 | 250.000 | no |
| token/mixed/200000 | 200007 | 7.514 | 3.927 | 250.000 | no |
| authorization/space/10000 | 10015 | 0.509 | 0.239 | 250.000 | no |
| authorization/space/20000 | 20015 | 0.699 | 0.511 | 250.000 | no |
| authorization/space/40000 | 40015 | 1.970 | 0.869 | 250.000 | no |
| authorization/space/200000 | 200015 | 7.866 | 3.500 | 250.000 | no |
| authorization/tab/10000 | 10015 | 0.586 | 0.269 | 250.000 | no |
| authorization/tab/20000 | 20015 | 0.793 | 0.431 | 250.000 | no |
| authorization/tab/40000 | 40015 | 1.462 | 0.787 | 250.000 | no |
| authorization/tab/200000 | 200015 | 8.110 | 3.677 | 250.000 | no |
| authorization/mixed/10000 | 10015 | 0.434 | 0.275 | 250.000 | no |
| authorization/mixed/20000 | 20015 | 0.847 | 0.457 | 250.000 | no |
| authorization/mixed/40000 | 40015 | 1.550 | 0.706 | 250.000 | no |
| authorization/mixed/200000 | 200015 | 7.377 | 4.052 | 250.000 | no |
| cookie/space/10000 | 10008 | 0.478 | 0.266 | 250.000 | no |
| cookie/space/20000 | 20008 | 1.029 | 0.421 | 250.000 | no |
| cookie/space/40000 | 40008 | 1.707 | 0.713 | 250.000 | no |
| cookie/space/200000 | 200008 | 7.479 | 3.571 | 250.000 | no |
| cookie/tab/10000 | 10008 | 0.459 | 0.247 | 250.000 | no |
| cookie/tab/20000 | 20008 | 1.039 | 0.452 | 250.000 | no |
| cookie/tab/40000 | 40008 | 1.510 | 0.795 | 250.000 | no |
| cookie/tab/200000 | 200008 | 7.276 | 3.457 | 250.000 | no |
| cookie/mixed/10000 | 10008 | 0.432 | 0.252 | 250.000 | no |
| cookie/mixed/20000 | 20008 | 0.791 | 0.450 | 250.000 | no |
| cookie/mixed/40000 | 40008 | 1.717 | 0.798 | 250.000 | no |
| cookie/mixed/200000 | 200008 | 7.331 | 3.500 | 250.000 | no |
| generic/space/10000 | 10010 | 0.423 | 0.273 | 250.000 | no |
| generic/space/20000 | 20010 | 0.728 | 0.425 | 250.000 | no |
| generic/space/40000 | 40010 | 1.581 | 0.922 | 250.000 | no |
| generic/space/200000 | 200010 | 8.772 | 3.559 | 250.000 | no |
| generic/tab/10000 | 10010 | 0.495 | 0.318 | 250.000 | no |
| generic/tab/20000 | 20010 | 0.758 | 0.471 | 250.000 | no |
| generic/tab/40000 | 40010 | 1.650 | 0.890 | 250.000 | no |
| generic/tab/200000 | 200010 | 6.849 | 3.898 | 250.000 | no |
| generic/mixed/10000 | 10010 | 0.500 | 0.283 | 250.000 | no |
| generic/mixed/20000 | 20010 | 0.815 | 0.508 | 250.000 | no |
| generic/mixed/40000 | 40010 | 1.665 | 0.846 | 250.000 | no |
| generic/mixed/200000 | 200010 | 7.279 | 3.992 | 250.000 | no |
| secret_access_key/space/10000 | 10017 | 0.429 | 0.224 | 250.000 | no |
| secret_access_key/space/20000 | 20017 | 0.802 | 0.404 | 250.000 | no |
| secret_access_key/space/40000 | 40017 | 1.580 | 0.762 | 250.000 | no |
| secret_access_key/space/200000 | 200017 | 6.669 | 3.526 | 250.000 | no |
| secret_access_key/tab/10000 | 10017 | 0.394 | 0.248 | 250.000 | no |
| secret_access_key/tab/20000 | 20017 | 0.843 | 0.448 | 250.000 | no |
| secret_access_key/tab/40000 | 40017 | 1.562 | 0.755 | 250.000 | no |
| secret_access_key/tab/200000 | 200017 | 8.499 | 3.890 | 250.000 | no |
| secret_access_key/mixed/10000 | 10017 | 0.415 | 0.236 | 250.000 | no |
| secret_access_key/mixed/20000 | 20017 | 0.750 | 0.432 | 250.000 | no |
| secret_access_key/mixed/40000 | 40017 | 1.720 | 0.665 | 250.000 | no |
| secret_access_key/mixed/200000 | 200017 | 8.996 | 3.492 | 250.000 | no |
| armor/repeated-begin | 190004 | 7.930 | 2.932 | 250.000 | no |
| armor/missing-end | 200038 | 6.324 | 2.318 | 250.000 | no |
| armor/mixed-prefix-escape | 165000 | 7.080 | 3.532 | 250.000 | no |
| plain_baseline | 220000 | 7.319 | 13.447 | 250.000 | no |
| blank_lines | 200000 | 7.521 | 29.847 | 250.000 | yes |
| whitespace_lines | 300000 | 10.412 | 21.550 | 250.000 | no |
| keyword_no_separator | 600000 | 24.693 | 24.345 | 250.000 | no |
| unterminated_quote | 400012 | 20.196 | 4.387 | 250.000 | no |
| userinfo_no_at | 200008 | 8.346 | 61.568 | 250.000 | yes |
| jwt_segments | 900000 | 39.814 | 24.783 | 398.137 | no |
| jwt_hyphen_run | 200000 | 6.682 | 4.289 | 250.000 | no |
| escaped_key_repeat | 390000 | 17.200 | 30.239 | 250.000 | yes |
| escaped_value_backslashes | 200016 | 7.327 | 4.389 | 250.000 | no |
| tuple_comma_repeat | 270000 | 15.004 | 4.482 | 250.000 | no |
| cli_flag_repeat | 330000 | 14.781 | 26.283 | 250.000 | yes |
| curl_user_repeat | 250000 | 8.658 | 38.824 | 250.000 | yes |
| nextline_keys | 300000 | 13.720 | 32.065 | 250.000 | yes |
| bearer_quote_unterminated | 400008 | 20.298 | 29.549 | 250.000 | yes |
| double_equals_repeat | 320000 | 12.497 | 2.837 | 250.000 | no |
| sk_dash_run | 200003 | 8.691 | 4.206 | 250.000 | no |
| xox_repeat | 200000 | 7.596 | 4.766 | 250.000 | no |
| pem_body_no_end | 200027 | 9.891 | 11.964 | 250.000 | no |
| pem_begin_repeat | 216000 | 8.611 | 3.382 | 250.000 | no |
| pem_escaped_run | 210027 | 8.974 | 2.159 | 250.000 | no |
| userinfo_repeated_scheme | 250000 | 9.072 | 40.538 | 250.000 | yes |
| query_key_repeat | 250000 | 10.770 | 34.917 | 250.000 | yes |
| akia_run | 200000 | 8.868 | 5.382 | 250.000 | no |
| backslash_run | 200012 | 8.195 | 1.313 | 250.000 | no |
| doubled_quotes | 200011 | 8.277 | 3.479 | 250.000 | no |
| escaped_quote_run | 200012 | 9.187 | 1.133 | 250.000 | no |
| mixed_quotes | 210012 | 8.383 | 3.607 | 250.000 | no |
| literal_exemption_repeat | 220000 | 8.469 | 2.710 | 250.000 | no |
| rule/nextline | 300000 | 12.271 | 27.468 | 250.000 | yes |
| rule/armor | 216000 | 9.375 | 2.382 | 250.000 | no |
| rule/name_value | 390000 | 16.273 | 27.250 | 250.000 | yes |
| rule/tuple | 270000 | 13.628 | 3.930 | 250.000 | no |
| rule/structural | 320000 | 12.132 | 3.154 | 250.000 | no |
| rule/authorization | 600000 | 26.178 | 24.476 | 261.783 | no |
| rule/cookie | 300000 | 11.053 | 30.417 | 250.000 | yes |
| rule/bearer | 400008 | 15.646 | 21.293 | 250.000 | no |
| rule/secret_access_key | 300000 | 11.304 | 25.418 | 250.000 | yes |
| rule/github | 200000 | 7.602 | 4.752 | 250.000 | no |
| rule/hex | 200012 | 7.186 | 1.422 | 250.000 | no |
| rule/sk | 200003 | 8.549 | 4.377 | 250.000 | no |
| rule/slack | 200000 | 7.281 | 4.474 | 250.000 | no |
| rule/npm | 330000 | 13.313 | 22.158 | 250.000 | no |
| rule/userinfo | 250000 | 12.146 | 39.654 | 250.000 | yes |
| rule/jwt | 200000 | 7.018 | 4.238 | 250.000 | no |
| rule/aws | 200000 | 7.793 | 5.303 | 250.000 | no |
| rule/query | 250000 | 10.107 | 37.786 | 250.000 | yes |
| rule/cli | 330000 | 12.000 | 20.687 | 250.000 | no |
| rule/curl | 250000 | 10.554 | 44.020 | 250.000 | yes |
| rule/generic | 220000 | 9.670 | 2.758 | 250.000 | no |
| separator/token/1/colon/space | 200007 | 6.643 | 3.516 | 250.000 | no |
| separator/token/1/colon/tab | 200007 | 6.575 | 4.182 | 250.000 | no |
| separator/token/1/colon/mixed | 200007 | 7.624 | 3.960 | 250.000 | no |
| separator/token/1/equals/space | 200007 | 7.782 | 3.891 | 250.000 | no |
| separator/token/1/equals/tab | 200007 | 7.856 | 3.866 | 250.000 | no |
| separator/token/1/equals/mixed | 200007 | 7.154 | 4.255 | 250.000 | no |
| separator/token/2/arrow/space | 200008 | 7.536 | 4.497 | 250.000 | no |
| separator/token/2/arrow/tab | 200008 | 7.315 | 4.409 | 250.000 | no |
| separator/token/2/arrow/mixed | 200008 | 7.798 | 4.621 | 250.000 | no |
| separator/token/2/equals/space | 200008 | 7.859 | 3.376 | 250.000 | no |
| separator/token/2/equals/tab | 200008 | 7.091 | 3.398 | 250.000 | no |
| separator/token/2/equals/mixed | 200008 | 7.343 | 3.684 | 250.000 | no |
| separator/token/3/equals/space | 200009 | 6.965 | 3.351 | 250.000 | no |
| separator/token/3/equals/tab | 200009 | 7.065 | 3.649 | 250.000 | no |
| separator/token/3/equals/mixed | 200009 | 8.157 | 3.586 | 250.000 | no |
| separator/Authorization/1/colon/space | 200015 | 7.766 | 3.372 | 250.000 | no |
| separator/Authorization/1/colon/tab | 200015 | 6.681 | 3.956 | 250.000 | no |
| separator/Authorization/1/colon/mixed | 200015 | 6.873 | 3.795 | 250.000 | no |
| separator/Authorization/1/equals/space | 200015 | 7.670 | 3.436 | 250.000 | no |
| separator/Authorization/1/equals/tab | 200015 | 7.158 | 3.649 | 250.000 | no |
| separator/Authorization/1/equals/mixed | 200015 | 7.956 | 4.395 | 250.000 | no |
| separator/Authorization/2/arrow/space | 200016 | 7.445 | 2.564 | 250.000 | no |
| separator/Authorization/2/arrow/tab | 200016 | 8.004 | 3.114 | 250.000 | no |
| separator/Authorization/2/arrow/mixed | 200016 | 7.088 | 2.913 | 250.000 | no |
| separator/Authorization/2/equals/space | 200016 | 8.081 | 2.114 | 250.000 | no |
| separator/Authorization/2/equals/tab | 200016 | 6.865 | 2.234 | 250.000 | no |
| separator/Authorization/2/equals/mixed | 200016 | 7.379 | 1.920 | 250.000 | no |
| separator/Authorization/3/equals/space | 200017 | 8.764 | 2.071 | 250.000 | no |
| separator/Authorization/3/equals/tab | 200017 | 8.262 | 1.996 | 250.000 | no |
| separator/Authorization/3/equals/mixed | 200017 | 9.079 | 2.313 | 250.000 | no |
| separator/Cookie/1/colon/space | 200008 | 7.633 | 3.579 | 250.000 | no |
| separator/Cookie/1/colon/tab | 200008 | 8.372 | 3.586 | 250.000 | no |
| separator/Cookie/1/colon/mixed | 200008 | 7.996 | 3.894 | 250.000 | no |
| separator/Cookie/1/equals/space | 200008 | 8.311 | 3.412 | 250.000 | no |
| separator/Cookie/1/equals/tab | 200008 | 8.495 | 3.774 | 250.000 | no |
| separator/Cookie/1/equals/mixed | 200008 | 9.955 | 3.651 | 250.000 | no |
| separator/Cookie/2/arrow/space | 200009 | 8.624 | 3.928 | 250.000 | no |
| separator/Cookie/2/arrow/tab | 200009 | 7.172 | 4.457 | 250.000 | no |
| separator/Cookie/2/arrow/mixed | 200009 | 9.409 | 4.072 | 250.000 | no |
| separator/Cookie/2/equals/space | 200009 | 8.712 | 3.534 | 250.000 | no |
| separator/Cookie/2/equals/tab | 200009 | 8.743 | 3.682 | 250.000 | no |
| separator/Cookie/2/equals/mixed | 200009 | 6.940 | 3.653 | 250.000 | no |
| separator/Cookie/3/equals/space | 200010 | 7.614 | 3.216 | 250.000 | no |
| separator/Cookie/3/equals/tab | 200010 | 8.523 | 3.454 | 250.000 | no |
| separator/Cookie/3/equals/mixed | 200010 | 6.729 | 3.301 | 250.000 | no |
| separator/password/1/colon/space | 200010 | 7.158 | 3.443 | 250.000 | no |
| separator/password/1/colon/tab | 200010 | 8.243 | 4.080 | 250.000 | no |
| separator/password/1/colon/mixed | 200010 | 6.611 | 4.011 | 250.000 | no |
| separator/password/1/equals/space | 200010 | 9.183 | 3.450 | 250.000 | no |
| separator/password/1/equals/tab | 200010 | 7.803 | 3.573 | 250.000 | no |
| separator/password/1/equals/mixed | 200010 | 6.769 | 3.602 | 250.000 | no |
| separator/password/2/arrow/space | 200011 | 8.252 | 4.407 | 250.000 | no |
| separator/password/2/arrow/tab | 200011 | 6.746 | 4.255 | 250.000 | no |
| separator/password/2/arrow/mixed | 200011 | 8.832 | 4.211 | 250.000 | no |
| separator/password/2/equals/space | 200011 | 8.070 | 3.247 | 250.000 | no |
| separator/password/2/equals/tab | 200011 | 7.805 | 3.682 | 250.000 | no |
| separator/password/2/equals/mixed | 200011 | 7.794 | 4.006 | 250.000 | no |
| separator/password/3/equals/space | 200012 | 8.194 | 3.453 | 250.000 | no |
| separator/password/3/equals/tab | 200012 | 7.318 | 4.082 | 250.000 | no |
| separator/password/3/equals/mixed | 200012 | 7.294 | 4.248 | 250.000 | no |
| separator/SecretAccessKey/1/colon/space | 200017 | 7.553 | 3.398 | 250.000 | no |
| separator/SecretAccessKey/1/colon/tab | 200017 | 8.242 | 3.844 | 250.000 | no |
| separator/SecretAccessKey/1/colon/mixed | 200017 | 8.185 | 3.667 | 250.000 | no |
| separator/SecretAccessKey/1/equals/space | 200017 | 7.216 | 3.587 | 250.000 | no |
| separator/SecretAccessKey/1/equals/tab | 200017 | 9.582 | 3.536 | 250.000 | no |
| separator/SecretAccessKey/1/equals/mixed | 200017 | 8.620 | 3.707 | 250.000 | no |
| separator/SecretAccessKey/2/arrow/space | 200018 | 9.174 | 3.730 | 250.000 | no |
| separator/SecretAccessKey/2/arrow/tab | 200018 | 6.992 | 3.877 | 250.000 | no |
| separator/SecretAccessKey/2/arrow/mixed | 200018 | 11.744 | 4.197 | 250.000 | no |
| separator/SecretAccessKey/2/equals/space | 200018 | 8.218 | 3.749 | 250.000 | no |
| separator/SecretAccessKey/2/equals/tab | 200018 | 7.645 | 3.935 | 250.000 | no |
| separator/SecretAccessKey/2/equals/mixed | 200018 | 8.948 | 3.208 | 250.000 | no |
| separator/SecretAccessKey/3/equals/space | 200019 | 8.005 | 4.180 | 250.000 | no |
| separator/SecretAccessKey/3/equals/tab | 200019 | 10.637 | 2.983 | 250.000 | no |
| separator/SecretAccessKey/3/equals/mixed | 200019 | 7.613 | 3.133 | 250.000 | no |
| residual/provider_extra | 240000 | 10.055 | 5.440 | 250.000 | no |
| residual/twilio | 200000 | 9.056 | 4.838 | 250.000 | no |
| residual/slack_webhook | 330000 | 13.673 | 25.616 | 250.000 | yes |
| residual/command_password | 250000 | 9.442 | 6.725 | 250.000 | no |
| residual/command_curl | 285000 | 10.661 | 44.691 | 250.000 | yes |
| residual/command_hex | 264000 | 10.104 | 9.924 | 250.000 | no |
| residual/command_openssl | 285000 | 11.316 | 3.693 | 250.000 | no |
| residual/query_encoded | 240000 | 9.412 | 9.532 | 250.000 | no |
| residual/userinfo_encoded | 250000 | 9.620 | 14.833 | 250.000 | no |
| residual/jwt_prefix_upper | 240000 | 9.294 | 4.993 | 250.000 | no |
| residual/authorization_nextline | 210000 | 8.789 | 14.149 | 250.000 | no |
| residual/csi_normalization | 260000 | 9.993 | 3.344 | 250.000 | no |
| residual/full_width_separator | 200010 | 8.429 | 1.867 | 250.000 | no |
| residual/identifier_alias | 240000 | 8.703 | 2.969 | 250.000 | no |

## Named-form copied controls

All rows were emitted by a synchronous failing child on stdout and stderr. Each watched seed was inside the unmasked line-then-size tail window before absence was checked. This mirrors the public API exactly: the historical byte-named limit counts JavaScript string units. CSI controls are removed before either check. No raw values or output are retained here.

The pre-fix copy is from bb325826; the identity copy replaces the candidate masker with identity behavior without changing tracked source. Candidate leaking rows: 0/45. Pre-fix leaking rows: 42/45. Identity leaking rows: 45/45. The three pre-existing protections also have exact output pins in the test file and fail the identity control.

| Named form | Family | Pre-fix status | Candidate leaked seeds | Pre-fix leaked seeds | Identity leaked seeds |
|---|---|---|---:|---:|---:|
| gitlab | provider | red | 0 | 1 | 1 |
| stripe_secret | provider | red | 0 | 1 | 1 |
| stripe_restricted | provider | red | 0 | 1 | 1 |
| stripe_webhook | provider | red | 0 | 1 | 1 |
| google_api | provider | red | 0 | 1 | 1 |
| twilio | provider | red | 0 | 1 | 1 |
| slack_webhook | provider | red | 0 | 3 | 3 |
| azure_account_key | identifier | red | 0 | 1 | 1 |
| cli_0 | cli | red | 0 | 1 | 1 |
| cli_1 | cli | red | 0 | 1 | 1 |
| cli_2 | cli | red | 0 | 1 | 1 |
| cli_3 | cli | red | 0 | 1 | 1 |
| cli_4 | cli | red | 0 | 1 | 1 |
| cli_5 | cli | red | 0 | 1 | 1 |
| cli_6 | cli | already protected | 0 | 0 | 1 |
| cli_7 | cli | already protected | 0 | 0 | 1 |
| cli_8 | cli | red | 0 | 1 | 1 |
| alias_pwd | identifier | red | 0 | 1 | 1 |
| alias_pass | identifier | red | 0 | 1 | 1 |
| alias_pw | identifier | red | 0 | 1 | 1 |
| alias_DB_PASS | identifier | red | 0 | 1 | 1 |
| alias_DB_PWD | identifier | red | 0 | 1 | 1 |
| alias__auth | identifier | red | 0 | 1 | 1 |
| alias_session_id | identifier | red | 0 | 1 | 1 |
| query_0 | query | red | 0 | 1 | 1 |
| query_1 | query | red | 0 | 1 | 1 |
| query_2 | query | already protected | 0 | 0 | 1 |
| query_3 | query | red | 0 | 1 | 1 |
| query_4 | query | red | 0 | 1 | 1 |
| url_user_only | url | red | 0 | 1 | 1 |
| url_long_user_password | url | red | 0 | 1 | 1 |
| url_password_spaces | url | red | 0 | 2 | 2 |
| url_encoded_colon | url | red | 0 | 1 | 1 |
| url_encoded_at | url | red | 0 | 1 | 1 |
| full_width_separator | encoding | red | 0 | 1 | 1 |
| csi_key_erase | encoding | red | 0 | 1 | 1 |
| csi_inside_key | encoding | red | 0 | 1 | 1 |
| bearer_next_line | authorization | red | 0 | 1 | 1 |
| bearer_colon | authorization | red | 0 | 1 | 1 |
| basic_standalone | authorization | red | 0 | 1 | 1 |
| jwt_prefix_0 | jwt | red | 0 | 1 | 1 |
| jwt_prefix_1 | jwt | red | 0 | 1 | 1 |
| jwt_prefix_2 | jwt | red | 0 | 1 | 1 |
| jwt_prefix_3 | jwt | red | 0 | 1 | 1 |
| jwt_upper_header | jwt | red | 0 | 1 | 1 |

## Red evidence

| Task | Executed tests | Passing | Failing | Classifier | Semantic assessment |
|---|---:|---:|---:|---|---|
| 1 | 3 | 1 | 2 | RED_EVIDENCE_OK | Rejected execution contexts and missing credential references failed their intended assertions; supported exact echo passed. |
| 2 | 3 | 0 | 3 | RED_EVIDENCE_OK | The byte-window cap and two safe-delimiter assertions failed against the prior harness/rules. |
| 3 | 2 | 0 | 2 | RED_EVIDENCE_OK | Named provider masking and exact authorization/normalization diagnostics failed their intended assertions. |

Only supported identifiers, reviewed credential shapes and the bounded one/two-level derivation model are proven. Arbitrary unlabelled secrets and arbitrary Bash programs remain outside that claim; the existing GR-06 Phase 196 receiver is unchanged.
