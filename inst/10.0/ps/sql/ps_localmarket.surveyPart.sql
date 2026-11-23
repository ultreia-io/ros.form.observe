-- ObServe 10.0 PS: ps_localmarket.surveyPart sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.proportion AS "proportion",
    q.species AS "species",
    q.survey AS "survey"
FROM ps_localmarket.surveyPart AS q
JOIN ps_localmarket.survey AS p1 ON p1.topiaId = q.survey
WHERE p1.trip = $1::text
ORDER BY q.topiaId;
