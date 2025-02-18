-- Populating the tables

-- Personnel
INSERT INTO Personnel (firstName, lastName, dob, ssn, medicareCard, phoneNumber, address, city, province, postalCode)
VALUES
('John', 'Doe', '1985-03-25', '123-45-6789', 'A123456789', '123-456-7890', '123 Street', 'Montreal', 'Quebec', 'H1A 2B3'),
('Jane', 'Smith', '1990-07-15', '987-65-4321', 'B987654321', '987-654-3210', '456 Avenue', 'Montreal', 'Quebec', 'H2B 3C4'),
('Mark', 'Johnson', '1978-11-05', '567-89-0123', 'C123987654', '234-567-8901', '789 Boulevard', 'Laval', 'Quebec', 'H3C 4D5');

-- Locations
INSERT INTO Locations (locationName, address, city, province, postalCode, phoneNumber, webAddress, locationType, capacity, managerId, generalManagerId)
VALUES
('Head Office', '123 Club Road', 'Montreal', 'Quebec', 'H1A 1A1', '514-123-4567', 'www.myvc.club', 'Head', 50, 1, 1),
('Branch 1', '456 Branch St', 'Laval', 'Quebec', 'H2B 2B2', '450-123-4567', 'www.myvc-laval.club', 'Branch', 30, 2, 2);

-- FamilyMembers
INSERT INTO FamilyMembers (firstName, lastName, dob, ssn, medicareCard, phoneNumber, address, city, province, postalCode, email, locationId)
VALUES
('Alice', 'Brown', '1980-04-11', '246-80-1357', 'D123456789', '514-567-8901', '100 Maple St', 'Montreal', 'Quebec', 'H1A 3B4', 'alice.brown@email.com', 1),
('Bob', 'Davis', '1975-01-30', '135-79-2468', 'E987654321', '450-987-6543', '200 Oak St', 'Laval', 'Quebec', 'H2B 4C5', 'bob.davis@email.com', 2);

-- Activities
INSERT INTO Activities (activityType, activityDate, personnelId, maxParticipants)
VALUES
('Training', '2024-02-10', 2, 20),
('Tournament', '2024-02-20', 1, 12);

-- COULD NOT EXECUTE THE FOLLOWING STATEMENTS

-- ClubMembers
INSERT INTO ClubMembers (firstName, lastName, dob, height, weight, ssn, medicareCard, phoneNumber, address, city, province, postalCode, familyMemberId, status)
VALUES
('Charlie', 'Brown', '2007-03-18', 160, 50, '345-67-8901', 'F123456789', '514-678-9012', '101 Birch St', 'Montreal', 'Quebec', 'H1A 4C6', 1, 'Active'),
('David', 'Davis', '2005-08-22', 170, 65, '543-21-0987', 'G987654321', '450-876-5432', '202 Pine St', 'Laval', 'Quebec', 'H2B 5D7', 2, 'Inactive');

-- Payments
INSERT INTO Payments (clubMemberNumber, membershipPeriod, paymentDate, amount, method)
VALUES
(1, 2024, '2024-01-01', 100.00, 'Credit'),
(2, 2024, '2024-02-15', 100.00, 'Debit');


-- ActivityRegistrations
INSERT INTO ActivityRegistrations (activityId, clubMemberNumber)
VALUES
(1, 1),
(2, 1);
