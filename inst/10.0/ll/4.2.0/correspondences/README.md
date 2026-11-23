# ObServe LL to ROS LL correspondences

These files map encountered ObServe technical IDs to ROS codes; they contain no trip or person data.

They are initial correspondences based on recorded catalogue meanings, for review before production export.

## Evidence

Scope: 70 saved observer-monitored LL trips in 2020–2025, French flag, Indian Ocean, five programmes.

The year counts are 8, 13, 7, 12, 13 and 17 trips respectively; no trip belongs to two selections.

Source exports: `~/.cache/ros.form.observe/ird/exports/20261112T221530Z/`.

ObServe reference snapshot: `~/.cache/ros.form.observe/ird/snapshots/20261112T184113Z/code_lists/`.

ROS reference snapshot: `~/.cache/ros.form.references/code_lists/code_lists--b7c000cba93d/`.

All 560 relevant source CSVs matched the SHA-256 checksums in the saved yearly file inventories.

Reference fields were located through each export's saved source model, including every line-material binding.

Only nonempty values encountered in these exports are included; unused and missing values receive no correspondence.

The CSV contract is exactly `source_value,target_value`; both columns are text, including complete technical IDs.

Each CSV is named after its ROS target table (`schema.table.csv`), matching the target-driven mapping entries.

[Extended correspondences](../correspondences-extended/README.md) add candidates beyond the encountered values.

`mapping.yaml` selects this cohort-derived set; it does not enable the extended set.

## Initial pairs

The source business codes below explain the pairs; the CSVs themselves use their catalogue technical IDs.

| File                                      | Pairs | Source codes            | Target codes       |
| ----------------------------------------- | ----- | ----------------------- | ------------------ |
| refs_biology.sex.csv                      | 3     | 0, 1, 2                 | N, M, F            |
| refs_biology.measurement_tools.csv        | 4     | 1, 2, 5, 9              | CA, MB, VL, UN     |
| refs_biology.weight_measurement_tools.csv | 1     | 9                       | UN                 |
| refs_biology.weight_measurements.csv      | 3     | ENT, VAT, VDK           | RD, GO, HD         |
| refs_fishery.fish_processing_types.csv    | 3     | ENT, VAT, VDK           | RD, GO, HD         |
| refs_biology.fate_types.csv               | 2     | DIS, RET                | DI, RE             |
| refs_fishery.light_colours.csv            | 4     | B, G, P, Y              | BU, GR, OT, YL     |
| refs_fishery.light_types.csv              | 2     | CH, EL                  | CL, EL             |
| refs_fishery.line_material_types.csv      | 5     | BRL, GLW, MON, MUN, TR3 | BR, GW, NL, MN, TR |
| refs_data.data_sources_ro.csv             | 1     | OB                      | OB                 |

Whole, gutted and headed-and-gutted categories retain their recorded meaning; no gill or tail removal is inferred.

Pink maps to the target's Other colour category; mixed colours do not receive that correspondence automatically.

Recorded Unknown measurement methods map to `UN`. This is not a default for missing measurements or missing inputs.

## Encountered values left unresolved

Counts are populated field occurrences across the cohort, not trip or animal counts.

| Source table               | Code | Occurrences | Decision still needed                            |
| -------------------------- | ---- | ----------- | ------------------------------------------------ |
| common.sex                 | 4    | 342         | Confirm how Not available should be reported.    |
| common.sizemeasuremethod   | 4    | 2           | Identify an equivalent semi-rigid tape category. |
| ll_common.catchfate        | ESC  | 681         | Confirm how escaped catches fit ROS fate types.  |
| ll_common.lightstickscolor | VAR  | 364         | Define reporting of several recorded colours.    |
| ll_common.lightstickstype  | MX   | 87          | Define reporting of mixed light types.           |
| ll_common.linetype         | PV   | 27          | Confirm Polyvinyl versus multifilament cremona.  |

These source values are deliberately absent from the CSVs, so resolution returns `no_match`.

## Target catalogue limitations

In `refs_biology.measurement_tools`, `CA` and `UN` occur in both `LN` and `WG` rows.

`CA` means Calliper for length but Calculation for weight. Both `UN` rows mean Unknown in their own context.

The size-method correspondences mean `LN/CA` and `LN/UN`; the configured lookup on `code` returns ambiguity.

This affects 2,876 calliper and 20,825 unknown size-method occurrences in this cohort.

Length-context selection needs an exporter/catalogue decision; no matching row is selected automatically.

The light-colour names agree in English and French, but descriptions for `OT`, `RD` and `YL` appear shifted.

The proposed colour correspondences follow the code/name pairs; the target descriptions need separate review.
