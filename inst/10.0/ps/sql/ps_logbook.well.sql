-- ObServe 10.0 PS: ps_logbook.well sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.well AS "well",
    q.wellFactory AS "wellFactory",
    q.wellVessel AS "wellVessel",
    q.trip AS "trip",
    q.wellSamplingConformity AS "wellSamplingConformity",
    q.wellSamplingStatus AS "wellSamplingStatus"
FROM ps_logbook.well AS q
WHERE q.trip = $1::text
ORDER BY q.topiaId;
