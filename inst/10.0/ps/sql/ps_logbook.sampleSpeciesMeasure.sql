-- ObServe 10.0 PS: ps_logbook.sampleSpeciesMeasure sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.count AS "count",
    q.sizeClass AS "sizeClass",
    q.sampleSpecies AS "sampleSpecies"
FROM ps_logbook.sampleSpeciesMeasure AS q
JOIN ps_logbook.sampleSpecies AS p1 ON p1.topiaId = q.sampleSpecies
JOIN ps_logbook.sample AS p2 ON p2.topiaId = p1.sample
WHERE p2.trip = $1::text
ORDER BY q.topiaId;
