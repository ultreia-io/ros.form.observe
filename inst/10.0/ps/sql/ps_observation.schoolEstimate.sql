-- ObServe 10.0 PS: ps_observation.schoolEstimate sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.meanWeight AS "meanWeight",
    q.totalWeight AS "totalWeight",
    q.fishingSet AS "fishingSet",
    q.species AS "species",
    q.weightMeasureMethod AS "weightMeasureMethod"
FROM ps_observation.schoolEstimate AS q
JOIN ps_observation.fishingSet AS p1 ON p1.topiaId = q.fishingSet
JOIN ps_observation.activity AS p2 ON p2.topiaId = p1.activity
JOIN ps_observation.route AS p3 ON p3.topiaId = p2.route
WHERE p3.trip = $1::text
ORDER BY q.topiaId;
