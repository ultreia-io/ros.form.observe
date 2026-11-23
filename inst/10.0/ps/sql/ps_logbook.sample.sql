-- ObServe 10.0 PS: ps_logbook.sample sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.bigsWeight AS "bigsWeight",
    q.comment AS "comment",
    q.number AS "number",
    q.smallsWeight AS "smallsWeight",
    q.superSample AS "superSample",
    q.totalWeight AS "totalWeight",
    q.weightsComputed AS "weightsComputed",
    q.well AS "well",
    q.sampleQuality AS "sampleQuality",
    q.sampleType AS "sampleType",
    q.trip AS "trip"
FROM ps_logbook.sample AS q
WHERE q.trip = $1::text
ORDER BY q.topiaId;
