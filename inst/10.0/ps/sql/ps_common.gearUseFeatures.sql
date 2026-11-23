-- ObServe 10.0 PS: ps_common.gearUseFeatures sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.comment AS "comment",
    q.number AS "number",
    q.usedInTrip AS "usedInTrip",
    q.gear AS "gear",
    q.trip AS "trip"
FROM ps_common.gearUseFeatures AS q
WHERE q.trip = $1::text
ORDER BY q.topiaId;
