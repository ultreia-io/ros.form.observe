-- ObServe 10.0 LL: ll_observation.baitsComposition sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    c.topiaId AS "topiaId",
    c.individualSize AS "individualSize",
    c.individualWeight AS "individualWeight",
    c.proportion AS "proportion",
    c.baitSettingStatus AS "baitSettingStatus",
    c.baitType AS "baitType",
    c.fishingSet AS "fishingSet"
FROM ll_observation.baitsComposition AS c
JOIN ll_observation.fishingSet AS s ON s.topiaId = c.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY c.topiaId;
