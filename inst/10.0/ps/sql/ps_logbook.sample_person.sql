-- ObServe 10.0 PS: ps_logbook.sample_person sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.sample AS "sample",
    q.person AS "person"
FROM ps_logbook.sample_person AS q
JOIN ps_logbook.sample AS p1 ON p1.topiaId = q.sample
WHERE p1.trip = $1::text
ORDER BY q.sample, q.person;
