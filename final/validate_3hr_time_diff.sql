DELIMITER $$

CREATE TRIGGER trg_validate_formation_time_conflict
BEFORE INSERT ON FormationEnrollments
FOR EACH ROW
BEGIN
    DECLARE new_session_time DATETIME;
    DECLARE new_session_date DATE;

    -- Get start time of the session for the new formation
    SELECT s.startTime, DATE(s.startTime) INTO new_session_time, new_session_date
    FROM TeamFormations tf
    JOIN Sessions s ON tf.sessionID = s.sessionID
    WHERE tf.formationID = NEW.formationID;

    -- Check for time conflicts with other formations the same player is enrolled in
    IF EXISTS (
        SELECT 1
        FROM FormationEnrollments fe
        JOIN TeamFormations tf2 ON fe.formationID = tf2.formationID
        JOIN Sessions s2 ON tf2.sessionID = s2.sessionID
        WHERE fe.clubMemberNo = NEW.clubMemberNo
          AND DATE(s2.startTime) = new_session_date
          AND ABS(TIMESTAMPDIFF(MINUTE, s2.startTime, new_session_time)) < 180
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot enroll player: session times are less than 3 hours apart on the same day.';
    END IF;
END$$

DELIMITER ;
