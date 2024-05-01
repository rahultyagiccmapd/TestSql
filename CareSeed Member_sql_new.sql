with #cc as (
select    dc.*
,    MemberCode = did.IdentifierValue
from    DimCoverage dc
join    DimIdentifier did on    did.ResourceID = dc.CoveragePolicyHolderRefResourceID
and    did.ResourceTypeCode = 'PATIENT'
and    did.IdentifierTypeCode = 'MEMBID'
where    dc.CoverageIsCurrent = '1' and   dc.IsActive = 1
and    (dc.CoveragePeriodStartDate <> dc.CoveragePeriodEndDate or dc.CoveragePeriodEndDate = '12/31/9999') and    (dc.CoveragePeriodEndDate <= '12/31/2023' or dc.CoveragePeriodEndDate = '12/31/9999')) 

SELECT DISTINCT 'CleverCloud' AS DataSource     ,dp.PatientNum AS MemberCode
    ,FirstName=dpn.FirstName --The member's first name String
    ,[MiddleName] = dpn.MiddleName --The member's middle name String
    ,[LastName] = dpn.LastName     ,convert(VARCHAR(10), dp.dateofBirth, 101) AS DateofBirth
    ,dp.GenderCode AS Sex
    ,[Address1] = dpa.AddressLine1 --The first line of the member's address String
    ,[Address2] = dpa.AddressLine2 --The second line of the member's address String
    ,[City] = dpa.City --The member's city String
    ,[State] = dpa.STATE --The member's state String
    ,[ZipCode] = dpa.ZipCode --The member's ZIP code String
    ,[County] = dpa.County --The member's county String
    ,[PhoneNumber] = con.patienttelecomvalue --The member's phone number String
    ,[HealthPlanEmployee] = 0 --Whether the member is an employee of the health plan 1 for true or 0 for false
    ,'' AS Email
    ,    [Race] = CASE        
WHEN de.EthnicityDefinition = 'NOT PROVIDED/UNKNOWN'
          THEN 'UNKNOWN'
        WHEN de.EthnicityDefinition = 'ASIAN INDIAN'
            THEN 'ASIAN'
        WHEN de.EthnicityDefinition = 'ASIAN OR PACIFIC ISLANDER'
            THEN 'ASIAN'
          WHEN de.EthnicityDefinition = 'BLACK'
            THEN 'BlackOrAfricanAmerican'
when de.EthnicityDefinition in ('KOREAN','VIETNAMESE','CHINESE')  then 'ASIAN'
when de.EthnicityDefinition in ('HISPANIC','FILIPINO','CAMBODIAN/KHUMER','CAUCASIAN/WHITE','LAOTIAN')  then 'UNKNOWN'
else  de.EthnicityDefinition
        END
    ,[RaceSource] = 'HealthPlanDirect'
    ,[Ethnicity] = CASE         WHEN de.EthnicityDefinition = 'HISPANIC'
            THEN 'HispanicOrLatino'
        WHEN de.EthnicityDefinition = 'BLACK (NON-HISPANIC)'
            THEN 'NotHispanicOrLatino'
        WHEN de.EthnicityDefinition = 'WHITE (NON-HISPANIC)'
            THEN 'NotHispanicOrLatino'
        ELSE 'UNKNOWN'
        END
    ,[EthnicitySource] = 'HealthPlanDirect'
    ,[SpokenLanguage] =  case when dcm.CommunicationDisplay='ENGLISH' then 'English' else 'NonEnglish' end
    ,[SpokenLanguageSource] = 'HealthPlanDirect'
    ,[WrittenLanguage] =  case when dcm.CommunicationDisplay='ENGLISH' then 'English' else 'NonEnglish' end --The member's preferred language for written materials One of the following:
    ,[WrittenLanguageSource] = 'HealthPlanDirect' --The data source for the member's written language One of the following:
    ,[OtherLanguage] = case 
when dcm.CommunicationDisplay='ENGLISH' then 'English' else 'NonEnglish' end

--The member's other language needs One of the following:
    ,[OtherLanguageSource] = 'HealthPlanDirect' --The data source for the member's other language One of the following:
    ,[SubscriberCode] = null --The member's plan-defined, subscriber identifier String
    ,[Parent_FirstName] = NULL --The member's parent's first name String
    ,[Parent_MiddleInitial] = NULL --The member's parent's middle initial String
    ,[Parent_LastName] = NULL --The member's parent's last name String
    ,[Parent_Email] = NULL --The member's parent's e-mail address String ,dp.PatientId
--into    #temp
FROM DimPatient dp
left JOIN DimPatientName dpn ON dpn.PatientID = dp.PatientID
left JOIN #cc di ON di.CoveragePolicyHolderRefResourceID = dp.patientID
left join  (
    select  PatientId
    ,   AddressLine1
    ,   AddressLine2
    ,   City
    ,   State
    ,   ZipCode
    ,   County
    ,   rn = row_number() over (partition by PatientId order by isnull(EndDate, '12/31/9999') desc)
    from    DimPatientAddress
    ) dpa on dpa.patientId=dp.patientID and dpa.rn = 1
left JOIN DimPatientEthnicity dpe ON dpe.PatientID = dp.PatientID
left JOIN [dbo].[DimEthnicity] de ON de.EthnicityCode = dpe.EthnicityCode
left JOIN DimCommunication dcm ON dcm.CommunicationCode = dp.[CommunicationCode]
left join (
    select  PatientID
    ,   PatientTelecomValue
    ,   rn = ROW_NUMBER() over (partition by PatientId order by PatientTelecomRank)
    from    DimPatientTelecom
    where   telecomsystemCode='phone'
    ) con on con.patientID= dp.patientID and con.rn = 1