-- here each of us will write their queries and procedures that we’ve written for each deliverable.
-- Trigger for club member status checking and updating 

-- This checks for valid age when registering, and checks each day to update Active / Inactivity
-- @block Check Member Age Trigger
DELIMITER //
CREATE TRIGGER check_member_age_before_insert
BEFORE INSERT ON ClubMembers
FOR EACH ROW
BEGIN
    DECLARE member_age INT;check_member_age_before_insert
   
    -- Calculate age at the time of registration
    SET member_age = TIMESTAMPDIFF(YEAR, NEW.dob, CURDATE());

    -- Enforce the age restriction
    IF member_age < 11 OR member_age > 18 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Member must be between 11 and 18 years old at registration.';
    ELSE
        SET NEW.status = 'Active';
    END IF;
END;

-- @block Update member statuses
CREATE EVENT update_member_status
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE ClubMembers
    SET status =
        CASE
            WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) BETWEEN 11 AND 18 THEN 'Active'
            ELSE 'Inactive'
        END;
END;
//
-- DELIMITER ;


-- Trigger to enforce global uniqueness of SSN

-- DELIMITER //
-- We want to check if ssn is valid across all locations where SSN is stored
-- @block Check ClubSSN universal
CREATE TRIGGER check_clubmember_ssn
BEFORE INSERT ON ClubMembers
FOR EACH ROW
BEGIN
    IF (EXISTS (SELECT ssn FROM FamilyMembers WHERE ssn = NEW.ssn))
     THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SSN already exists';
    END IF;
END;

-- @block Check FamilyMembers SSN
CREATE TRIGGER check_familymember_ssn
BEFORE INSERT ON FamilyMembers
FOR EACH ROW
BEGIN
    IF (EXISTS (SELECT ssn FROM ClubMembers WHERE ssn = NEW.ssn))
     THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SSN already exists';
    END IF;
END;
//
-- DELIMITER ;



-- Change delimiter from ';' to '//' to not get confused
-- DELIMITER //

-- Ensure only one location is marked as 'Head'
CREATE TRIGGER enforceSingleHead BEFORE INSERT ON Locations
FOR EACH ROW
BEGIN
	IF NEW.type = 'Head' THEN
    	IF (SELECT COUNT(*) FROM Locations WHERE type = 'Head') > 0 THEN
        	SIGNAL SQLSTATE '45000'
        	SET MESSAGE_TEXT = 'There can only be one Head location.';
    	END IF;
	END IF;
END //

-- Check if the club can operate (head location, general manager, and at least 1 administrator must exist)
CREATE PROCEDURE checkClubOperation()
BEGIN
	
	DECLARE headCount INT;
	DECLARE personnelCount INT;
	DECLARE adminCount INT;

	-- Check if there is at least one head location
	SELECT COUNT(*) INTO headCount FROM Locations WHERE type = 'Head';
	IF headCount = 0 THEN
    	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'The club cannot operate without a Head location.';
	END IF;

	-- Check if there is at least one general manager
	SELECT COUNT(*) INTO personnelCount FROM Personnel WHERE role = 'General Manager';
	IF personnelCount = 0 THEN
    	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'The club cannot operate without a General Manager.';
	END IF;

	-- Check if there is at least one administrator
	SELECT COUNT(*) INTO adminCount FROM Personnel WHERE role = 'Administrator';
	IF adminCount = 0 THEN
    	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'The club cannot operate without at least one Administrator.';
	END IF;
END //

