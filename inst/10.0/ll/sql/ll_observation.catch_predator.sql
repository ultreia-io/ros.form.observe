-- ObServe 10.0 LL: ll_observation.catch_predator sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    cp.catch AS "catch",
    cp.species AS "species"
FROM ll_observation.catch_predator AS cp
JOIN ll_observation.catch AS c ON c.topiaId = cp.catch
JOIN ll_observation.fishingSet AS s ON s.topiaId = c.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY cp.catch, cp.species;
