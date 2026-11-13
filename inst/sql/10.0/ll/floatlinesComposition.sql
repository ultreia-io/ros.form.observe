-- ObServe 10.0 LL: floatlinesComposition sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/models/10.0/ll-form.yaml; quoted aliases preserve field names.
SELECT
    c.topiaId AS "topiaId",
    c.length AS "length",
    c.proportion AS "proportion",
    c.fishingSet AS "fishingSet",
    c.lineType AS "lineType"
FROM ll_observation.floatlinesComposition AS c
JOIN ll_observation.fishingSet AS s ON s.topiaId = c.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY c.topiaId;
