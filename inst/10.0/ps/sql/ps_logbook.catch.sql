-- ObServe 10.0 PS: ps_logbook.catch sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.comment AS "comment",
    q.count AS "count",
    q.weight AS "weight",
    q.well AS "well",
    q.activity AS "activity",
    q.species AS "species",
    q.speciesFate AS "speciesFate",
    q.weightCategory AS "weightCategory",
    q.weightMeasureMethod AS "weightMeasureMethod"
FROM ps_logbook.catch AS q
JOIN ps_logbook.activity AS p1 ON p1.topiaId = q.activity
JOIN ps_logbook.route AS p2 ON p2.topiaId = p1.route
WHERE p2.trip = $1::text
ORDER BY q.topiaId;
