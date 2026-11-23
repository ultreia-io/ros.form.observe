-- ObServe 10.0 LL: ll_observation.fishingSet_mitigationType sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    m.fishingSet AS "fishingSet",
    m.mitigationType AS "mitigationType"
FROM ll_observation.fishingSet_mitigationType AS m
JOIN ll_observation.fishingSet AS s ON s.topiaId = m.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY m.fishingSet, m.mitigationType;
