-- ObServe 10.0 PS: ps_logbook.route sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.comment AS "comment",
    q.date AS "date",
    q.fishingTime AS "fishingTime",
    q.timeAtSea AS "timeAtSea",
    q.trip AS "trip"
FROM ps_logbook.route AS q
WHERE q.trip = $1::text
ORDER BY q.topiaId;
