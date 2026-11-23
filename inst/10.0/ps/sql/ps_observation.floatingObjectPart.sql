-- ObServe 10.0 PS: ps_observation.floatingObjectPart sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.whenArriving AS "whenArriving",
    q.whenLeaving AS "whenLeaving",
    q.floatingObject AS "floatingObject",
    q.objectMaterial AS "objectMaterial"
FROM ps_observation.floatingObjectPart AS q
JOIN ps_observation.floatingObject AS p1 ON p1.topiaId = q.floatingObject
JOIN ps_observation.activity AS p2 ON p2.topiaId = p1.activity
JOIN ps_observation.route AS p3 ON p3.topiaId = p2.route
WHERE p3.trip = $1::text
ORDER BY q.topiaId;
