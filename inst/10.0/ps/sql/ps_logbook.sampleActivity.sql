-- ObServe 10.0 PS: ps_logbook.sampleActivity sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.weightedWeight AS "weightedWeight",
    q.weightedWeightComputed AS "weightedWeightComputed",
    q.activity AS "activity",
    q.sample AS "sample"
FROM ps_logbook.sampleActivity AS q
JOIN ps_logbook.sample AS p1 ON p1.topiaId = q.sample
WHERE p1.trip = $1::text
ORDER BY q.topiaId;
