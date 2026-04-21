--
-- KMSKA Optimizations to the MySQL database
--
-- These optimisations are geared towards the KMSKA Catmandu Fix as part of the
-- Arthub platform. These queries will add a set of indices to the MySQL tables,
-- and a set of views to ease up querying the data.
--
-- You will need to import these SQL file before attempting to run the
-- Datahub::Factory::Arthub. Ideally, first run the tms:install command in the
-- Tmssync application, then run this SQL file against the database, then run tms:export
--

--
-- INDEXES

-- Procedure to drop and recreate indexes

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_RecreateIndex $$
CREATE PROCEDURE sp_RecreateIndex (
    IN tblName   VARCHAR(64),
    IN ndxName   VARCHAR(64),
    IN ndxCols   VARCHAR(512)
)
BEGIN
    DECLARE idxExists INT DEFAULT 0;
    DECLARE sqlStmt TEXT;

    SELECT COUNT(*)
    INTO idxExists
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = tblName
      AND index_name = ndxName;

    IF idxExists > 0 THEN
        SET sqlStmt = CONCAT(
            'ALTER TABLE `', tblName, '` ',
            'DROP INDEX `', ndxName, '`, ',
            'ADD INDEX `', ndxName, '` (', ndxCols, ')'
        );
    ELSE
        SET sqlStmt = CONCAT(
            'ALTER TABLE `', tblName, '` ',
            'ADD INDEX `', ndxName, '` (', ndxCols, ')'
        );
    END IF;

    PREPARE stmt FROM sqlStmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END $$

DROP FUNCTION IF EXISTS `uf_get_first_digits`$$

