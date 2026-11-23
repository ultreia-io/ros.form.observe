-- ObServe 10.0 PS: ps_common.trip sheet.
-- $1: one ps_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ps/form.yaml; quoted aliases preserve field names.
SELECT
    q.topiaId AS "topiaId",
    q.activitiesAcquisitionMode AS "activitiesAcquisitionMode",
    q.endDate AS "endDate",
    q.ersId AS "ersId",
    q.fishingTime AS "fishingTime",
    q.formsUrl AS "formsUrl",
    q.generalComment AS "generalComment",
    q.historicalData AS "historicalData",
    q.landingTotalWeight AS "landingTotalWeight",
    q.localMarketTotalWeight AS "localMarketTotalWeight",
    q.loch AS "loch",
    q.logbookComment AS "logbookComment",
    q.observationComment AS "observationComment",
    q.reportsUrl AS "reportsUrl",
    q.startDate AS "startDate",
    q.timeAtSea AS "timeAtSea",
    q.advancedSamplingAcquisitionStatus AS "advancedSamplingAcquisitionStatus",
    q.captain AS "captain",
    q.departureHarbour AS "departureHarbour",
    q.departureWellContentStatus AS "departureWellContentStatus",
    q.landingAcquisitionStatus AS "landingAcquisitionStatus",
    q.landingHarbour AS "landingHarbour",
    q.landingWellContentStatus AS "landingWellContentStatus",
    q.localMarketAcquisitionStatus AS "localMarketAcquisitionStatus",
    q.localMarketSurveySamplingAcquisitionStatus AS "localMarketSurveySamplingAcquisitionStatus",
    q.localMarketWellsSamplingAcquisitionStatus AS "localMarketWellsSamplingAcquisitionStatus",
    q.logbookAcquisitionStatus AS "logbookAcquisitionStatus",
    q.logbookDataEntryOperator AS "logbookDataEntryOperator",
    q.logbookDataQuality AS "logbookDataQuality",
    q.logbookProgram AS "logbookProgram",
    q.observationAcquisitionStatus AS "observationAcquisitionStatus",
    q.observationDataEntryOperator AS "observationDataEntryOperator",
    q.observationDataQuality AS "observationDataQuality",
    q.observationProgram AS "observationProgram",
    q.observer AS "observer",
    q.ocean AS "ocean",
    q.targetWellsSamplingAcquisitionStatus AS "targetWellsSamplingAcquisitionStatus",
    q.vessel AS "vessel"
FROM ps_common.trip AS q
WHERE q.topiaId = $1::text
ORDER BY q.topiaId;
