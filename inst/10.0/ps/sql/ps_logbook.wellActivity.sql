-- ObServe 10.0 PS: ps_logbook.wellActivity sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.activity AS "activity",
    q.well AS "well"
FROM ps_logbook.wellActivity AS q
JOIN ps_logbook.well AS p1 ON p1.topiaId = q.well
WHERE p1.trip = $1::text
ORDER BY q.topiaId;
