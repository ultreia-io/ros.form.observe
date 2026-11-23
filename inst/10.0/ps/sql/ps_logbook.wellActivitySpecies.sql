-- ObServe 10.0 PS: ps_logbook.wellActivitySpecies sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.count AS "count",
    q.setSpeciesNumber AS "setSpeciesNumber",
    q.weight AS "weight",
    q.species AS "species",
    q.weightCategory AS "weightCategory",
    q.wellActivity AS "wellActivity"
FROM ps_logbook.wellActivitySpecies AS q
JOIN ps_logbook.wellActivity AS p1 ON p1.topiaId = q.wellActivity
JOIN ps_logbook.well AS p2 ON p2.topiaId = p1.well
WHERE p2.trip = $1::text
ORDER BY q.topiaId;