-- Procedure to add a family member without specifying an ID
CREATE PROCEDURE addFamilyMember(
	IN pFirstName VARCHAR(100),
	IN pLastName VARCHAR(100),
	IN pDob DATE,
	IN pSsn VARCHAR(15),
	IN pMedicareCard VARCHAR(15),
	IN pPhoneNumber VARCHAR(15),
	IN pAddress VARCHAR(255),
	IN pCity VARCHAR(100),
	IN pProvince VARCHAR(100),
	IN pPostalCode VARCHAR(10),
	IN pEmail VARCHAR(100),
	IN pLocationId INT
)
BEGIN
	INSERT INTO FamilyMembers (
    firstName, 
    lastName, 
    dob, 
    ssn, 
    medicareCard, 
    phoneNumber, 
    address, 
    city, 
    province, 
    postalCode, 
    email, 
    locationId
  )
	VALUES (
    pFirstName, 
    pLastName, 
    pDob, 
    pSsn, 
    pMedicareCard, 
    pPhoneNumber, 
    pAddress, 
    pCity, 
    pProvince, 
    pPostalCode, 
    pEmail, 
    pLocationId
  );
END //

-- Procedure to remove family members who are no longer linked to club members
CREATE PROCEDURE pruneUnlinkedFamilyMembers()
BEGIN
	DELETE FROM FamilyMembers
	WHERE familyMemberId IN (
    	SELECT fm.familyMemberId
    	FROM FamilyMembers fm
    	LEFT JOIN ClubMembers cm ON fm.familyMemberId = cm.familyMemberId
    	WHERE cm.familyMemberId IS NULL
	);
END;


-- DELIMITER ;




-- DELIMITER //

CREATE PROCEDURE MembersToContact()
BEGIN
	-- Define age range
	DECLARE minAge INT DEFAULT 18;
	DECLARE maxAge INT DEFAULT 65;
	DECLARE nextMembershipPeriod INT;

	-- Calculate the next membership period
	SET nextMembershipPeriod = YEAR(CURDATE()) + 1;

	-- Retrieve members not in good financial standing
	SELECT p.firstName, p.lastName, p.email, p.phoneNumber
	FROM ClubMembers cm
	JOIN Payments pay ON cm.clubMemberNumber = pay.clubMemberNumber
	JOIN FamilyMembers fm ON cm.familyMemberId = fm.familyMemberId
	WHERE pay.membershipPeriod = nextMembershipPeriod
	GROUP BY cm.clubMemberNumber
	HAVING SUM(pay.amount) < 100
	  AND TIMESTAMPDIFF(YEAR, cm.dob, CURDATE()) BETWEEN minAge AND maxAge;
END //

CREATE PROCEDURE CheckFinancialStatus(
	IN pClubMemberNumber INT,
	IN pMembershipPeriod INT,
	OUT pStatus VARCHAR(10)
)
BEGIN
	DECLARE totalPayment DECIMAL(10,2);

	-- Calculate total amount paid within the first 4 payments
	SELECT SUM(amount)
	INTO totalPayment
	FROM (
    	SELECT amount
    	FROM Payments
    	WHERE clubMemberNumber = pClubMemberNumber
    	AND membershipPeriod = pMembershipPeriod
    	ORDER BY paymentDate ASC
    	LIMIT 4
	) AS PaymentSummary;

	-- Determine financial status
	IF totalPayment IS NOT NULL AND totalPayment >= 100 THEN
    	SET pStatus = 'Active';
	ELSE
    	SET pStatus = 'Inactive';
	END IF;
END //

-- DELIMITER ;

-- Procedure to create new activity so long as club is operational, personnel responsible exists, and location exists

DELIMITER //

CREATE PROCEDURE newActivity(
	IN pActivityType VARCHAR(100),
	IN pActivityDate DATE,
	IN pPersonnelResponsible INT,
	IN pLocationId INT,
	IN pMaxParticipants INT
)
BEGIN
	
	CALL CheckClubOperation(); -- will throw an error if club does can’t operate

	DECLARE eventCount INT;
	DECLARE personnelExists INT;
	DECLARE locationExists INT;
    
	SELECT COUNT(*) INTO personnelExists
	FROM Personnel
	WHERE personnelID = pPersonnelResponsible;
    
	SELECT COUNT(*) INTO locationExists
	FROM Locations
	WHERE locationId = pLocationId;
    
	IF personnelExists > 0 AND locationExists > 0 THEN
    
    
    	SELECT COUNT(*) INTO eventCount
    	FROM Activities
    	WHERE activityDate = pActivityDate
        	AND locationId = pLocationId;
    
    	IF eventCount = 0 THEN
        	INSERT INTO Activities(
            activityType, 
            activityDate, 
            personnelId, 
            locationId, 
            maxParticipants
          )
        	VALUES (
            pActivityType, 
            pActivityDate, 
            personnelId, 
            locationId, 
            maxParticipants
          );
    	END IF;
	END IF;
