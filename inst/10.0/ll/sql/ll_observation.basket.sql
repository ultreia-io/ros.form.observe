-- ObServe 10.0 LL: ll_observation.basket sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    b.topiaId AS "topiaId",
    b.floatline1Length AS "floatline1Length",
    b.floatline2Length AS "floatline2Length",
    b.haulingIdentifier AS "haulingIdentifier",
    b.settingIdentifier AS "settingIdentifier",
    b.section AS "section"
FROM ll_observation.basket AS b
JOIN ll_observation.section AS sc ON sc.topiaId = b.section
JOIN ll_observation.fishingSet AS s ON s.topiaId = sc.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY b.topiaId;
