-- ObServe 10.0 PS: ps_common.gearUseFeaturesMeasurement sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.measurementValue AS "measurementValue",
    q.gearCharacteristic AS "gearCharacteristic",
    q.gearUseFeatures AS "gearUseFeatures"
FROM ps_common.gearUseFeaturesMeasurement AS q
JOIN ps_common.gearUseFeatures AS p1 ON p1.topiaId = q.gearUseFeatures
WHERE p1.trip = $1::text
ORDER BY q.topiaId;
