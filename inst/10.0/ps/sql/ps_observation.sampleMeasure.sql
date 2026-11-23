-- ObServe 10.0 PS: ps_observation.sampleMeasure sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.acquisitionMode AS "acquisitionMode",
    q.count AS "count",
    q.isLengthComputed AS "isLengthComputed",
    q.isWeightComputed AS "isWeightComputed",
    q.length AS "length",
    q.picturesReferences AS "picturesReferences",
    q.tagNumber AS "tagNumber",
    q.weight AS "weight",
    q.sample AS "sample",
    q.sex AS "sex",
    q.sizeMeasureMethod AS "sizeMeasureMethod",
    q.sizeMeasureType AS "sizeMeasureType",
    q.species AS "species",
    q.speciesFate AS "speciesFate",
    q.weightMeasureMethod AS "weightMeasureMethod",
    q.weightMeasureType AS "weightMeasureType"
FROM ps_observation.sampleMeasure AS q
JOIN ps_observation.sample AS p1 ON p1.topiaId = q.sample
JOIN ps_observation.fishingSet AS p2 ON p2.topiaId = p1.fishingSet
JOIN ps_observation.activity AS p3 ON p3.topiaId = p2.activity
JOIN ps_observation.route AS p4 ON p4.topiaId = p3.route
WHERE p4.trip = $1::text
ORDER BY q.topiaId;
