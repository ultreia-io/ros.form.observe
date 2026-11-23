-- ObServe 10.0 PS: ps_logbook.floatingObject sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.comment AS "comment",
    q.computedWhenArrivingBiodegradable AS "computedWhenArrivingBiodegradable",
    q.computedWhenArrivingNonEntangling AS "computedWhenArrivingNonEntangling",
    q.computedWhenArrivingSimplifiedObjectType AS "computedWhenArrivingSimplifiedObjectType",
    q.computedWhenLeavingBiodegradable AS "computedWhenLeavingBiodegradable",
    q.computedWhenLeavingNonEntangling AS "computedWhenLeavingNonEntangling",
    q.computedWhenLeavingSimplifiedObjectType AS "computedWhenLeavingSimplifiedObjectType",
    q.supportVesselName AS "supportVesselName",
    q.activity AS "activity",
    q.objectOperation AS "objectOperation"
FROM ps_logbook.floatingObject AS q
JOIN ps_logbook.activity AS p1 ON p1.topiaId = q.activity
JOIN ps_logbook.route AS p2 ON p2.topiaId = p1.route
WHERE p2.trip = $1::text
ORDER BY q.topiaId;
