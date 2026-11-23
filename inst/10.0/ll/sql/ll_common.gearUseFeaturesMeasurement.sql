-- ObServe 10.0 LL: ll_common.gearUseFeaturesMeasurement sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    m.topiaId AS "topiaId",
    m.measurementValue AS "measurementValue",
    m.gearCharacteristic AS "gearCharacteristic",
    m.gearUseFeatures AS "gearUseFeatures"
FROM ll_common.gearUseFeaturesMeasurement AS m
JOIN ll_common.gearUseFeatures AS g ON g.topiaId = m.gearUseFeatures
WHERE g.trip = $1::text
ORDER BY m.topiaId;
