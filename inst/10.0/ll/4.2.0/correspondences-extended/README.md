# Extended ObServe LL to ROS LL correspondences

This alternative set contains 42 pairs: the 28 cohort-derived pairs plus 14 explicit catalogue correspondences.

The additional source values were not encountered in the 70 saved trips from 2020–2025.

The ten CSVs use the same ROS `schema.table.csv` names and `source_value,target_value` contract as the original set.

Each file includes its original pairs unchanged; this is an alternative set, not a collection of patches.

The inspected source and target snapshots are recorded in the [cohort README](../correspondences/README.md#evidence).

`mapping.yaml` still selects `correspondences/`. Selecting this set requires changing its ten CSV paths explicitly.

These are catalogue candidates for review. Coverage is incomplete; unlisted source values remain unresolved.

## Additional pairs

Source codes below explain the additions; the CSVs contain complete ObServe technical IDs.

| ROS target table                      | Source table                | Added source codes | Target codes |
| ------------------------------------- | --------------------------- | ------------------ | ------------ |
| refs_biology.sex                      | common.sex                  | 3                  | J            |
| refs_biology.measurement_tools        | common.sizemeasuremethod    | 3                  | FT           |
| refs_biology.weight_measurement_tools | common.weightmeasuremethod  | 1, 2, 4            | SB, EB, VW   |
| refs_biology.weight_measurements      | common.weightmeasuretype    | UNK                | UN           |
| refs_fishery.fish_processing_types    | common.weightmeasuretype    | UNK                | UN           |
| refs_biology.fate_types               | ll_common.catchfate         | UNK                | UN           |
| refs_fishery.light_colours            | ll_common.lightstickscolor  | R, O, W            | RD, OT, OT   |
| refs_fishery.line_material_types      | ll_common.linetype          | SSW, SKW           | ST, SK       |
| refs_data.data_sources_ro             | ll_common.observationmethod | OE                 | EM           |

`refs_fishery.light_types.csv` has no additions and retains its two original pairs.

The added pairs follow these catalogue meanings:

* Juvenile sex maps to Juvenile; the disabled source entry remains usable for historical data.
* Flexible measuring tape maps to Flexible tape.
* Mechanical hanging scale maps to Spring balance, whose description explicitly includes hanging scales.
* Electronic hanging scale maps to Electronic balance; visual weight assessment maps to Visual weight.
* Recorded Unknown weight type, processing type and fate map to their explicit Unknown categories.
* Red maps to Red; Orange and White map to Other, as neither has a dedicated ROS colour code.
* Stainless steel wire and Sekiyama wire map to the corresponding material categories.
* Electronic monitoring maps to Electronic monitoring, without implying any particular observation coverage.

An explicit Unknown source entry is not a default: missing inputs and absent correspondences remain unresolved.

## Remaining gaps

| Source table                | Omitted codes   | Reason                                                                     |
| --------------------------- | --------------- | -------------------------------------------------------------------------- |
| common.sex                  | 4               | Not collected is not automatically Unknown.                                |
| common.sizemeasuremethod    | 4               | No exact semi-rigid tape category.                                         |
| common.weightmeasuremethod  | 3, 5            | Anti-roll scale technology and echosounder conversion need interpretation. |
| ll_common.catchfate         | SOLD, ESC, LOST | Historical sale, escape and loss semantics need an explicit decision.      |
| ll_common.lightstickscolor  | UNK, VAR        | No Unknown target; several colours need a reporting rule.                  |
| ll_common.lightstickstype   | MX              | Mixed types require a reporting rule.                                      |
| ll_common.linetype          | UNK, PR, PV, WR | No Unknown target; material equivalences or detail are insufficient.       |
| ll_common.observationmethod | SR              | No self-reporting target category.                                         |

This set extends the existing ten target lists; it does not settle contextual rules or add other target lists.

The original `CA` and `UN` length-tool pairs still return ambiguity because ROS also uses those codes for weight tools.

The ROS light-colour descriptions for `OT`, `RD` and `YL` still need review; these pairs follow the bilingual names.

All 14 additions resolve uniquely through the declared target lookups using the frozen catalogue.
