-- Create a trigger to enforce a maximum of 2 team formations per session
DELIMITER $$

CREATE TRIGGER check_team_formations_limit
BEFORE INSERT ON TeamFormations
FOR EACH ROW
BEGIN
    -- Declare a variable to store the count of team formations for the session
    DECLARE formation_count INT;

    -- Count the number of team formations for the given session ID
    SELECT COUNT(*)
    INTO formation_count
    FROM TeamFormations
    WHERE sessionID = NEW.sessionID;

    -- If there are already 2 team formations for the session, raise an error
    IF formation_count >= 2 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot add more than 2 team formations for a single session.';
    END IF;
END$$

DELIMITER ;