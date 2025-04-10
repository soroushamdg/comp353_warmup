------- Q7 ---------------------------
-- Get complete details for every location in the system.
-- For each location, include:
-- - address, city, province, postal code
-- - phone number, web address
-- - type (Head, Branch), max capacity
-- - name of the General Manager (personnelRole = 'General Manager')
-- - number of club members associated with the location
-- Results are sorted by province, then city (both ascending).

SELECT 
    l.locationID,
    a.address,
    a.city,
    a.province,
    a.postalCode,
    l.telephoneNo,
    l.webAddress,
    l.locationType,
    l.maxCapacity,
    CONCAT(p.firstName, ' ', p.lastName) AS generalManagerName,
    COUNT(cm.clubMemberNo) AS numberOfClubMembers
FROM Locations l
JOIN Addresses a ON l.addressID = a.addressID
-- Join Contracts to get personnel assigned to each location
LEFT JOIN Contracts c ON l.locationID = c.locationID AND c.personnelRole = 'General Manager'
-- Join Personnel and People to get the name of the general manager
LEFT JOIN Personnel per ON c.personnelID = per.personnelID
LEFT JOIN People p ON per.generalID = p.generalID
-- Join PlayingAt to count club members per location
LEFT JOIN PlayingAt pa ON l.locationID = pa.locationID
LEFT JOIN ClubMembers cm ON pa.clubMemberNo = cm.clubMemberNo
GROUP BY 
    l.locationID,
    a.address,
    a.city,
    a.province,
    a.postalCode,
    l.telephoneNo,
    l.webAddress,
    l.locationType,
    l.maxCapacity,
    generalManagerName
ORDER BY 
    a.province ASC,
    a.city ASC;


------- Q8 ---------------------------
-- For a given family member, retrieve:
-- - All secondary family members associated with them (name + phone)
-- - All club members associated with them (via ClubMemFamRelationship)
-- - For each club member:
--   - Location name they are playing at
--   - Club membership number
--   - First name, last name, DOB, SIN, Medicare number, telephone number
--   - Full address (address, city, province, postal-code)
--   - Relationship between club member and the family member

DELIMITER $$

CREATE PROCEDURE GetFamilyMemberAssociations(IN inputFamMemberID INT)
BEGIN
    -- Get details of all locations associated with the given family member,
    -- including secondary family members and club members related to the primary family member.
    SELECT
        -- Secondary Family Member Info
        sf.firstName AS secFamFirstName,
        sf.lastName AS secFamLastName,
        sf.telephoneNo AS secFamPhone,

        -- Club Member Info
        cm.clubMemberNo,
        p.firstName AS clubMemberFirstName,
        p.lastName AS clubMemberLastName,
        p.dob,
        p.sin,
        p.medicareNo,
        p.telephoneNo AS clubMemberPhone,
        a.address,
        a.city,
        a.province,
        a.postalCode,

        -- Location Info
        l.locationName,

        -- Relationship
        cmfr.relationship

    FROM FamilyMembers fm

    -- Join to Secondary Family Member(s)
    LEFT JOIN PrimFamSecFamRelationship psr ON fm.famMemberID = psr.famMemberID
    LEFT JOIN SecondaryFamMembers sf ON psr.secondaryFamID = sf.secondaryFamID

    -- Join to Club Members via ClubMemFamRelationship
    JOIN ClubMemFamRelationship cmfr ON fm.famMemberID = cmfr.famMemberID
    JOIN ClubMembers cm ON cmfr.clubMemberNo = cm.clubMemberNo

    -- Join to People and Address for Club Member details
    JOIN People p ON cm.generalID = p.generalID
    JOIN Addresses a ON p.addressID = a.addressID

    -- Join to Location via PlayingAt
    LEFT JOIN PlayingAt pa ON cm.clubMemberNo = pa.clubMemberNo
    LEFT JOIN Locations l ON pa.locationID = l.locationID

    WHERE fm.famMemberID = inputFamMemberID;
END $$

DELIMITER ;


------- Q9 ---------------------------
-- Get all team formations for a given location and week.
-- Includes session details, team info, score (null for future sessions),
-- head coach name, and player info (name and role).
-- Results sorted by session start day and time.

DELIMITER $$