CREATE FUNCTION `uf_get_first_digits`(as_val VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN

    DECLARE retval VARCHAR(255);
    DECLARE i INT;
    DECLARE strlen INT;
    -- shortcut exit for special cases
    IF as_val IS NULL OR as_val = '' THEN
        RETURN as_val;
    END IF;
    -- initialize for loop
    SET retval = '';
    SET i = 1;
    SET strlen = CHAR_LENGTH(as_val);
    do_loop:
        LOOP
            IF i > strlen THEN
            LEAVE do_loop;
        END IF;
        IF SUBSTR(as_val,i,1) IN ('0','1','2','3','4','5','6','7','8','9') THEN
            SET retval = CONCAT(retval,SUBSTR(as_val,i,1));
        ELSE
            LEAVE do_loop;
        END IF;
        SET i = i + 1;
        END LOOP do_loop;

    RETURN retval;

END$$

DELIMITER ;


CALL sp_RecreateIndex('ObjTitles', 'ObjectID', 'ObjectID');
CALL sp_RecreateIndex('ObjTitles', 'LanguageID', 'LanguageID');
CALL sp_RecreateIndex('ObjTitles', 'TitleTypeID', 'TitleTypeID');
CALL sp_RecreateIndex('ObjTitles', 'DisplayOrder', 'DisplayOrder');
CALL sp_RecreateIndex('ObjTitles', 'Displayed', 'Displayed');
CALL sp_RecreateIndex('ObjTitles', 'Active', 'Active');
CALL sp_RecreateIndex('DDLanguages', 'LanguageID', 'LanguageID');
CALL sp_RecreateIndex('DDLanguages', 'ISO369v1Code', 'ISO369v1Code');
CALL sp_RecreateIndex('Classifications', 'ClassificationID', '`ClassificationID` , `Classification`');
CALL sp_RecreateIndex('ClassificationXRefs', 'ClassificationID', '`ClassificationID`, `ID`');
CALL sp_RecreateIndex('ConXrefDetails', 'ConXrefID', 'ConXrefID');
CALL sp_RecreateIndex('ConXrefDetails', 'ConstituentID', 'ConstituentID');
CALL sp_RecreateIndex('ConXrefs', 'ID', 'ID');
CALL sp_RecreateIndex('ConXrefs', 'ConXrefID', 'ConXrefID');
CALL sp_RecreateIndex('ConXrefs', 'RoleID', 'RoleID');
CALL sp_RecreateIndex('ConXrefs', 'RoleTypeID', 'RoleTypeID');
CALL sp_RecreateIndex('ConXrefs', 'TableID', 'TableID');
CALL sp_RecreateIndex('ConXrefs', 'DisplayOrder', 'DisplayOrder');
CALL sp_RecreateIndex('ObjContext', 'ObjectID', ' `ObjectID` , `Period`');
CALL sp_RecreateIndex('Objects', 'ObjectID', 'ObjectID');
CALL sp_RecreateIndex('Objects', 'ObjectNumber', 'ObjectNumber');
CALL sp_RecreateIndex('Constituents', 'ConstituentID', 'ConstituentID');
CALL sp_RecreateIndex('ConAltNames', 'ConstituentID', 'ConstituentID');
CALL sp_RecreateIndex('Dimensions', 'DimItemElemXrefID', '`DimItemElemXrefID` , `DimensionTypeID` ,  `PrimaryUnitID`');
CALL sp_RecreateIndex('DimensionTypes', 'DimensionTypeID', 'DimensionTypeID');
CALL sp_RecreateIndex('DimensionElements', 'ElementID', 'ElementID');
CALL sp_RecreateIndex('DimensionUnits', 'UnitID', 'UnitID');
CALL sp_RecreateIndex('DimItemElemXrefs', 'DimItemElemXrefID', 'DimItemElemXrefID');
CALL sp_RecreateIndex('DimItemElemXrefs', 'TableID', 'TableID');
CALL sp_RecreateIndex('DimItemElemXrefs', 'ID', 'ID');
CALL sp_RecreateIndex('DimItemElemXrefs', 'ElementID', 'ElementID');
CALL sp_RecreateIndex('Roles', 'RoleID', 'RoleID');
CALL sp_RecreateIndex('Terms', 'TermID', 'TermID');
CALL sp_RecreateIndex('ThesXrefs', 'ID', 'ID');
CALL sp_RecreateIndex('ThesXrefs', 'TermID', 'TermID');
CALL sp_RecreateIndex('ThesXrefs', 'ThesXrefTypeID', 'ThesXrefTypeID');
CALL sp_RecreateIndex('ThesXrefs', 'TableID', 'TableID');
CALL sp_RecreateIndex('UserFieldXrefs', 'UserFieldID', 'UserFieldID');
CALL sp_RecreateIndex('UserFieldXrefs', 'ID', 'ID');
CALL sp_RecreateIndex('Associations', 'AssociationID', '`AssociationID`, `ID1`, `ID2`, `RelationshipID`');
CALL sp_RecreateIndex('Relationships', 'RelationshipID', 'RelationshipID');
CALL sp_RecreateIndex('AltNums', 'AltNumID', ' `AltNumID` , `ID`');
CALL sp_RecreateIndex('AltNumDescriptions', 'AltNumDescriptionID', 'AltNumDescriptionID');
CALL sp_RecreateIndex('Departments', 'DepartmentID', 'DepartmentID');
CALL sp_RecreateIndex('Locations', 'LocationID', 'LocationID');
CALL sp_RecreateIndex('ObjLocations', 'ObjLocationID', '`ObjLocationID` , `LocationID`');
CALL sp_RecreateIndex('ObjComponents', 'ComponentID', '`ComponentID` , `CurrentObjLocID` , `ObjectID`');
CALL sp_RecreateIndex('MediaFiles', 'FileID', 'FileID');
CALL sp_RecreateIndex('MediaFiles', 'RenditionID', '`RenditionID`');
CALL sp_RecreateIndex('MediaFiles', 'PathID', '`PathID`');
CALL sp_RecreateIndex('MediaRenditions', 'RenditionID', '`RenditionID` , `MediaMasterID`');
CALL sp_RecreateIndex('MediaXrefs', 'MediaXrefID', 'MediaXrefID');
CALL sp_RecreateIndex('MediaXrefs', 'MediaMasterID', 'MediaMasterID');
CALL sp_RecreateIndex('MediaXrefs', 'ID', 'ID');
CALL sp_RecreateIndex('MediaXrefs', 'TableID', 'TableID');
CALL sp_RecreateIndex('TextEntries', 'ID', 'ID');
CALL sp_RecreateIndex('TextEntries', 'TextTypeID', 'TextTypeID');
CALL sp_RecreateIndex('ClassificationNotations', 'TermMasterID', 'TermMasterID');
CALL sp_RecreateIndex('StatusFlags', 'ObjectID', 'ObjectID');
CALL sp_RecreateIndex('AuthorityTranslations', 'ID', 'ID');
CALL sp_RecreateIndex('TermMasterThes', 'TermMasterID', 'TermMasterID');
CALL sp_RecreateIndex('Exhibitions', 'ExhibitionID', 'ExhibitionID');
CALL sp_RecreateIndex('Exhibitions', 'ProjectNumber', 'ProjectNumber');
CALL sp_RecreateIndex('Exhibitions', 'ExhibitionTitleID', 'ExhibitionTitleID');
CALL sp_RecreateIndex('ExhObjXrefs', 'ExhibitionID', 'ExhibitionID');
CALL sp_RecreateIndex('ExhObjXrefs', 'ObjectID', 'ObjectID');
CALL sp_RecreateIndex('ExhibitionTitles', 'ExhibitionTitleID', 'ExhibitionTitleID');
CALL sp_RecreateIndex('HistEvents', 'HistEventID', 'HistEventID');
CALL sp_RecreateIndex('VGSRPCONDITIONSS_RO', 'ConditionID', 'ConditionID');
CALL sp_RecreateIndex('VGSRPCONDITIONSS_RO', 'ID', 'ID');
CALL sp_RecreateIndex('VGSRPCONDITIONSS_RO', 'SURVEYTYPEID', 'SURVEYTYPEID');
CALL sp_RecreateIndex('vgsrpSurveyTypesS_RO', 'SurveyTypeID', 'SurveyTypeID');
CALL sp_RecreateIndex('vgsrpSurveyAttrTypesS_RO', 'AttributeTypeID', 'AttributeTypeID');
CALL sp_RecreateIndex('vgsrpCondLineItemsS_RO', 'AttributeTypeID', 'AttributeTypeID');
CALL sp_RecreateIndex('vgsrpCondLineItemsS_RO', 'ConditionID', 'ConditionID');
CALL sp_RecreateIndex('vgsrpCondLineItemsS_RO', 'CondLineItemID', 'CondLineItemID');
CALL sp_RecreateIndex('VGSRPMEDIAMASTERS_RO', 'MEDIAMASTERID', 'MEDIAMASTERID');
CALL sp_RecreateIndex('VGSRPMEDIAMASTERS_RO', 'PRIMARYRENDID', 'PRIMARYRENDID');
CALL sp_RecreateIndex('MediaPaths', 'PathID', 'PathID');
CALL sp_RecreateIndex('OSCCitaatvormen', 'ConditionID', 'ConditionID');

--

--
-- VIEWS

-- VIEW Constituents

CREATE OR REPLACE VIEW vconstituents AS
SELECT o.ObjectID as _id, o.ObjectNumber, c.ConstituentID, c.AlphaSort, c.DisplayName, c.BeginDate,
    a1.DisplayName AS FrenchDisplay, a1.AlphaSort AS FrenchAlphaSort,
    a2.DisplayName AS EnglishDisplay, a2.AlphaSort AS EnglishAlphaSort,
    a3.DisplayName AS GermanDisplay, a3.AlphaSort AS GermanAlphaSort,
    a4.DisplayName AS ItalianDisplay, a4.AlphaSort AS ItalianAlphaSort,
    a5.DisplayName AS SpanishDisplay, a5.AlphaSort AS SpanishAlphaSort,
    a6.DisplayName AS RussianDisplay, a6.AlphaSort AS RussianAlphaSort,
    a7.DisplayName AS ChineseDisplay, a7.AlphaSort AS ChineseAlphaSort,
    c.EndDate, c.BeginDateISO, c.EndDateISO, c.DisplayDate, r.Role as role_nl, at.Translation1 as role_en, at.Translation2 as role_fr, cr.DisplayOrder,
    te.TextEntry as copyright,
    te.Purpose as copyrightstatus
FROM Objects o
   INNER JOIN ConXrefs cr ON cr.ID = o.ObjectID AND cr.TableID = 108 AND cr.RoleTypeID = 1
   INNER JOIN (SELECT DISTINCT ConXrefID, ConstituentID FROM ConXrefDetails) cd ON cd.ConXRefID = cr.ConXrefID
   LEFT JOIN Roles r ON r.RoleID = cr.RoleID
   INNER JOIN Constituents c ON c.ConstituentID = cd.ConstituentID
   LEFT JOIN TextEntries te ON te.ID = c.ConstituentID AND te.TextTypeID = 64
   LEFT JOIN AuthorityTranslations at ON (r.RoleID = at.ID AND at.TableID = 149)
   LEFT JOIN ConAltNames a1 ON(a1.ConstituentID = c.ConstituentID AND a1.NameType = 'Frans')
   LEFT JOIN ConAltNames a2 ON(a2.ConstituentID = c.ConstituentID AND a2.NameType = 'Engels')
   LEFT JOIN ConAltNames a3 ON(a3.ConstituentID = c.ConstituentID AND a3.NameType = 'Duits')
   LEFT JOIN ConAltNames a4 ON(a4.ConstituentID = c.ConstituentID AND a4.NameType = 'Italiaans')
   LEFT JOIN ConAltNames a5 ON(a5.ConstituentID = c.ConstituentID AND a5.NameType = 'Spaans')
   LEFT JOIN ConAltNames a6 ON(a6.ConstituentID = c.ConstituentID AND a6.NameType = 'Russisch')
   LEFT JOIN ConAltNames a7 ON(a7.ConstituentID = c.ConstituentID AND a7.NameType = 'Chinees')
ORDER BY CAST(cr.DisplayOrder AS SIGNED);

-- VIEW Classifications

CREATE OR REPLACE VIEW vclassifications AS
SELECT o.ObjectID as _id, o.ObjectNumber, c.ClassificationID, c.Classification as classification_nl, at.Translation1 as classification_en, at.Translation2 as classification_fr FROM Objects o
  INNER JOIN ClassificationXRefs cr ON o.ObjectID = cr.ID
  INNER JOIN Classifications c ON c.ClassificationID = cr.ClassificationID
  LEFT JOIN AuthorityTranslations at ON (at.ID = c.ClassificationID AND at.TableID = 10)
ORDER BY CAST(cr.DisplayOrder AS SIGNED);

-- VIEW Periods

CREATE OR REPLACE VIEW vperiods AS
SELECT ObjectID as _id,
    Period as term
FROM ObjContext;

-- VIEW Dimensions

CREATE OR REPLACE VIEW vdimensions AS
SELECT o.ObjectID as _id,
    d.Dimension as dimension,
    t.DimensionType as type,
    e.Element as element,
    u.UnitName as unit,
    x.DisplayDimensions as display
FROM Objects o
LEFT JOIN
    DimItemElemXrefs x ON x.ID = o.ObjectID
INNER JOIN
    Dimensions d ON d.DimItemElemXrefID = x.DimItemElemXrefID
INNER JOIN
    DimensionUnits u ON u.UnitID = d.PrimaryUnitID
INNER JOIN
    DimensionTypes t ON t.DimensionTypeID = d.DimensionTypeID
INNER JOIN
    DimensionElements e ON e.ElementID = x.ElementID
WHERE
    x.TableID = '108'
ORDER BY
    e.Element = 'Dagmaat' DESC,
    e.Element = 'Volledig' DESC;

-- VIEW Objects

CREATE OR REPLACE VIEW vobjects AS
SELECT DISTINCT o.ObjectID as _id,
    t.Term as object,
    t.TermID,
    x.DisplayOrder
FROM Terms t,
    Objects o,
    ThesXrefs x
WHERE
    x.ID = o.ObjectID AND
    x.TermID = t.TermID AND
    x.ThesXrefTypeID = 3 AND
    x.DisplayOrder = (SELECT MIN(CAST(DisplayOrder AS SIGNED)) FROM ThesXrefs AS r WHERE r.ID = o.ObjectID AND r.ThesXrefTypeID = 3)
ORDER BY CAST(x.DisplayOrder AS SIGNED);

-- VIEW Subjects

CREATE OR REPLACE VIEW vsubjects AS
SELECT DISTINCT o.ObjectID as _id,
    t.Term as subject,
    t.TermID,
    x.DisplayOrder
FROM Terms t,
    Objects o,
    ThesXrefs x
WHERE
    x.TermID = t.TermID AND
    x.ID = o.ObjectID AND
    x.ThesXrefTypeID = 30 AND
    x.DisplayOrder = (SELECT MIN(CAST(DisplayOrder AS SIGNED)) FROM ThesXrefs AS r WHERE r.ID = o.ObjectID AND r.ThesXrefTypeID = 30)
ORDER BY CAST(x.DisplayOrder AS SIGNED);

-- VIEW Materials

CREATE OR REPLACE VIEW vmaterials AS
SELECT DISTINCT o.ObjectID as _id,
    t.Term as material,
    t.TermID,
    x.DisplayOrder
FROM Terms t,
    Objects o,
    ThesXrefs x
WHERE
    x.TermID = t.TermID AND
    x.ID = o.ObjectID AND
    x.ThesXrefTypeID = 5 AND
    x.DisplayOrder = (SELECT MIN(CAST(DisplayOrder AS SIGNED)) FROM ThesXrefs AS r WHERE r.ID = o.ObjectID AND r.ThesXrefTypeID = 5)
ORDER BY CAST(x.DisplayOrder AS SIGNED);

-- VIEW Techniques

CREATE OR REPLACE VIEW vtechniques AS
SELECT DISTINCT o.ObjectID as _id,
    t.Term as technique,
    t.TermID,
    x.DisplayOrder
FROM Terms t,
    Objects o,
    ThesXrefs x
WHERE
    x.TermID = t.TermID AND
    x.ID = o.ObjectID AND
    x.ThesXrefTypeID = 6 AND
    x.DisplayOrder = (SELECT MIN(CAST(DisplayOrder AS SIGNED)) FROM ThesXrefs AS r WHERE r.ID = o.ObjectID AND r.ThesXrefTypeID = 6)
ORDER BY CAST(x.DisplayOrder AS SIGNED);

-- VIEW Data PIDS

CREATE OR REPLACE VIEW vdatapids AS
SELECT o.ObjectNumber as _id,
    ref.ID,
    ref.fieldValue as dataPid
FROM UserFieldXrefs ref
INNER JOIN
    Objects o ON o.ObjectID = ref.ID
WHERE userFieldID = '44';

-- VIEW Work PIDS

CREATE OR REPLACE VIEW vworkpids AS
SELECT o.ObjectNumber as _id,
    ref.ID,
    ref.fieldValue as workPid
FROM UserFieldXrefs ref
INNER JOIN
    Objects o ON o.ObjectID = ref.ID
WHERE userFieldID = '46';

-- VIEW Representation PIDS

CREATE OR REPLACE VIEW vrepresentationpids AS
SELECT o.ObjectNumber as _id,
    ref.ID,
    ref.fieldValue as representationPid
FROM UserFieldXrefs ref
INNER JOIN
    Objects o ON o.ObjectID = ref.ID
WHERE userFieldID = '48';

-- VIEW ObjTitles

CREATE OR REPLACE VIEW vobjtitles AS
SELECT obj.ObjectNumber as _id,
    tit.titleID as titleid,
    tit.Title as title,
    l.ISO369v1Code as language,
    tit.TitleTypeID as titletypeid,
    tit.Displayed as displayed,
    tit.Active as active
FROM
    Objects obj
LEFT JOIN
    (
        SELECT ObjTitles.ObjectID,
            ObjTitles.titleID,
            ObjTitles.Title,
            ObjTitles.LanguageID,
            ObjTitles.TitleTypeID,
            ObjTitles.Displayed,
            ObjTitles.Active,
            ObjTitles.DisplayOrder
        FROM
            (
                SELECT ObjTitles.ObjectID,
                    ObjTitles.LanguageID,
                    ObjTitles.TitleTypeID,
                    MIN(CAST(ObjTitles.DisplayOrder AS SIGNED)) as displayorder
                FROM
                    (
                        SELECT ObjectID,
                            LanguageID,
                            MIN(CAST(TitleTypeID AS SIGNED)) as TitleTypeID
                        FROM
                            ObjTitles
                        WHERE
                            (TitleTypeID = 1 OR TitleTypeID = 2) AND Displayed = 1 AND Active = 1
                        GROUP BY
                            ObjectID,
                            LanguageID
                    ) AS lowestttid
                INNER JOIN ObjTitles ON ObjTitles.ObjectID = lowestttid.ObjectID
                           AND ObjTitles.LanguageID = lowestttid.LanguageID
                           AND ObjTitles.TitleTypeID = lowestttid.TitleTypeID
                GROUP BY
                    ObjectID,
                    LanguageID
            ) AS lowest
        INNER JOIN
            ObjTitles ON ObjTitles.ObjectID = lowest.ObjectID
            AND ObjTitles.LanguageID = lowest.LanguageID
            AND ObjTitles.TitleTypeID = lowest.TitleTypeID
            AND ObjTitles.DisplayOrder = lowest.displayorder
    ) AS tit ON tit.ObjectID = obj.ObjectID
INNER JOIN
    DDLanguages l ON l.LanguageID = tit.LanguageID AND l.ISO369v1Code <> ''
ORDER BY CAST(tit.DisplayOrder AS SIGNED);

-- VIEW Departments

CREATE OR REPLACE VIEW vdepartments AS
SELECT o.ObjectID as _id,
    d.DepartmentID,
    d.Department as department
FROM Objects o,
    Departments d
WHERE
    o.DepartmentID = d.DepartmentID;

-- VIEW Relations

CREATE OR REPLACE VIEW vrelations AS
SELECT *,
IF(beforeSlash LIKE '%-%', SUBSTRING(beforeSlash, 1, INSTR(beforeSlash, '-') - 1), beforeSlash) AS first,
IF(beforeSlash LIKE '%-%', SUBSTRING(beforeSlash, INSTR(beforeSlash, '-') + 1), 999999999) AS second,
IF(afterSlash LIKE '%-%', SUBSTRING(afterSlash, 1, INSTR(afterSlash, '-') - 1), afterSlash) AS third,
IF(afterSlash LIKE '%-%', SUBSTRING(afterSlash, INSTR(afterSlash, '-') + 1), 999999999) AS fourth
FROM
(
    SELECT *,
    IF(relatedObjectNumber LIKE '%/%', SUBSTRING(relatedObjectNumber, 1, INSTR(relatedObjectNumber, '/') - 1), relatedObjectNumber) AS beforeSlash,
    IF(relatedObjectNumber LIKE '%/%', SUBSTRING(relatedObjectNumber, INSTR(relatedObjectNumber, '/') + 1), 0) AS afterSlash
    FROM
    (
        (
        SELECT DISTINCT o.ObjectID as _id,
            obj.ObjectNumber as relatedObjectNumber,
            r.Relation2 as relationship,
            r.RelationshipID as relationshipID1,
            NULL as relationshipID2,
            n.AltNum as numbering,
            ad.AltNumDescription as descriptionNumbering
        FROM Objects o,
            Associations a
        INNER JOIN
            Relationships r ON r.RelationshipID = a.RelationshipID
        INNER JOIN
            Objects obj ON obj.ObjectID = a.ID2
        LEFT JOIN
            AltNums n ON n.ID = a.ID2
        LEFT JOIN
            AltNumDescriptions ad ON n.AltNumDescriptionID = ad.AltNumDescriptionID AND ad.AltNumDescription = 'paginanummer'
        WHERE
            o.ObjectID = a.ID1 AND r.RelationshipID <> 8
        )
        UNION
        (
        SELECT DISTINCT o.ObjectID as _id,
            obj.ObjectNumber as relatedObjectNumber,
            r.Relation1 as relationship,
            NULL as relationshipID1,
            r.RelationshipID as relationshipID2,
            n.AltNum as numbering,
            ad.AltNumDescription as descriptionNumbering
        FROM Objects o,
            Associations a
        INNER JOIN
            Relationships r ON r.RelationshipID = a.RelationshipID
        INNER JOIN
            Objects obj ON obj.ObjectID = a.ID1
        LEFT JOIN
            AltNums n ON n.ID = a.ID1
        LEFT JOIN
            AltNumDescriptions ad ON n.AltNumDescriptionID = ad.AltNumDescriptionID AND ad.AltNumDescription = 'paginanummer'
        WHERE
            o.ObjectID = a.ID2 AND r.RelationshipID <> 8
        )
    ) AS rel
) AS rel1
ORDER BY
-CAST(numbering AS UNSIGNED) DESC,
IF(first REGEXP '^[0-9].*$', LPAD(uf_get_first_digits(first), 30, 0), first),
CAST(uf_get_first_digits(second) AS UNSIGNED),
CAST(uf_get_first_digits(third) AS UNSIGNED),
IF(third LIKE '%(%', CAST(uf_get_first_digits(SUBSTRING_INDEX(third, '(', -1)) AS UNSIGNED), 1),
CAST(uf_get_first_digits(fourth) AS UNSIGNED),
relatedObjectNumber,
_id;

-- VIEW PageNumbers

CREATE OR REPLACE VIEW vpagenumbers AS
SELECT o.ObjectID as _id,
    a.AltNum as pageNumber
FROM Objects o
LEFT JOIN
    AltNums a ON a.ID = o.ObjectID
LEFT JOIN
    AltNumDescriptions ad ON ad.AltNumDescriptionID = a.AltNumDescriptionID
WHERE ad.AltNumDescription = 'paginanummer';

-- VIEW Locations

CREATE OR REPLACE VIEW vlocations AS
SELECT o.ObjectID as _id,
    l.Room as room_nl,
    at.Translation1 as room_en,
    at.Translation2 as room_fr
FROM Locations l
INNER JOIN
    ObjLocations ol ON l.LocationID = ol.LocationID
INNER JOIN
    ObjComponents oc ON ol.ObjLocationID = oc.CurrentObjLocID
INNER JOIN
    Objects o ON oc.ObjectID = o.ObjectID
LEFT JOIN
    AuthorityTranslations at ON (at.ID = l.LocationID AND at.TableID = 83)
WHERE
    l.Site = 'publieksruimte';

-- VIEW TextEntries

CREATE OR REPLACE VIEW vtextentries AS
SELECT o.ObjectID as _id,
    REPLACE(t.TextEntry, '\r', '') as textEntry,
    t.LanguageID as languageid,
    t.TextTypeID as textTypeID
FROM TextEntries t
INNER JOIN
    Objects o ON t.ID = o.ObjectID
WHERE
    t.Purpose = 'Update Collectie-Informatie' AND t.TextTypeID IN(107, 110, 113, 117) AND t.TextStatusID = 8;

-- VIEW Clusters

-- CREATE OR REPLACE VIEW vclusters AS
-- SELECT o.ObjectID as _id,
--     u.FieldValue as cluster
-- FROM UserFieldXrefs u
-- INNER JOIN
--     Objects o ON u.ID = o.ObjectID
-- Where
--     u.UserFieldID = 108;

-- VIEW Halls

-- CREATE OR REPLACE VIEW vhalls AS
-- SELECT o.ObjectID as _id,
--     u.FieldValue as hall
-- FROM UserFieldXrefs u
-- INNER JOIN
--     Objects o ON u.ID = o.ObjectID
-- Where
--     u.UserFieldID = 107;

-- VIEW Provenance

CREATE OR REPLACE VIEW vprovenance AS
SELECT ObjectID as _id,
    ObjectNumber as objectNumber,
    REPLACE(Provenance, '\r', '') as provenance
FROM Objects;

-- VIEW AAT

CREATE OR REPLACE VIEW vaat AS
SELECT DISTINCT o.ObjectID as _id,
    o.ObjectNumber as objectNumber,
    t.Term as term,
    c.CN as path,
    tx.DisplayOrder
FROM ThesXrefs tx
INNER JOIN
    Terms t ON tx.TermID = t.TermID
INNER JOIN
    Objects o ON tx.ID = o.ObjectID
INNER JOIN
    ClassificationNotations c on t.TermMasterID = c.TermMasterID
WHERE
    tx.TableID = '108' AND tx.ThesXrefTypeID = '39' AND
    tx.DisplayOrder = (SELECT MIN(CAST(DisplayOrder AS SIGNED)) FROM ThesXrefs AS r WHERE r.ID = o.ObjectID AND r.TableID = '108' AND r.ThesXrefTypeID = '39')
ORDER BY CAST(tx.DisplayOrder AS SIGNED);

-- VIEW Iconclass

CREATE OR REPLACE VIEW viconclass AS
SELECT DISTINCT o.ObjectID AS _id,
    o.ObjectNumber AS objectNumber,
    t.Term AS term,
    c.CN AS path,
    tx.DisplayOrder,
    tm.SourceTermID,
    tm.TermSource
FROM ThesXrefs AS tx
INNER JOIN
    Terms AS t ON tx.TermID = t.TermID
INNER JOIN
    Objects AS o ON tx.ID = o.ObjectID
INNER JOIN
    ClassificationNotations AS c ON t.TermMasterID = c.TermMasterID
INNER JOIN
    TermMasterThes AS tm ON t.TermMasterID = tm.TermMasterID
WHERE
    tx.TableID = '108' AND tx.ThesXrefTypeID = '35'
ORDER BY CAST(tx.DisplayOrder AS SIGNED);

-- VIEW LinkLibrary

CREATE OR REPLACE VIEW vlinklibrary AS
SELECT ObjectID as _id,
    ObjectNumber as objectNumber,
    UserNumber1 as link
FROM Objects
WHERE
    UserNumber1 <> '';

-- VIEW LinkArchive

CREATE OR REPLACE VIEW vlinkarchive AS
SELECT o.ObjectID as _id,
    o.ObjectNumber as objectNumber,
    mf.FileName as link
FROM MediaXrefs m
INNER JOIN
    Objects o ON m.ID = o.ObjectID
INNER JOIN
    MediaRenditions mr ON m.MediaMasterID = mr.MediaMasterID
INNER JOIN
    MediaFiles mf ON mr.RenditionID = mf.RenditionID
WHERE
    m.TableID = '108' AND mf.PathID = 23
ORDER BY CAST(m.DisplayOrder AS SIGNED);

-- VIEW Acquisition

CREATE OR REPLACE VIEW vacquisition AS
SELECT o.ObjectID as _id,
    o.ObjectNumber as objectNumber,
    r.Role as role_nl,
    at.Translation1 as role_en,
    at.Translation2 as role_fr,
    con.DisplayName AS name,
    con.ConstituentID AS constituentID,
    cd.DisplayDate as date
FROM
    Objects o
INNER JOIN
    ConXrefs c ON o.ObjectID = c.ID
INNER JOIN
    Roles r ON r.RoleID = c.RoleID
INNER JOIN
    ConXrefDetails cd ON cd.ConXrefID = c.ConXrefID
LEFT OUTER JOIN
    Constituents con ON cd.ConstituentID = con.ConstituentID
LEFT JOIN
    AuthorityTranslations at ON (at.ID = r.RoleID AND at.TableID = 149)
WHERE
    c.RoleTypeID = 2 AND c.TableID = 108 AND c.Displayed = 1 AND cd.UnMasked = 1 AND r.Role IS NOT NULL AND con.DisplayName IS NOT NULL AND at.TableID = 149
ORDER BY
    CAST(c.DisplayOrder AS SIGNED);

-- VIEW ObjectNames

CREATE OR REPLACE VIEW vobjectnames AS
SELECT o.ObjectID as _id,
    o.ObjectNumber as objectNumber,
    n.ObjectName as objectName,
    n.ObjectNameID as objectNameID,
    n.ObjectNameTypeID as objectNameTypeID
FROM ObjectNames n
INNER JOIN
    Objects o ON n.ObjectID = o.ObjectID
ORDER BY CAST(n.DisplayOrder AS SIGNED);

-- VIEW Handling

CREATE OR REPLACE VIEW vhandling AS
SELECT o.ObjectID as _id,
    REPLACE(t.TextEntry, '\r', '') as textEntry,
    l.ISO369v1Code as language
FROM TextEntries t
INNER JOIN
    Objects o ON t.ID = o.ObjectID
INNER JOIN
    DDLanguages l ON l.LanguageID = t.LanguageID AND l.ISO369v1Code <> ''
WHERE
    t.TextTypeID = 116;

-- VIEW highlights

CREATE OR REPLACE VIEW vhighlights AS
SELECT o.ObjectID as _id
FROM Objects o
INNER JOIN StatusFlags f ON f.ObjectID = o.ObjectID
WHERE f.FlagID = 31;

-- VIEW collectionpresentation

CREATE OR REPLACE VIEW vcollectionpresentation AS
SELECT o.ObjectID as _id
FROM Objects o
INNER JOIN StatusFlags f ON f.ObjectID = o.ObjectID
WHERE f.FlagID = 50;

-- VIEW Translations

CREATE OR REPLACE VIEW vtranslations AS
SELECT o.ObjectID as _id,
    REPLACE(t.TextEntry, '\r', '') as textEntry,
    t.TextTypeID as textTypeID
FROM Objects o
INNER JOIN TextEntries t ON t.ID = o.ObjectID
WHERE t.TableID = 726 AND t.TextTypeID BETWEEN 118 AND 188
GROUP BY CONCAT(_id, textEntry, textTypeID);

-- VIEW Exhibitions

CREATE OR REPLACE VIEW vexhibitions AS
SELECT eo.ObjectID AS _id,
    eo.ExhibitionID AS exhibitionID,
    o.ObjectNumber AS objectNumber
FROM ExhObjXrefs AS eo
INNER JOIN Exhibitions AS e ON e.ExhibitionID = eo.ExhibitionID
INNER JOIN Objects AS o ON o.ObjectID = eo.ObjectID
WHERE e.ProjectNumber = 'Collectiepresentatie2022';

-- VIEW ExhibitionTitles

CREATE OR REPLACE VIEW vexhibitiontitles AS
SELECT e.ExhibitionID AS _id,
    et.Title AS title
FROM Exhibitions AS e
INNER JOIN ExhibitionTitles AS et ON et.ExhibitionTitleID = e.ExhibitionTitleID
WHERE e.ProjectNumber = 'Collectiepresentatie2022';

-- VIEW ExhibitionTexts

CREATE OR REPLACE VIEW vexhibitiontexts AS
SELECT e.ExhibitionID AS _id,
    et.Title AS title,
    te.Remarks AS name,
    te.TextEntry AS textEntry,
    tt.TextTypeID AS textTypeID,
    tt.TextType AS textType
FROM Exhibitions AS e
INNER JOIN ExhibitionTitles AS et ON et.ExhibitionTitleID = e.ExhibitionTitleID
INNER JOIN TextEntries AS te ON te.ID = e.ExhibitionID
INNER JOIN TextTypes AS tt ON tt.TextTypeID = te.TextTypeID
WHERE e.ProjectNumber = 'Collectiepresentatie2022' AND tt.TextTypeID IN(162, 164, 165, 166, 167, 168, 169, 170, 171);

-- VIEW AppNumbers

CREATE OR REPLACE VIEW vappnumbers AS
SELECT o.ObjectID as _id,
    a.AltNum as appNumber
FROM Objects AS o
INNER JOIN AltNums AS a ON o.ObjectID = a.ID
LEFT JOIN AltNumDescriptions AS ad ON a.AltNumDescriptionID = ad.AltNumDescriptionID
WHERE ad.AltNumDescription = 'App nr';

-- VIEW OSCTexts

CREATE OR REPLACE VIEW vosctexts AS
SELECT h.EventName AS eventName,
    te.TextEntry AS textEntry,
    te.LanguageID AS languageID,
    tt.TextType AS textType
FROM TextTypes tt
INNER JOIN TextEntries te ON tt.TextTypeID = te.TextTypeID
INNER JOIN HistEvents h ON te.ID = h.HistEventID
WHERE tt.TableID = 187 AND h.EventName LIKE 'OSC%';

-- VIEW OSCObjectTexts

CREATE OR REPLACE VIEW voscobjecttexts AS
SELECT o.ObjectID AS _id,
    c.PROJECT AS project,
    c.REPORTISODATE AS date,
    cl.BriefDescription AS briefDescription,
    cl.Statement AS statement,
    cl.Proposal AS footnotes,
    sa.AttributeType AS attributeType
FROM Objects o
INNER JOIN VGSRPCONDITIONSS_RO c ON o.ObjectID = c.ID
INNER JOIN vgsrpCondLineItemsS_RO cl ON c.CONDITIONID = cl.ConditionID
INNER JOIN vgsrpSurveyTypesS_RO st ON c.SURVEYTYPEID = st.SurveyTypeID
INNER JOIN vgsrpSurveyAttrTypesS_RO sa ON cl.AttributeTypeID = sa.AttributeTypeID
WHERE c.PROJECT LIKE 'OSC%'
    AND st.SurveyType = 'OSC';

-- VIEW OSCAAT

CREATE OR REPLACE VIEW voscaat AS
SELECT o.ObjectID AS _id,
    t.Term AS Term,
    t.LanguageID AS languageID
FROM VGSRPCONDITIONSS_RO c
INNER JOIN ThesXrefs tx ON c.CONDITIONID = tx.ID
INNER JOIN Terms t ON tx.TermID = t.TermID
INNER JOIN Objects o ON c.ID = o.ObjectID
WHERE c.PROJECT LIKE 'OSC%' AND tx.ThesXrefTypeID = 29;

-- VIEW OSCManifests

CREATE OR REPLACE VIEW voscmanifests AS
SELECT o.ObjectID AS _id,
    CONCAT(mp.Path, mf.FileName) AS manifest
FROM Objects o
    INNER JOIN VGSRPCONDITIONSS_RO c ON c.ID = o.ObjectID
    INNER JOIN vgsrpCondLineItemsS_RO cl ON c.CONDITIONID = cl.ConditionID
    INNER JOIN vgsrpSurveyTypesS_RO st ON c.SURVEYTYPEID = st.SurveyTypeID
    INNER JOIN vgsrpSurveyAttrTypesS_RO sa ON cl.AttributeTypeID = sa.AttributeTypeID
    INNER JOIN MediaXrefs mx ON cl.CondLineItemID = mx.ID
    INNER JOIN VGSRPMEDIAMASTERS_RO mm ON mx.MediaMasterID = mm.MEDIAMASTERID
    INNER JOIN MediaFiles mf ON mm.PRIMARYRENDID = mf.RenditionID
    INNER JOIN MediaPaths mp ON mf.PathID = mp.PathID
WHERE c.PROJECT LIKE 'OSC%'
    AND st.SurveyType = 'OSC'
    AND cl.AttributeTypeID = 101
    AND sa.AttributeType = 'research image';

-- VIEW OSCCitations

CREATE OR REPLACE VIEW vosccitations AS
SELECT o.ObjectID as _id,
    ocv.TextType AS textType,
    ocv.TextEntry AS textEntry
FROM Objects o
    INNER JOIN VGSRPCONDITIONSS_RO c ON o.ObjectID = c.ID
    INNER JOIN vgsrpSurveyTypesS_RO st ON c.SURVEYTYPEID = st.SurveyTypeID
    INNER JOIN OSCCitaatvormen ocv ON c.CONDITIONID = ocv.ConditionID
WHERE c.PROJECT LIKE 'OSC%'
    AND st.SurveyType = 'OSC';
