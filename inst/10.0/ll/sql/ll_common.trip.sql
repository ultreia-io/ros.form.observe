-- ObServe 10.0 LL: ll_common.trip sheet.
-- $1: one ll_common.trip.topiaId, bound as a text parameter.
-- Bind the same trip ID to every sheet query.
-- Columns follow inst/10.0/ll/form.yaml; quoted aliases preserve field names.
SELECT
    t.topiaId AS "topiaId",
    t.endDate AS "endDate",
    t.ersId AS "ersId",
    t.generalComment AS "generalComment",
    t.logbookAvailability AS "logbookAvailability",
    t.logbookComment AS "logbookComment",
    t.noOfCrewMembers AS "noOfCrewMembers",
    t.observationAvailability AS "observationAvailability",
    t.observationComment AS "observationComment",
    t.startDate AS "startDate",
    t.captain AS "captain",
    t.departureHarbour AS "departureHarbour",
    t.landingDataEntryOperator AS "landingDataEntryOperator",
    t.landingHarbour AS "landingHarbour",
    t.logbookDataEntryOperator AS "logbookDataEntryOperator",
    t.logbookDataQuality AS "logbookDataQuality",
    t.logbookProgram AS "logbookProgram",
    t.observationDataEntryOperator AS "observationDataEntryOperator",
    t.observationDataQuality AS "observationDataQuality",
    t.observationMethod AS "observationMethod",
    t.observationProgram AS "observationProgram",
    t.observer AS "observer",
    t.ocean AS "ocean",
    t.sampleDataEntryOperator AS "sampleDataEntryOperator",
    t.tripType AS "tripType",
    t.vessel AS "vessel"
FROM ll_common.trip AS t
WHERE t.topiaId = $1::text
ORDER BY t.topiaId;
