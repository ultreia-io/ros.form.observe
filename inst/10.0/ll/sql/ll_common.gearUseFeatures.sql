-- ObServe 10.0 LL: ll_common.gearUseFeatures sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    g.topiaId AS "topiaId",
    g.comment AS "comment",
    g.number AS "number",
    g.usedInTrip AS "usedInTrip",
    g.gear AS "gear",
    g.trip AS "trip"
FROM ll_common.gearUseFeatures AS g
WHERE g.trip = $1::text
ORDER BY g.topiaId;
