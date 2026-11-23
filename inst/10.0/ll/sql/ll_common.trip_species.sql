-- ObServe 10.0 LL: ll_common.trip_species sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    ts.trip AS "trip",
    ts.species AS "species"
FROM ll_common.trip_species AS ts
WHERE ts.trip = $1::text
ORDER BY ts.trip, ts.species;
