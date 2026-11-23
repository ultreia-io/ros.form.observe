-- ObServe 10.0 PS: ps_logbook.transmittingBuoy sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.code AS "code",
    q.comment AS "comment",
    q.latitude AS "latitude",
    q.longitude AS "longitude",
    q.country AS "country",
    q.floatingObject AS "floatingObject",
    q.transmittingBuoyOperation AS "transmittingBuoyOperation",
    q.transmittingBuoyOwnership AS "transmittingBuoyOwnership",
    q.transmittingBuoyType AS "transmittingBuoyType",
    q.vessel AS "vessel"
FROM ps_logbook.transmittingBuoy AS q
JOIN ps_logbook.floatingObject AS p1 ON p1.topiaId = q.floatingObject
JOIN ps_logbook.activity AS p2 ON p2.topiaId = p1.activity
JOIN ps_logbook.route AS p3 ON p3.topiaId = p2.route
WHERE p3.trip = $1::text
ORDER BY q.topiaId;
