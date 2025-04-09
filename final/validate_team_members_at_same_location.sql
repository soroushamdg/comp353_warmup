DELIMITER $$

CREATE TRIGGER trg_validate_location_and_gender
BEFORE INSERT ON FormationEnrollments
FOR EACH ROW
BEGIN
    DECLARE member_location INT;
    DECLARE team_location INT;
    DECLARE member_gender CHAR(1);
    DECLARE team_gender CHAR(1);

    -- Get the club member's location
    SELECT locationID INTO member_location
    FROM PlayingAt
    WHERE clubMemberNo = NEW.clubMemberNo;

    -- Get the team location and gender via the formation
    SELECT t.locationID, t.gender INTO team_location, team_gender
    FROM TeamFormations tf
    JOIN Teams t ON tf.teamName = t.teamName
    WHERE tf.formationID = NEW.formationID;

    -- Get the club member's gender
    SELECT gender INTO member_gender
    FROM ClubMembers
    WHERE clubMemberNo = NEW.clubMemberNo;

    -- Check for nulls
    IF member_location IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Club member has no assigned location.';
    END IF;

    IF member_gender IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Club member has no assigned gender.';
    END IF;

    IF team_location IS NULL OR team_gender IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Team information is missing for the formation.';
    END IF;

    -- Check location match
    IF member_location != team_location THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot enroll player: location mismatch between team and club member.';
    END IF;

    -- Check gender match
    IF member_gender != team_gender THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot enroll player: gender mismatch between team and club member.';
    END IF;

END$$

DELIMITER ;