CREATE PROCEDURE GetWeeklyFormationsByLocation(
    IN inputLocationID INT,
    IN weekStart DATETIME,
    IN weekEnd DATETIME
)
BEGIN
    SELECT
        coach.firstName AS coachFirstName,
        coach.lastName AS coachLastName,

        s.startTime,
        a.address,
        a.city,
        a.province,
        a.postalCode,
        s.sessionType,

        tf.teamName,
        tf.score,

        player.firstName AS playerFirstName,
        player.lastName AS playerLastName,
        fe.playerRole

    FROM TeamFormations tf
    JOIN Sessions s ON tf.sessionID = s.sessionID
    JOIN Locations l ON s.locationID = l.locationID
    JOIN Addresses a ON l.addressID = a.addressID
    JOIN Teams t ON tf.teamName = t.teamName

    LEFT JOIN Contracts c ON c.locationID = l.locationID 
        AND c.personnelRole = 'Coach'
    LEFT JOIN Personnel per ON c.personnelID = per.personnelID
    LEFT JOIN People coach ON per.generalID = coach.generalID

    JOIN FormationEnrollments fe ON tf.formationID = fe.formationID
    JOIN ClubMembers cm ON fe.clubMemberNo = cm.clubMemberNo
    JOIN People player ON cm.generalID = player.generalID

    WHERE s.locationID = inputLocationID
      AND s.startTime BETWEEN weekStart AND weekEnd

    ORDER BY DATE(s.startTime), TIME(s.startTime);
END $$

DELIMITER ;

------- Q10 ---------------------------




------- Q11 ---------------------------
-- Report on team formations per location for a given time period.
-- Includes training/game sessions and player counts.
-- Only shows locations with at least 2 game sessions.

SELECT
    l.locationName,

    -- Total training sessions at this location
    SUM(CASE WHEN s.sessionType = 'Training' THEN 1 ELSE 0 END) AS totalTrainingSessions,

    -- Total players in training sessions
    SUM(CASE WHEN s.sessionType = 'Training' THEN (
        SELECT COUNT(*)
        FROM FormationEnrollments fe
        WHERE fe.formationID = tf.formationID
    ) ELSE 0 END) AS totalTrainingPlayers,

    -- Total game sessions
    SUM(CASE WHEN s.sessionType = 'Game' THEN 1 ELSE 0 END) AS totalGameSessions,

    -- Total players in game sessions
    SUM(CASE WHEN s.sessionType = 'Game' THEN (
        SELECT COUNT(*)
        FROM FormationEnrollments fe
        WHERE fe.formationID = tf.formationID
    ) ELSE 0 END) AS totalGamePlayers

FROM Locations l

-- Sessions at this location
JOIN Sessions s ON s.locationID = l.locationID

-- Team formations at each session
JOIN TeamFormations tf ON tf.sessionID = s.sessionID

-- Filter by input date range
WHERE s.startTime BETWEEN '2025-01-01' AND '2025-05-31'

GROUP BY l.locationID, l.locationName

-- Only include locations with at least 2 game sessions
HAVING totalGameSessions >= 2

ORDER BY totalGameSessions DESC;

------- Q12 ---------------------------
-- Report of active club members never assigned to a formation
-- Includes location, contact info, and join date
-- Sorted by location name and club member number

SELECT
    cm.clubMemberNo,
    p.firstName,
    p.lastName,

    -- Age calculated from date of birth
    TIMESTAMPDIFF(YEAR, p.dob, CURDATE()) AS age,

    -- Contact info
    p.telephoneNo,
    p.email,

    -- Location name (current location)
    l.locationName

FROM ClubMembers cm

-- Join to get personal details
JOIN People p ON cm.generalID = p.generalID

-- Join to get current location (active members only)
JOIN PlayingAt pa ON cm.clubMemberNo = pa.clubMemberNo
JOIN Locations l ON pa.locationID = l.locationID

-- Exclude club members who are in any formation
WHERE cm.clubMemberNo NOT IN (
    SELECT DISTINCT clubMemberNo FROM FormationEnrollments
)

ORDER BY l.locationName ASC, cm.clubMemberNo ASC;


------- Q13 ---------------------------
-- Report on active club members who have only ever played as 'Outside Hitter'
-- and have at least one such assignment.
-- Sorted by location name and club member number

SELECT
    cm.clubMemberNo,
    p.firstName,
    p.lastName,
    TIMESTAMPDIFF(YEAR, p.dob, CURDATE()) AS age,
    p.telephoneNo,
    p.email,
    l.locationName

FROM ClubMembers cm

-- Join with People table for personal details
JOIN People p ON cm.generalID = p.generalID

-- Join with PlayingAt to ensure they're active and get location
JOIN PlayingAt pa ON cm.clubMemberNo = pa.clubMemberNo
JOIN Locations l ON pa.locationID = l.locationID

-- Only include those who:
-- (1) Have at least one formation role as 'Outside Hitter'
-- (2) Have never had any role that is NOT 'Outside Hitter'
WHERE cm.clubMemberNo IN (
    SELECT clubMemberNo
    FROM FormationEnrollments
    GROUP BY clubMemberNo
    HAVING 
        COUNT(*) >= 1 AND
        SUM(playerRole != 'Outside Hitter') = 0
)

ORDER BY l.locationName ASC, cm.clubMemberNo ASC;


------- Q14 ---------------------------


------- Q15 ---------------------------


------- Q16 ---------------------------

------- Q17 ---------------------------

------- Q18 ---------------------------



