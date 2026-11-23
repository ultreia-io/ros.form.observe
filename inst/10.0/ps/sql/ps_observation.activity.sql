-- ObServe 10.0 PS: ps_observation.activity sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.comment AS "comment",
    q.ersId AS "ersId",
    q.latitude AS "latitude",
    q.longitude AS "longitude",
    q.observedSystemDistance AS "observedSystemDistance",
    q.seaSurfaceTemperature AS "seaSurfaceTemperature",
    q.time AS "time",
    q.vesselSpeed AS "vesselSpeed",
    q.currentFpaZone AS "currentFpaZone",
    q.dataQuality AS "dataQuality",
    q.detectionMode AS "detectionMode",
    q.nextFpaZone AS "nextFpaZone",
    q.previousFpaZone AS "previousFpaZone",
    q.reasonForNoFishing AS "reasonForNoFishing",
    q.route AS "route",
    q.surroundingActivity AS "surroundingActivity",
    q.vesselActivity AS "vesselActivity",
    q.wind AS "wind"
FROM ps_observation.activity AS q
JOIN ps_observation.route AS p1 ON p1.topiaId = q.route
WHERE p1.trip = $1::text
ORDER BY q.topiaId;
