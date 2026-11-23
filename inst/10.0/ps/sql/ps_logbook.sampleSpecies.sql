-- ObServe 10.0 PS: ps_logbook.sampleSpecies sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.comment AS "comment",
    q.endTime AS "endTime",
    q.measuredCount AS "measuredCount",
    q.startTime AS "startTime",
    q.subSampleNumber AS "subSampleNumber",
    q.totalCount AS "totalCount",
    q.sample AS "sample",
    q.sizeMeasureType AS "sizeMeasureType",
    q.species AS "species"
FROM ps_logbook.sampleSpecies AS q
JOIN ps_logbook.sample AS p1 ON p1.topiaId = q.sample
WHERE p1.trip = $1::text
ORDER BY q.topiaId;
