DROP DATABASE MYVC;
CREATE DATABASE MYVC;
USE MYVC;
CREATE TABLE Addresses (
	addressID INT AUTO_INCREMENT PRIMARY KEY,
	address VARCHAR(255) UNIQUE NOT NULL,
	city VARCHAR(100),
	province VARCHAR(100),
	postalCode VARCHAR(10)
);
CREATE TABLE People (
	generalID INT AUTO_INCREMENT PRIMARY KEY,
	sin VARCHAR(15) UNIQUE,
	medicareNo VARCHAR(15) UNIQUE,
	dob DATE,
	firstName VARCHAR(100),
	lastName VARCHAR(100),
	telephoneNo VARCHAR(15),
	email VARCHAR(100),
	addressID INT,
	FOREIGN KEY (addressID) REFERENCES Addresses(addressID)
);
CREATE TABLE Personnel (
	personnelID INT AUTO_INCREMENT PRIMARY KEY,
	generalID INT UNIQUE,
	FOREIGN KEY (generalID) REFERENCES People(generalID)
);
CREATE TABLE FamilyMembers (
	famMemberID INT AUTO_INCREMENT PRIMARY KEY,
	generalID INT UNIQUE,
	FOREIGN KEY (generalID) REFERENCES People(generalID)
);
CREATE TABLE SecondaryFamMembers (
	secondaryFamID INT AUTO_INCREMENT PRIMARY KEY,
	telephoneNo VARCHAR(15),
	firstName VARCHAR(100),
	lastName VARCHAR(100)
);
CREATE TABLE PrimFamSecFamRelationship (
	famMemberID INT PRIMARY KEY,
	secondaryFamID INT,
	FOREIGN KEY (famMemberID) REFERENCES FamilyMembers(famMemberID),
	FOREIGN KEY (secondaryFamID) REFERENCES SecondaryFamMembers(secondaryFamID)
);
CREATE TABLE ClubMembers (
	clubMemberNo INT AUTO_INCREMENT PRIMARY KEY,
	generalID INT UNIQUE,
	height INT,
	weight INT,
	gender ENUM('M', 'F'),
	FOREIGN KEY (generalID) REFERENCES People(generalID)
);
CREATE TABLE ClubMemFamRelationship (
	clubMemberNo INT PRIMARY KEY,
	famMemberID INT NOT NULL,
	relationship ENUM(
		'Mother',
		'Father',
		'Sibling',
		'Partner',
		'Tutor',
		'Friend',
		'Grandmother',
		'Grandfather',
		'Uncle',
		'Aunt',
		'Other'
	) NOT NULL,
	FOREIGN KEY (clubMemberNo) REFERENCES ClubMembers(clubMemberNo),
	FOREIGN KEY (famMemberID) REFERENCES FamilyMembers(famMemberID)
);
CREATE TABLE Locations (
	locationID INT AUTO_INCREMENT PRIMARY KEY,
	locationType ENUM('Head', 'Branch') NOT NULL,
	maxCapacity INT NOT NULL,
	locationName VARCHAR(100),
	addressID INT UNIQUE NOT NULL,
	telephoneNo VARCHAR(15),
	webAddress VARCHAR(100),
	FOREIGN KEY (addressID) REFERENCES Addresses(addressID)
);
CREATE TABLE PlayingAt (
	clubMemberNo INT PRIMARY KEY,
	locationID INT NOT NULL,
	FOREIGN KEY (clubMemberNo) REFERENCES ClubMembers(clubMemberNo),
	FOREIGN KEY (locationID) REFERENCES Locations(locationID)
);
CREATE TABLE Teams (
	teamName VARCHAR(100) PRIMARY KEY,
	captainMemberNo INT NOT NULL,
	locationID INT NOT NULL,
	gender ENUM('M', 'F') NOT NULL,
	FOREIGN KEY (captainMemberNo) REFERENCES ClubMembers(clubMemberNo),
	FOREIGN KEY (locationID) REFERENCES Locations(locationID)
);
CREATE TABLE Sessions (
	sessionID INT AUTO_INCREMENT PRIMARY KEY,
	locationID INT,
	startTime DATETIME,
	sessionType ENUM('Training', 'Game'),
	FOREIGN KEY (locationID) REFERENCES Locations(locationID)
);
CREATE TABLE TeamFormations (
	formationID INT AUTO_INCREMENT PRIMARY KEY,
	teamName VARCHAR(100) NOT NULL,
	score INT,
	sessionID INT NOT NULL,
	FOREIGN KEY (teamName) REFERENCES Teams(teamName),
	FOREIGN KEY (sessionID) REFERENCES Sessions(sessionID)
);
CREATE TABLE FormationEnrollments (
	formationID INT NOT NULL,
	clubMemberNo INT NOT NULL,
	playerRole ENUM(
		'Outside Hitter',
		'Opposite',
		'Setter',
		'Middle Blocker',
		'Libero',
		'Defensive Specialist',
		'Serving Specialist'
	),
	CONSTRAINT PK_Enrollments PRIMARY KEY (formationID, clubMemberNo),
	FOREIGN KEY (formationID) REFERENCES TeamFormations(formationID),
	FOREIGN KEY (clubMemberNo) REFERENCES ClubMembers(clubMemberNo)
);
CREATE TABLE Contracts (
	contractID INT AUTO_INCREMENT PRIMARY KEY,
	locationID INT NOT NULL,
	personnelID INT NOT NULL,
	startDate DATE NOT NULL,
	endDate DATE,
	mandate ENUM('Volunteer', 'Paid') NOT NULL,
	personnelRole ENUM(
		'General Manager',
		'Deputy Manager',
		'Administrator',
		'Coach',
		'Assisant Coach',
		'Other'
	),
	FOREIGN KEY (locationID) REFERENCES Locations(locationID),
	FOREIGN KEY (personnelID) REFERENCES Personnel(personnelID)
);
CREATE TABLE Payments (
	paymentID INT AUTO_INCREMENT PRIMARY KEY,
	clubMemberNo INT,
	-- not putting as not null to allow for donations w/o member
	paymentDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	method ENUM('Credit', 'Debit', 'Cash'),
	amount DECIMAL(10, 2),
	FOREIGN KEY (clubMemberNo) REFERENCES ClubMembers(clubMemberNo)
);
CREATE TABLE EmailLogs (
	emailID INT AUTO_INCREMENT PRIMARY KEY,
	senderID INT NOT NULL,
	recipientID INT NOT NULL,
	messageSubject VARCHAR(100) NOT NULL,
	sendDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	messageBody VARCHAR(100) NOT NULL,
	FOREIGN KEY (senderID) REFERENCES People(generalID),
	FOREIGN KEY (recipientID) REFERENCES People(generalID)
);
