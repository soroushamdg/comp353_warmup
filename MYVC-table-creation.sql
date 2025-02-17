CREATE DATABASE Volleyball;
USE Volleyball;

-- Create Tables

CREATE TABLE Personnel (
	personnelId INT AUTO_INCREMENT PRIMARY KEY,
	firstName VARCHAR(100),
	lastName VARCHAR(100),
	dob DATE,
	ssn VARCHAR(15) UNIQUE,
	medicareCard VARCHAR(15) UNIQUE,
	phoneNumber VARCHAR(15),
	address VARCHAR(255),
	city VARCHAR(100),
	province VARCHAR(100),
	postalCode VARCHAR(10),
	email VARCHAR(100)
);

CREATE TABLE Locations (
	locationId INT AUTO_INCREMENT PRIMARY KEY,
	locationName VARCHAR(255),
	address VARCHAR(255),
	city VARCHAR(100),
	province VARCHAR(100),
	postalCode VARCHAR(10),
	phoneNumber VARCHAR(15),
	webAddress VARCHAR(100),
	locationType ENUM('Head', 'Branch'),
	capacity INT CHECK (capacity >= 12),
	managerId INT UNIQUE,
	generalManagerId INT UNIQUE,
	FOREIGN KEY (managerId) REFERENCES Personnel(personnelId),
	FOREIGN KEY (generalManagerId) REFERENCES Personnel(personnelId)
);

CREATE TABLE Contracts(
	contractId int NOT NULL AUTO_INCREMENT PRIMARY KEY,
	personnelId int,
	locationId int,
	startDate date,
	endDate date,
	position ENUM('General Manager', 'Deputy Manager', 'Administrator', 'Coach', 'Assistant Coach', 'Other'),
	mandate ENUM('Paid', 'Volunteer'),
	FOREIGN KEY (personnelId) REFERENCES Personnel(personnelId),
	FOREIGN KEY (locationId) REFERENCES Locations(locationId)
);

CREATE TABLE FamilyMembers (
	familyMemberId INT AUTO_INCREMENT PRIMARY KEY,
	firstName VARCHAR(100),
	lastName VARCHAR(100),
	dob DATE,
	ssn VARCHAR(15) UNIQUE,
	medicareCard VARCHAR(15) UNIQUE,
	phoneNumber VARCHAR(15),
	address VARCHAR(255),
	city VARCHAR(100),
	province VARCHAR(100),
	postalCode VARCHAR(10),
	email VARCHAR(100),
	locationId INT,
	FOREIGN KEY (locationId) REFERENCES Locations(locationId)
);

CREATE TABLE ClubMembers (
	clubMemberNumber INT AUTO_INCREMENT PRIMARY KEY,
	firstName VARCHAR(100),
	lastName VARCHAR(100),
	dob DATE,
	height INT,
	weight INT,
	ssn VARCHAR(15) UNIQUE,
	medicareCard VARCHAR(15) UNIQUE,
	phoneNumber VARCHAR(15),
	address VARCHAR(255),
	city VARCHAR(100),
	province VARCHAR(100),
	postalCode VARCHAR(10),
	familyMemberId INT,
	status ENUM('Active', 'Inactive'),
	FOREIGN KEY (familyMemberId) REFERENCES FamilyMembers(familyMemberId)
);

CREATE TABLE Payments (
	paymentId INT AUTO_INCREMENT PRIMARY KEY,
	clubMemberNumber INT,
	membershipPeriod INT,
	paymentDate DATE,
	amount DECIMAL(10, 2),
	method ENUM('Cash', 'Debit', 'Credit'),
	FOREIGN KEY (clubMemberNumber) REFERENCES ClubMembers(clubMemberNumber)
);

CREATE TABLE Activities(
	activityId INT AUTO_INCREMENT PRIMARY KEY,
	activityType ENUM('Tournament', 'Training', 'Practice', 'Social', 'Other'),
	activityDate DATE,
	personnelId INT,
	maxParticipants INT,
	FOREIGN KEY (personnelId) REFERENCES Personnel(personnelId)
);

CREATE TABLE ActivityRegistrations (
	activityId INT,
	clubMemberNumber INT,
	FOREIGN KEY (activityId) REFERENCES Activity(activityId),
	FOREIGN KEY (clubMemberNumber) REFERENCES ClubMembers(clubMemberNumber),
	PRIMARY KEY (activityId, clubMemberNumber)
);

