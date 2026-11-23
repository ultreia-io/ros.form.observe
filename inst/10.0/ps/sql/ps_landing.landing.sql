-- ObServe 10.0 PS: ps_landing.landing sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.date AS "date",
    q.weight AS "weight",
    q.destination AS "destination",
    q.fate AS "fate",
    q.fateVessel AS "fateVessel",
    q.species AS "species",
    q.trip AS "trip",
    q.weightCategory AS "weightCategory"
FROM ps_landing.landing AS q
WHERE q.trip = $1::text
ORDER BY q.topiaId;