END //

-- DELIMITER ;


-- Procedure to register a club member in an activity, so long as they are active and the activity date hasn’t passed

-- DELIMITER //

CREATE PROCEDURE registerParticipant(
	IN pParticipantId INT,
	IN pActivityId INT
)
BEGIN
	DECLARE activityExists INT;
	DECLARE memberExists INT;
	DECLARE memberStatus VARCHAR(100);
	DECLARE currentParticipants INT;
	DECLARE maxParticipants INT;
	DECLARE activityDate DATE;
    
    
	SELECT COUNT(*) INTO memberExists
	FROM ClubMembers
	WHERE memberId = pParticipantId;
    
	IF memberExists > 0 THEN
    	SELECT memberStatus 
      FROM ClubMembers 
      WHERE memberID = pParticipantId 
      INTO memberStatus;

    	IF memberStatus != "Active" THEN
        	SIGNAL SQLSTATE '45000'
        	SET MESSAGE_TEXT = "Member inactive, cannot be registered in activities.";
    	END IF;
	END IF;

	SELECT COUNT(*), activityDate, maxParticipants 
    INTO activityExists, activityDate, maxParticipants
	FROM Activities
	WHERE activityId = pActivityId;

    
	SELECT COUNT(*) INTO currentParticipants
	FROM ActivityRegistrations
	WHERE activityId = pActivityId;
    
    
	IF activityExists > 0
    	AND memberExists > 0
    	AND currentParticipants < maxParticipants  
    	AND activityDate > CURDATE() THEN
        	INSERT INTO ActivityRegistrations (memberId, activityId)
        	VALUES (pParticipantId, pActivityId);
	END IF;
END //

-- DELIMITER ;



-- DELIMITER //

CREATE PROCEDURE newContract(
	pPersonnelId INT,
	pLocationId INT,
	pStartDate DATE,
	pPosition VARCHAR(25),
	pMandate VARCHAR(25)
)
BEGIN
	DECLARE numActiveContracts INT;
    
	SELECT COUNT(*)
	FROM Contracts
	WHERE personnelId = pPersonnelId
    	AND endDate IS NULL
	INTO numActiveContracts;
    
	IF numActiveContracts > 0 THEN
    	UPDATE Contracts
    	SET endDate = CURDATE()
    	WHERE personnelId = pPersonnelId
        	AND endDate IS NULL
        	AND (position != pPosition OR mandate != pMandate OR locationId != pLocationId);
	END IF;
    
	IF numActiveContracts = 0 THEN
    	INSERT INTO Contracts(personnelId, locationId, startDate, position, mandate)
    	VALUES (pPersonnelId, pLocationId, pStartDate, pPosition, pMandate);
   	 
    	IF pPosition = "General Manager" THEN
        	UPDATE Locations
        	SET generalManagerId = pPersonnelId
        	WHERE locationId = pLocationId;
    	END IF;
	END IF;
END //

-- DELIMITER ;


-- Procedure to terminate all active contracts for given personnel
-- DELIMITER //

CREATE PROCEDURE terminateContract(pPersonnelId INT)
BEGIN
	DECLARE numActiveContracts INT;
    
	SELECT COUNT(*)
	FROM Contracts
	WHERE personnelId = pPersonnelId
    	AND endDate IS NULL
	INTO numActiveContracts;
    
	IF numActiveContracts > 0 THEN
    	UPDATE Contracts
    	SET endDate = CURDATE()
    	WHERE personnelId = pPersonnelId AND endDate IS NULL;
	END IF;
END //

DELIMITER ;



