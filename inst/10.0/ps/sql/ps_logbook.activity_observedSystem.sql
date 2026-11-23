-- ObServe 10.0 PS: ps_logbook.activity_observedSystem sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.activity AS "activity",
    q.observedSystem AS "observedSystem"
FROM ps_logbook.activity_observedSystem AS q
JOIN ps_logbook.activity AS p1 ON p1.topiaId = q.activity
JOIN ps_logbook.route AS p2 ON p2.topiaId = p1.route
WHERE p2.trip = $1::text
ORDER BY q.activity, q.observedSystem;
