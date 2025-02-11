f
--@block
CREATE TABLE Personnel (
    personnelID int AUTO_INCREMENT PRIMARY KEY,
    firstName varchar(255) NOT NULL,
    lastName varchar(255) NOT NULL,
    ssn int NOT NULL,
    locationID int,
    medicareNO int,
    dob date,
    email varchar(255),
    phone bigint,
    address text,
    postalCode varchar(255),
    city varchar(255),
    provinceCode varchar(2),
    CONSTRAINT UC_Personnel UNIQUE (ssn, medicareNO),
    @FOREIGN KEY (locationID) REFERENCES Locations(locationID)
);

--@block
CREATE TABLE FamilyMembers (
    familyMemberID int AUTO_INCREMENT PRIMARY KEY,
    locationID int,
    firstName varchar(255),
    lastName varchar(255),
    ssn INT NOT NULL,
    medicareNo INT,
    dob date,
    email varchar(255),
    phone bigint,
    address text,
    postalCode varchar(255),
    city varchar(255),
    provinceCode varchar(2),
    CONSTRAINT UC_FamilyMembers UNIQUE (ssn, medicareNo),
    FOREIGN KEY (locationID) REFERENCES Locations(locationID),
);

--@block
-- I need to enfore age constraints on the club members, which should be actively
-- checked by comparing DOB to current date
CREATE TABLE ClubMembers (
    memberID int AUTO_INCREMENT PRIMARY KEY,
    locationID int,
    familyMemberID int,
    relationship varchar(100) NOT NULL,
    firstName varchar(255),
    lastName varchar(255),
    ssn INT NOT NULL,
    medicareNo INT,
    height int,
    weight int,
    registrationDate date,
    status varchar(100),
    dob date,
    email varchar(255),
    phone bigint,
    address text,
    postalCode varchar(255),
    city varchar(255),
    provinceCode varchar(2),
    CHECK (status IN ('Active', 'Inactive')),
    CHECK (relationship IN ('Father', 'Mother', 'Grandfather', 'Grandmother', 'Tutor', 'Partner', 'Friend', 'Other')),
    CONSTRAINT UC_ClubMembers UNIQUE (ssn, medicareNo),
    FOREIGN KEY (locationID) REFERENCES Locations(locationID),
    FOREIGN KEY (familyMemberID) REFERENCES FamilyMembers(familyMemberID),
);
--@block
CREATE TABLE WorkHistory(
    personnelID int,
    locationID int,
    startDate date,
    endDate date,
    workrole varchar(100),
    CHECK (workrole IN ('General Manager', 'Administrator', 'Captain', 'Coach', 'Assistant Coach')),
    mandate varchar(20),
    CHECK (mandate IN ('Paid', 'Volunteer')),
    FOREIGN KEY (personnelID) REFERENCES Personnel(personnelID)
    FOREIGN KEY (locationID) REFERENCES Locations(locationID) 
);

--@block
CREATE TABLE Locations (
    locationID INT AUTO_INCREMENT PRIMARY KEY,
    webAddress TEXT,
    phone BIGINT,
    address TEXT,
    locationName TEXT,
    maxCapacity INT,
    postalCode VARCHAR(255),
    city VARCHAR(255),
    province VARCHAR(255),
    locationType VARCHAR(255),
    CHECK (locationType IN ('Head', 'Branch'))
    -- Head location has: the General manager, deputy manager, treasurer, secretary, and one or more administrators
);

--@block
-- This has a bunch of shit that I have no clue how to enforce
CREATE TABLE Payments(
    paymentID int AUTO_INCREMENT PRIMARY KEY,
    memberID int,
    paymentDate date,
    paymentAmount decimal(10,2),
    paymentMethod varchar(100),
    CHECK (paymentMethod IN ('Cash', 'Credit Card', 'Debit Card')),
    FOREIGN KEY (memberID) REFERENCES ClubMembers(memberID),
)


CREATE TABLE Teams (
    teamID INT AUTO_INCREMENT PRIMARY KEY,
    teamName VARCHAR(255) NOT NULL,
    maxPlayers INT,
    category VARCHAR(255),
    status VARCHAR(255),
    playingAt INT,
    coachedBy INT,
    FOREIGN KEY (playingAt) REFERENCES Locations(locationID),
    FOREIGN KEY (coachedBy) REFERENCES Personnel(personnelID),
);




--@------------------------------------------------------------------------------------------------------------
--@block
INSERT INTO Locations (webAddress,phone,address,locationName,maxCapacity,postalCode,city,province,locationType)
VALUES 
    ("location1.com",6042227564,"1234 big street", "Primary Location Superb",10,"H2X2L8","Montreal","Quebec","Head");


--@block
INSERT INTO personnel (personnelID,firstName,locationID,ssn,medicareNO,workrole,mandate) VALUES(
    1,
    "bob johnson",
    1,
    25,
    25,
    "General Manager",
    "Paid"
);


--@block
DROP TABLE clubmembers;
--@block
SELECT * FROM Personnel;
