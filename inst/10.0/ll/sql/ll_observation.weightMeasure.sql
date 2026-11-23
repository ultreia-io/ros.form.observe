-- ObServe 10.0 LL: ll_observation.weightMeasure sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    m.topiaId AS "topiaId",
    m.weight AS "weight",
    m.catch AS "catch",
    m.weightMeasureMethod AS "weightMeasureMethod",
    m.weightMeasureType AS "weightMeasureType"
FROM ll_observation.weightMeasure AS m
JOIN ll_observation.catch AS c ON c.topiaId = m.catch
JOIN ll_observation.fishingSet AS s ON s.topiaId = c.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY m.topiaId;
