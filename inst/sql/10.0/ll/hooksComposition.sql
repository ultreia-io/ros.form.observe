-- ObServe 10.0 LL: hooksComposition sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/models/10.0/ll-form.yaml; quoted aliases preserve field names.
SELECT
    c.topiaId AS "topiaId",
    c.hookOffset AS "hookOffset",
    c.proportion AS "proportion",
    c.fishingSet AS "fishingSet",
    c.hookSize AS "hookSize",
    c.hookType AS "hookType"
FROM ll_observation.hooksComposition AS c
JOIN ll_observation.fishingSet AS s ON s.topiaId = c.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY c.topiaId;
