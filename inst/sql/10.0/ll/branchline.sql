-- ObServe 10.0 LL: branchline sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/models/10.0/ll-form.yaml; quoted aliases preserve field names.
SELECT
    br.topiaId AS "topiaId",
    br.branchlineLength AS "branchlineLength",
    br.comment AS "comment",
    br.depthRecorder AS "depthRecorder",
    br.haulingIdentifier AS "haulingIdentifier",
    br.hookLost AS "hookLost",
    br.hookOffset AS "hookOffset",
    br.settingIdentifier AS "settingIdentifier",
    br.snapWeight AS "snapWeight",
    br.swivelWeight AS "swivelWeight",
    br.timeSinceContact AS "timeSinceContact",
    br.timer AS "timer",
    br.timerTimeOnBoard AS "timerTimeOnBoard",
    br.traceCutOff AS "traceCutOff",
    br.tracelineLength AS "tracelineLength",
    br.weightedSnap AS "weightedSnap",
    br.weightedSwivel AS "weightedSwivel",
    br.baitHaulingStatus AS "baitHaulingStatus",
    br.baitSettingStatus AS "baitSettingStatus",
    br.baitType AS "baitType",
    br.basket AS "basket",
    br.hookSize AS "hookSize",
    br.hookType AS "hookType",
    br.topType AS "topType",
    br.tracelineType AS "tracelineType"
FROM ll_observation.branchline AS br
JOIN ll_observation.basket AS b ON b.topiaId = br.basket
JOIN ll_observation.section AS sc ON sc.topiaId = b.section
JOIN ll_observation.fishingSet AS s ON s.topiaId = sc.fishingSet
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY br.topiaId;
