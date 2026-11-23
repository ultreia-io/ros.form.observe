-- ObServe 10.0 PS: ps_observation.fishingSet sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.comment AS "comment",
    q.currentDirection AS "currentDirection",
    q.currentMeasureDepth AS "currentMeasureDepth",
    q.currentSpeed AS "currentSpeed",
    q.endTimeStamp AS "endTimeStamp",
    q.haulingEndTimeStamp AS "haulingEndTimeStamp",
    q.haulingStartTimeStamp AS "haulingStartTimeStamp",
    q.maxGearDepth AS "maxGearDepth",
    q.schoolMeanDepth AS "schoolMeanDepth",
    q.schoolThickness AS "schoolThickness",
    q.schoolTopDepth AS "schoolTopDepth",
    q.startTime AS "startTime",
    q.supportVesselName AS "supportVesselName",
    q.activity AS "activity",
    q.reasonForNullSet AS "reasonForNullSet",
    q.schoolType AS "schoolType"
FROM ps_observation.fishingSet AS q
JOIN ps_observation.activity AS p1 ON p1.topiaId = q.activity
JOIN ps_observation.route AS p2 ON p2.topiaId = p1.route
WHERE p2.trip = $1::text
ORDER BY q.topiaId;
