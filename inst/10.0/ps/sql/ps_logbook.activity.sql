-- ObServe 10.0 PS: ps_logbook.activity sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.comment AS "comment",
    q.currentDirection AS "currentDirection",
    q.currentSpeed AS "currentSpeed",
    q.latitude AS "latitude",
    q.latitudeOriginal AS "latitudeOriginal",
    q.longitude AS "longitude",
    q.longitudeOriginal AS "longitudeOriginal",
    q.number AS "number",
    q.originalDataModified AS "originalDataModified",
    q.positionCorrected AS "positionCorrected",
    q.seaSurfaceTemperature AS "seaSurfaceTemperature",
    q.setCount AS "setCount",
    q.time AS "time",
    q.totalWeight AS "totalWeight",
    q.vmsDivergent AS "vmsDivergent",
    q.windDirection AS "windDirection",
    q.currentFpaZone AS "currentFpaZone",
    q.dataQuality AS "dataQuality",
    q.informationSource AS "informationSource",
    q.nextFpaZone AS "nextFpaZone",
    q.previousFpaZone AS "previousFpaZone",
    q.reasonForNoFishing AS "reasonForNoFishing",
    q.reasonForNullSet AS "reasonForNullSet",
    q.relatedObservedActivity AS "relatedObservedActivity",
    q.route AS "route",
    q.schoolType AS "schoolType",
    q.setSuccessStatus AS "setSuccessStatus",
    q.vesselActivity AS "vesselActivity",
    q.wind AS "wind"
FROM ps_logbook.activity AS q
JOIN ps_logbook.route AS p1 ON p1.topiaId = q.route
WHERE p1.trip = $1::text
ORDER BY q.topiaId;
