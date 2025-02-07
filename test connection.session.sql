
--@block
CREATE TABLE Personnel (
    personnelID int,
    firstName varchar(255),
    lastName varchar(255),
    locationID int,
    ssn int NOT NULL,
    medicareNO int,
    workrole varchar(100),
    mandate varchar(20),
    dob date,
    email varchar(255),
    phone bigint,
    address text,
    postalCode varchar(255),
    city varchar(255),
    provinceCode varchar(2),
    CHECK (workrole IN ('General Manager', 'Administrator', 'Captain', 'Coach', 'Assistant Coach')),
    CHECK (mandate IN ('Paid', 'Volunteer')),
    CONSTRAINT UC_Personnel UNIQUE (ssn, medicareNO),
    PRIMARY KEY (personnelID),
    FOREIGN KEY (locationID) REFERENCES Locations(locationID)
);

--@block
CREATE TABLE FamilyMembers (
    FamilyMemberID int,
    LocationID int,
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
    FOREIGN KEY (LocationID) REFERENCES Locations(LocationID),
    PRIMARY KEY (FamilyMemberID)  
);

--@block
-- I need to enfore age constraints on the club members, which should be actively
-- checked by comparing DOB to current date
CREATE TABLE ClubMembers (
    MemberID int AUTO_INCREMENT,
    LocationID int,
    FamilyMemberID int,
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
    FOREIGN KEY (LocationID) REFERENCES Locations(LocationID),
    FOREIGN KEY (FamilyMemberID) REFERENCES FamilyMembers(FamilyMemberID),
    PRIMARY KEY (MemberID)  
);
--@block
CREATE TABLE WorkHistory(
    personnelID int,
    locationID int,
    startDate date,
    endDate date,
    workrole varchar(100),
    FOREIGN KEY (personnelID) REFERENCES Personnel(personnelID),
    FOREIGN KEY (locationID) REFERENCES Locations(locationID)
    FOREIGN KEY (workrole) REFERENCES Personnel(workrole)
);

--@block
CREATE TABLE Locations (
    locationID int AUTO_INCREMENT,
    webAddress text,
    phone bigint,
    address text,
    locationName text,
    maxCapacity int,
    postalCode varchar(255),
    city varchar(255),
    province varchar(255),
    locationType varchar(255),
    PRIMARY KEY (locationID)
    -- Head location has: the General manager, deputy manager, treasurer, secretary, and one or more administrators
);

--@block
-- This has a bunch of shit that I have no clue how to enforce
CREATE TABLE Payments(
    paymentID int AUTO_INCREMENT,
    memberID int,
    paymentDate date,
    paymentAmount decimal(10,2),
    paymentMethod varchar(100),
    CHECK (paymentMethod IN ('Cash', 'Credit Card', 'Debit Card')),
    FOREIGN KEY (memberID) REFERENCES ClubMembers(MemberID),
    PRIMARY KEY (paymentID)
)
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