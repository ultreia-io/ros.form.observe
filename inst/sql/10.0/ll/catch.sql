-- ObServe 10.0 LL: catch sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/models/10.0/ll-form.yaml; quoted aliases preserve field names.
SELECT
    c.topiaId AS "topiaId",
    c.acquisitionMode AS "acquisitionMode",
    c.beatDiameter AS "beatDiameter",
    c.comment AS "comment",
    c.count AS "count",
    c.depredated AS "depredated",
    c.gonadeWeight AS "gonadeWeight",
    c.hookWhenDiscarded AS "hookWhenDiscarded",
    c.number AS "number",
    c.photoReferences AS "photoReferences",
    c.sampleReferences AS "sampleReferences",
    c.tagNumber AS "tagNumber",
    c.totalWeight AS "totalWeight",
    c.basket AS "basket",
    c.branchline AS "branchline",
    c.catchFate AS "catchFate",
    c.catchHealthStatus AS "catchHealthStatus",
    c.discardHealthStatus AS "discardHealthStatus",
    c.fishingSet AS "fishingSet",
    c.hookPosition AS "hookPosition",
    c.maturityStatus AS "maturityStatus",
    c.section AS "section",
    c.sex AS "sex",
    c.species AS "species",
    c.stomachFullness AS "stomachFullness",
    c.weightMeasureMethod AS "weightMeasureMethod",
    c.weightMeasureType AS "weightMeasureType"
FROM ll_observation.catch AS c
JOIN ll_observation.fishingSet AS s ON s.topiaId = c.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY c.topiaId;
