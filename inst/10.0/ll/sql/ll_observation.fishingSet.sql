-- ObServe 10.0 LL: ll_observation.fishingSet sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    s.topiaId AS "topiaId",
    s.basketsPerSectionCount AS "basketsPerSectionCount",
    s.branchlinesPerBasketCount AS "branchlinesPerBasketCount",
    s.comment AS "comment",
    s.haulingBreaks AS "haulingBreaks",
    s.haulingDirectionSameAsSetting AS "haulingDirectionSameAsSetting",
    s.haulingEndLatitude AS "haulingEndLatitude",
    s.haulingEndLongitude AS "haulingEndLongitude",
    s.haulingEndTimeStamp AS "haulingEndTimeStamp",
    s.haulingStartLatitude AS "haulingStartLatitude",
    s.haulingStartLongitude AS "haulingStartLongitude",
    s.haulingStartTimeStamp AS "haulingStartTimeStamp",
    s.lightsticksPerBasketCount AS "lightsticksPerBasketCount",
    s.maxDepthTargeted AS "maxDepthTargeted",
    s.monitored AS "monitored",
    s.number AS "number",
    s.settingEndLatitude AS "settingEndLatitude",
    s.settingEndLongitude AS "settingEndLongitude",
    s.settingEndTimeStamp AS "settingEndTimeStamp",
    s.settingStartLatitude AS "settingStartLatitude",
    s.settingStartLongitude AS "settingStartLongitude",
    s.settingStartTimeStamp AS "settingStartTimeStamp",
    s.settingVesselSpeed AS "settingVesselSpeed",
    s.shooterSpeed AS "shooterSpeed",
    s.shooterUsed AS "shooterUsed",
    s.snapWeight AS "snapWeight",
    s.swivelWeight AS "swivelWeight",
    s.timeBetweenHooks AS "timeBetweenHooks",
    s.totalBasketsCount AS "totalBasketsCount",
    s.totalHooksCount AS "totalHooksCount",
    s.totalSectionsCount AS "totalSectionsCount",
    s.weightedSnap AS "weightedSnap",
    s.weightedSwivel AS "weightedSwivel",
    s.activity AS "activity",
    s.lightsticksColor AS "lightsticksColor",
    s.lightsticksType AS "lightsticksType",
    s.lineType AS "lineType",
    s.settingShape AS "settingShape"
FROM ll_observation.fishingSet AS s
JOIN ll_observation.activity AS a ON a.topiaId = s.activity
WHERE a.trip = $1::text
ORDER BY s.topiaId;
