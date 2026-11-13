-- ObServe 10.0 LL: section sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/models/10.0/ll-form.yaml; quoted aliases preserve field names.
SELECT
    sc.topiaId AS "topiaId",
    sc.haulingIdentifier AS "haulingIdentifier",
    sc.settingIdentifier AS "settingIdentifier",
    sc.fishingSet AS "fishingSet"
FROM ll_observation.section AS sc
JOIN ll_observation.fishingSet AS s ON s.topiaId = sc.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY sc.topiaId;
