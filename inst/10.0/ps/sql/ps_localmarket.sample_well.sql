-- ObServe 10.0 PS: ps_localmarket.sample_well sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.sample AS "sample",
    q.well AS "well"
FROM ps_localmarket.sample_well AS q
JOIN ps_localmarket.sample AS p1 ON p1.topiaId = q.sample
WHERE p1.trip = $1::text
ORDER BY q.sample, q.well;
