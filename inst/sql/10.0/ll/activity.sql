-- ObServe 10.0 LL: activity sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/models/10.0/ll-form.yaml; quoted aliases preserve field names.
SELECT
    a.topiaId AS "topiaId",
    a.comment AS "comment",
    a.latitude AS "latitude",
    a.longitude AS "longitude",
    a.seaSurfaceTemperature AS "seaSurfaceTemperature",
    a.timeStamp AS "timeStamp",
    a.dataQuality AS "dataQuality",
    a.fpaZone AS "fpaZone",
    a.trip AS "trip",
    a.vesselActivity AS "vesselActivity"
FROM ll_observation.activity AS a
WHERE a.trip = $1::text
ORDER BY a.topiaId;
