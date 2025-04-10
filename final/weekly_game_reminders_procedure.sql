DELIMITER $$

CREATE PROCEDURE SendWeeklySessionReminders()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE sessID INT;
    DECLARE teamName VARCHAR(100);
    DECLARE sessionDateTime DATETIME;
    DECLARE sessionType ENUM('Training', 'Game');
    DECLARE locID INT;
    DECLARE address VARCHAR(255);
    DECLARE city VARCHAR(100);
    DECLARE province VARCHAR(100);
    DECLARE postalCode VARCHAR(10);
    DECLARE coachGeneralID INT;
    DECLARE coachFirstName VARCHAR(100);
    DECLARE coachLastName VARCHAR(100);
    DECLARE coachEmail VARCHAR(100);

    -- Cursor for sessions in the coming week
    DECLARE cur CURSOR FOR
        SELECT s.sessionID, tf.teamName, s.startTime, s.sessionType, t.locationID
        FROM Sessions s
        JOIN TeamFormations tf ON tf.sessionID = s.sessionID
        JOIN Teams t ON t.teamName = tf.teamName
        WHERE s.sessionType = 'Training'
          AND s.startTime >= NOW()
          AND s.startTime < DATE_ADD(NOW(), INTERVAL 7 DAY);

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO sessID, teamName, sessionDateTime, sessionType, locID;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Get address details
        SELECT a.address, a.city, a.province, a.postalCode
        INTO address, city, province, postalCode
        FROM Locations l
        JOIN Addresses a ON a.addressID = l.addressID
        WHERE l.locationID = locID;

        -- Get generalID of one coach at that location
        SELECT pe.generalID, pe.firstName, pe.lastName, pe.email
        INTO coachGeneralID, coachFirstName, coachLastName, coachEmail
        FROM Contracts c
        JOIN Personnel pr ON pr.personnelID = c.personnelID
        JOIN People pe ON pe.generalID = pr.generalID
        WHERE c.locationID = locID AND c.personnelRole = 'Coach'
        ORDER BY c.startDate DESC
        LIMIT 1;

        -- Send emails to players in the session
        INSERT INTO EmailLogs (senderID, recipientID, messageSubject, messageBody)
        SELECT 
            coachGeneralID,
            cm.generalID,
            CONCAT(teamName, ' ', DATE_FORMAT(sessionDateTime, '%W %d-%b-%Y %l:%i %p'), ' training session'),
            LEFT(CONCAT(
                'Player: ', p.firstName, ' ', p.lastName,
                ', Role: ', fe.playerRole,
                ', Captain: ', cap.firstName, ' ', cap.lastName, ', Email: ', cap.email,
                ', Session Type: ', sessionType,
                ', Address: ', address, ', ', city, ', ', province, ', ', postalCode
            ), 100)
        FROM FormationEnrollments fe
        JOIN TeamFormations tf ON tf.formationID = fe.formationID
        JOIN ClubMembers cm ON cm.clubMemberNo = fe.clubMemberNo
        JOIN People p ON p.generalID = cm.generalID
        JOIN Teams t ON t.teamName = tf.teamName
        JOIN ClubMembers capcm ON capcm.clubMemberNo = t.captainMemberNo
        JOIN People cap ON cap.generalID = capcm.generalID
        WHERE tf.sessionID = sessID;

    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;
