-- ObServe 10.0 LL: sizeMeasure sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/models/10.0/ll-form.yaml; quoted aliases preserve field names.
SELECT
    m.topiaId AS "topiaId",
    m.size AS "size",
    m.sizeMeasureMethod AS "sizeMeasureMethod",
    m.sizeMeasureType AS "sizeMeasureType",
    m.catch AS "catch"
FROM ll_observation.sizeMeasure AS m
JOIN ll_observation.catch AS c ON c.topiaId = m.catch
JOIN ll_observation.fishingSet AS s ON s.topiaId = c.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY m.topiaId;
