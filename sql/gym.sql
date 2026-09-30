-- ============================================================
-- FITNESS & GYM MANAGEMENT SYSTEM
-- Database Implementation Script
-- SRH University | Final Project
-- ============================================================

-- ============================================================
-- SECTION 1: CREATE DATABASE
-- ============================================================

CREATE DATABASE IF NOT EXISTS GymManagementDB;
USE GymManagementDB;

-- ============================================================
-- SECTION 2: CREATE TABLES
-- ============================================================

-- Table 1: Members
CREATE TABLE Members (
    MemberID      INT           PRIMARY KEY AUTO_INCREMENT,
    FirstName     VARCHAR(50)   NOT NULL,
    LastName      VARCHAR(50)   NOT NULL,
    Email         VARCHAR(100)  NOT NULL UNIQUE,
    Phone         VARCHAR(20)   NOT NULL,
    DateOfBirth   DATE          NOT NULL,
    Gender        ENUM('Male','Female','Other') NOT NULL,
    Address       VARCHAR(200),
    JoinDate      DATE          NOT NULL DEFAULT (CURRENT_DATE),
    Status        ENUM('Active','Inactive','Suspended') NOT NULL DEFAULT 'Active'
);

-- Table 2: Membership Plans
CREATE TABLE MembershipPlans (
    PlanID        INT           PRIMARY KEY AUTO_INCREMENT,
    PlanName      VARCHAR(100)  NOT NULL UNIQUE,
    DurationMonths INT          NOT NULL,
    Price         DECIMAL(10,2) NOT NULL,
    Description   VARCHAR(255),
    MaxClassBookings INT        DEFAULT 10
);

-- Table 3: Subscriptions (Members ↔ Plans)
CREATE TABLE Subscriptions (
    SubscriptionID INT          PRIMARY KEY AUTO_INCREMENT,
    MemberID       INT          NOT NULL,
    PlanID         INT          NOT NULL,
    StartDate      DATE         NOT NULL,
    EndDate        DATE         NOT NULL,
    PaymentStatus  ENUM('Paid','Pending','Overdue') NOT NULL DEFAULT 'Pending',
    AmountPaid     DECIMAL(10,2),
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
    FOREIGN KEY (PlanID)   REFERENCES MembershipPlans(PlanID)
);

-- Table 4: Trainers
CREATE TABLE Trainers (
    TrainerID     INT           PRIMARY KEY AUTO_INCREMENT,
    FirstName     VARCHAR(50)   NOT NULL,
    LastName      VARCHAR(50)   NOT NULL,
    Email         VARCHAR(100)  NOT NULL UNIQUE,
    Phone         VARCHAR(20)   NOT NULL,
    Specialization VARCHAR(100) NOT NULL,
    HireDate      DATE          NOT NULL,
    HourlyRate    DECIMAL(10,2) NOT NULL,
    CertificationLevel VARCHAR(50) DEFAULT 'Level 1'
);

-- Table 5: Fitness Classes
CREATE TABLE FitnessClasses (
    ClassID       INT           PRIMARY KEY AUTO_INCREMENT,
    ClassName     VARCHAR(100)  NOT NULL,
    TrainerID     INT           NOT NULL,
    Schedule      DATETIME      NOT NULL,
    DurationMinutes INT         NOT NULL DEFAULT 60,
    MaxCapacity   INT           NOT NULL DEFAULT 20,
    Room          VARCHAR(50),
    ClassType     ENUM('Yoga','HIIT','Cycling','Pilates','Zumba','Strength','Cardio') NOT NULL,
    FOREIGN KEY (TrainerID) REFERENCES Trainers(TrainerID)
);

-- Table 6: Class Bookings (Members ↔ Classes)
CREATE TABLE ClassBookings (
    BookingID     INT           PRIMARY KEY AUTO_INCREMENT,
    MemberID      INT           NOT NULL,
    ClassID       INT           NOT NULL,
    BookingDate   DATE          NOT NULL DEFAULT (CURRENT_DATE),
    AttendanceStatus ENUM('Booked','Attended','Cancelled','No-Show') NOT NULL DEFAULT 'Booked',
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
    FOREIGN KEY (ClassID)  REFERENCES FitnessClasses(ClassID)
);

-- Table 7: Equipment
CREATE TABLE Equipment (
    EquipmentID   INT           PRIMARY KEY AUTO_INCREMENT,
    EquipmentName VARCHAR(100)  NOT NULL,
    Category      VARCHAR(50)   NOT NULL,
    PurchaseDate  DATE,
    Condition_    ENUM('Excellent','Good','Fair','Under Maintenance') NOT NULL DEFAULT 'Good',
    LastMaintained DATE,
    Location      VARCHAR(50)
);

-- Table 8: Personal Training Sessions
CREATE TABLE PersonalTrainingSessions (
    SessionID     INT           PRIMARY KEY AUTO_INCREMENT,
    MemberID      INT           NOT NULL,
    TrainerID     INT           NOT NULL,
    SessionDate   DATETIME      NOT NULL,
    DurationMinutes INT         NOT NULL DEFAULT 60,
    Notes         TEXT,
    Status        ENUM('Scheduled','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    FOREIGN KEY (MemberID)  REFERENCES Members(MemberID),
    FOREIGN KEY (TrainerID) REFERENCES Trainers(TrainerID)
);

-- Table 9: Payments
CREATE TABLE Payments (
    PaymentID     INT           PRIMARY KEY AUTO_INCREMENT,
    MemberID      INT           NOT NULL,
    Amount        DECIMAL(10,2) NOT NULL,
    PaymentDate   DATE          NOT NULL DEFAULT (CURRENT_DATE),
    PaymentMethod ENUM('Cash','Credit Card','Debit Card','Bank Transfer','Online') NOT NULL,
    Description   VARCHAR(255),
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

-- Table 10: MemberFitnessGoals
CREATE TABLE MemberFitnessGoals (
    GoalID        INT           PRIMARY KEY AUTO_INCREMENT,
    MemberID      INT           NOT NULL,
    GoalType      ENUM('Weight Loss','Muscle Gain','Endurance','Flexibility','General Fitness') NOT NULL,
    TargetDate    DATE,
    CurrentWeight DECIMAL(5,2),
    TargetWeight  DECIMAL(5,2),
    Notes         TEXT,
    Achieved      BOOLEAN       DEFAULT FALSE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

-- ============================================================
-- SECTION 3: SAMPLE DATA
-- ============================================================

-- Members (10 rows)
INSERT INTO Members (FirstName, LastName, Email, Phone, DateOfBirth, Gender, Address, JoinDate, Status) VALUES
('Ahmed',   'Al-Rashid',  'ahmed.rashid@email.com',   '+49-170-1234567', '1990-03-15', 'Male',   'Berliner Str. 12, Berlin',     '2024-01-10', 'Active'),
('Sofia',   'Müller',     'sofia.mueller@email.com',  '+49-171-2345678', '1995-07-22', 'Female', 'Hauptstr. 45, Hamburg',        '2024-02-15', 'Active'),
('James',   'Wilson',     'james.wilson@email.com',   '+49-172-3456789', '1988-11-05', 'Male',   'Gartenweg 8, Munich',          '2024-01-20', 'Active'),
('Priya',   'Sharma',     'priya.sharma@email.com',   '+49-173-4567890', '1993-05-30', 'Female', 'Schillerstr. 22, Frankfurt',   '2024-03-01', 'Active'),
('Lucas',   'Fernandez',  'lucas.fernandez@email.com','+49-174-5678901', '1997-09-12', 'Male',   'Rosestr. 5, Cologne',          '2024-03-10', 'Active'),
('Anna',    'Kowalski',   'anna.kowalski@email.com',  '+49-175-6789012', '1991-01-28', 'Female', 'Lindenweg 3, Berlin',          '2024-02-20', 'Inactive'),
('Marcus',  'Johnson',    'marcus.johnson@email.com', '+49-176-7890123', '1985-06-17', 'Male',   'Parkstr. 77, Stuttgart',       '2023-12-05', 'Active'),
('Lena',    'Becker',     'lena.becker@email.com',    '+49-177-8901234', '1999-04-09', 'Female', 'Waldweg 14, Dresden',          '2024-04-01', 'Active'),
('Omar',    'Hassan',     'omar.hassan@email.com',    '+49-178-9012345', '1992-08-25', 'Male',   'Kirchstr. 33, Leipzig',        '2024-01-30', 'Suspended'),
('Yuki',   'Tanaka',     'yuki.tanaka@email.com',    '+49-179-0123456', '1996-12-03', 'Female', 'Brunnenstr. 6, Berlin',        '2024-04-15', 'Active');

-- Membership Plans (5 rows)
INSERT INTO MembershipPlans (PlanName, DurationMonths, Price, Description, MaxClassBookings) VALUES
('Basic Monthly',    1,  29.99, 'Access to gym floor and basic equipment',               5),
('Standard Monthly', 1,  49.99, 'Full gym access + 5 group classes per month',           10),
('Premium Monthly',  1,  79.99, 'Unlimited gym access + unlimited classes + 1 PT session', 999),
('Standard Yearly',  12, 499.99,'Full gym access + 10 classes per month, billed annually',10),
('Student Plan',     1,  19.99, 'Discounted plan for students with valid ID',             5);

-- Subscriptions (10 rows)
INSERT INTO Subscriptions (MemberID, PlanID, StartDate, EndDate, PaymentStatus, AmountPaid) VALUES
(1,  3, '2024-01-10', '2024-02-10', 'Paid',    79.99),
(2,  2, '2024-02-15', '2024-03-15', 'Paid',    49.99),
(3,  4, '2024-01-20', '2025-01-20', 'Paid',   499.99),
(4,  2, '2024-03-01', '2024-04-01', 'Paid',    49.99),
(5,  1, '2024-03-10', '2024-04-10', 'Paid',    29.99),
(6,  1, '2024-02-20', '2024-03-20', 'Overdue', 0.00),
(7,  3, '2023-12-05', '2024-01-05', 'Paid',    79.99),
(8,  5, '2024-04-01', '2024-05-01', 'Pending', 19.99),
(9,  2, '2024-01-30', '2024-02-29', 'Overdue', 0.00),
(10, 3, '2024-04-15', '2024-05-15', 'Paid',    79.99);

-- Trainers (6 rows)
INSERT INTO Trainers (FirstName, LastName, Email, Phone, Specialization, HireDate, HourlyRate, CertificationLevel) VALUES
('Karl',    'Weber',    'karl.weber@gym.com',    '+49-170-1111111', 'Strength & Conditioning', '2021-06-01', 45.00, 'Level 3'),
('Maria',   'Santos',   'maria.santos@gym.com',  '+49-170-2222222', 'Yoga & Pilates',          '2022-01-15', 40.00, 'Level 2'),
('David',   'Kim',      'david.kim@gym.com',     '+49-170-3333333', 'HIIT & Cardio',           '2022-07-10', 42.00, 'Level 3'),
('Emma',    'Hoffmann', 'emma.hoffmann@gym.com', '+49-170-4444444', 'Zumba & Dance Fitness',   '2023-03-01', 38.00, 'Level 2'),
('Raj',     'Patel',    'raj.patel@gym.com',     '+49-170-5555555', 'Cycling & Endurance',     '2023-09-01', 40.00, 'Level 2'),
('Claudia', 'Richter',  'claudia.richter@gym.com','+49-170-6666666','Nutrition & Weight Loss', '2021-11-01', 50.00, 'Level 3');

-- Fitness Classes (8 rows)
INSERT INTO FitnessClasses (ClassName, TrainerID, Schedule, DurationMinutes, MaxCapacity, Room, ClassType) VALUES
('Morning Yoga Flow',      2, '2024-05-06 07:00:00', 60,  15, 'Studio A', 'Yoga'),
('Power HIIT',             3, '2024-05-06 09:00:00', 45,  20, 'Main Hall','HIIT'),
('Spin Cycle Express',     5, '2024-05-06 18:00:00', 45,  16, 'Cycle Room','Cycling'),
('Zumba Party',            4, '2024-05-07 10:00:00', 60,  25, 'Studio B', 'Zumba'),
('Core & Strength',        1, '2024-05-07 17:00:00', 60,  18, 'Main Hall','Strength'),
('Pilates Fundamentals',   2, '2024-05-08 08:00:00', 60,  12, 'Studio A', 'Pilates'),
('Cardio Blast',           3, '2024-05-08 12:00:00', 30,  20, 'Main Hall','Cardio'),
('Evening Yoga',           2, '2024-05-09 19:00:00', 75,  15, 'Studio A', 'Yoga');

-- Class Bookings (12 rows)
INSERT INTO ClassBookings (MemberID, ClassID, BookingDate, AttendanceStatus) VALUES
(1,  1, '2024-05-01', 'Attended'),
(1,  2, '2024-05-01', 'Attended'),
(2,  1, '2024-05-01', 'Attended'),
(2,  4, '2024-05-02', 'Booked'),
(3,  5, '2024-05-02', 'Attended'),
(4,  2, '2024-05-02', 'Attended'),
(4,  7, '2024-05-03', 'Cancelled'),
(5,  3, '2024-05-03', 'Booked'),
(7,  2, '2024-05-01', 'No-Show'),
(8,  6, '2024-05-04', 'Booked'),
(10, 1, '2024-05-04', 'Attended'),
(10, 8, '2024-05-04', 'Booked');

-- Equipment (7 rows)
INSERT INTO Equipment (EquipmentName, Category, PurchaseDate, Condition_, LastMaintained, Location) VALUES
('Treadmill Pro X5',      'Cardio',    '2022-01-15', 'Good',                '2024-03-01', 'Cardio Zone'),
('Rowing Machine RM200',  'Cardio',    '2022-06-10', 'Excellent',           '2024-04-01', 'Cardio Zone'),
('Olympic Barbell Set',   'Weights',   '2021-08-20', 'Good',                '2024-02-15', 'Free Weights'),
('Cable Machine CM400',   'Strength',  '2023-01-10', 'Excellent',           '2024-04-10', 'Strength Zone'),
('Spin Bike SB100',       'Cycling',   '2022-11-05', 'Under Maintenance',   '2024-01-20', 'Cycle Room'),
('Yoga Mat Set (10 pcs)', 'Flexibility','2023-05-01','Good',                '2024-03-15', 'Studio A'),
('Dumbbells 5-50kg',      'Weights',   '2021-03-12', 'Fair',                '2024-01-10', 'Free Weights');

-- Personal Training Sessions (8 rows)
INSERT INTO PersonalTrainingSessions (MemberID, TrainerID, SessionDate, DurationMinutes, Notes, Status) VALUES
(1,  1, '2024-05-06 10:00:00', 60,  'Focus on upper body strength',     'Completed'),
(3,  6, '2024-05-07 11:00:00', 60,  'Nutrition plan discussion',        'Completed'),
(4,  3, '2024-05-08 14:00:00', 45,  'Beginner HIIT introduction',       'Scheduled'),
(7,  1, '2024-05-09 09:00:00', 60,  'Advanced powerlifting techniques', 'Scheduled'),
(2,  2, '2024-05-10 08:00:00', 60,  'Yoga for flexibility improvement', 'Scheduled'),
(10, 3, '2024-05-10 16:00:00', 45,  'Cardio endurance training',        'Scheduled'),
(5,  5, '2024-05-11 10:00:00', 60,  'Cycling performance assessment',   'Cancelled'),
(8,  4, '2024-05-12 11:00:00', 60,  'Dance fitness coordination',       'Scheduled');

-- Payments (10 rows)
INSERT INTO Payments (MemberID, Amount, PaymentDate, PaymentMethod, Description) VALUES
(1,  79.99, '2024-01-10', 'Credit Card',   'Premium Monthly Subscription'),
(2,  49.99, '2024-02-15', 'Bank Transfer', 'Standard Monthly Subscription'),
(3,  499.99,'2024-01-20', 'Credit Card',   'Standard Yearly Subscription'),
(4,  49.99, '2024-03-01', 'Online',        'Standard Monthly Subscription'),
(5,  29.99, '2024-03-10', 'Debit Card',    'Basic Monthly Subscription'),
(7,  79.99, '2023-12-05', 'Cash',          'Premium Monthly Subscription'),
(10, 79.99, '2024-04-15', 'Credit Card',   'Premium Monthly Subscription'),
(1,  45.00, '2024-05-06', 'Online',        'Personal Training Session - Karl Weber'),
(3,  50.00, '2024-05-07', 'Credit Card',   'Personal Training Session - Claudia Richter'),
(8,  19.99, '2024-04-01', 'Online',        'Student Plan Subscription');

-- Member Fitness Goals (8 rows)
INSERT INTO MemberFitnessGoals (MemberID, GoalType, TargetDate, CurrentWeight, TargetWeight, Notes, Achieved) VALUES
(1,  'Muscle Gain',      '2024-12-31', 78.5,  85.0,  'Increase bench press to 100kg',         FALSE),
(2,  'Flexibility',      '2024-09-30', 62.0,  60.0,  'Be able to do full splits',             FALSE),
(3,  'Weight Loss',      '2024-08-31', 95.0,  80.0,  'Reduce body fat percentage to 15%',     FALSE),
(4,  'General Fitness',  '2024-07-31', 58.0,  57.0,  'Run 5km without stopping',              FALSE),
(5,  'Endurance',        '2024-10-31', 72.0,  70.0,  'Complete a triathlon',                  FALSE),
(7,  'Muscle Gain',      '2024-06-30', 82.0,  88.0,  'Squat 140kg for 5 reps',               FALSE),
(8,  'Weight Loss',      '2024-11-30', 68.0,  60.0,  'Lose 8kg through diet and exercise',    FALSE),
(10, 'General Fitness',  '2024-09-30', 55.0,  54.0,  'Improve overall stamina and energy',    FALSE);

-- ============================================================
-- SECTION 4: SQL QUERIES (10+ Business Queries)
-- ============================================================

-- ---------------------------------------------------------------
-- Query 1: SELECT - List all active members with their details
-- ---------------------------------------------------------------
SELECT 
    MemberID,
    CONCAT(FirstName, ' ', LastName) AS FullName,
    Email,
    Phone,
    JoinDate,
    Status
FROM Members
WHERE Status = 'Active'
ORDER BY JoinDate DESC;

-- ---------------------------------------------------------------
-- Query 2: AGGREGATION - Total revenue collected per payment method
-- ---------------------------------------------------------------
SELECT 
    PaymentMethod,
    COUNT(*)          AS TotalTransactions,
    SUM(Amount)       AS TotalRevenue,
    AVG(Amount)       AS AverageTransaction,
    MIN(Amount)       AS MinPayment,
    MAX(Amount)       AS MaxPayment
FROM Payments
GROUP BY PaymentMethod
ORDER BY TotalRevenue DESC;

-- ---------------------------------------------------------------
-- Query 3: INNER JOIN - Members and their active subscription plans
-- ---------------------------------------------------------------
SELECT 
    m.MemberID,
    CONCAT(m.FirstName, ' ', m.LastName) AS MemberName,
    mp.PlanName,
    mp.Price,
    s.StartDate,
    s.EndDate,
    s.PaymentStatus
FROM Members m
INNER JOIN Subscriptions s  ON m.MemberID = s.MemberID
INNER JOIN MembershipPlans mp ON s.PlanID  = mp.PlanID
ORDER BY m.LastName;

-- ---------------------------------------------------------------
-- Query 4: LEFT JOIN - All members and their bookings (if any)
-- ---------------------------------------------------------------
SELECT 
    m.MemberID,
    CONCAT(m.FirstName, ' ', m.LastName) AS MemberName,
    COUNT(cb.BookingID) AS TotalBookings,
    SUM(CASE WHEN cb.AttendanceStatus = 'Attended' THEN 1 ELSE 0 END) AS ClassesAttended
FROM Members m
LEFT JOIN ClassBookings cb ON m.MemberID = cb.MemberID
GROUP BY m.MemberID, m.FirstName, m.LastName
ORDER BY TotalBookings DESC;

-- ---------------------------------------------------------------
-- Query 5: WHERE with LIKE / IN / BETWEEN - Filter members and trainers
-- ---------------------------------------------------------------
-- Members whose email is from gmail
SELECT FirstName, LastName, Email
FROM Members
WHERE Email LIKE '%@gmail.com%';

-- Members joining between Jan and March 2024
SELECT FirstName, LastName, JoinDate, Status
FROM Members
WHERE JoinDate BETWEEN '2024-01-01' AND '2024-03-31'
ORDER BY JoinDate;

-- Subscriptions with overdue or pending payment
SELECT s.SubscriptionID, CONCAT(m.FirstName,' ',m.LastName) AS Member, s.PaymentStatus, mp.PlanName
FROM Subscriptions s
JOIN Members m ON m.MemberID = s.MemberID
JOIN MembershipPlans mp ON mp.PlanID = s.PlanID
WHERE s.PaymentStatus IN ('Pending','Overdue');

-- ---------------------------------------------------------------
-- Query 6: GROUP BY + HAVING - Trainers who teach more than 2 classes
-- ---------------------------------------------------------------
SELECT 
    CONCAT(t.FirstName, ' ', t.LastName) AS TrainerName,
    t.Specialization,
    COUNT(fc.ClassID) AS TotalClassesTaught
FROM Trainers t
INNER JOIN FitnessClasses fc ON t.TrainerID = fc.TrainerID
GROUP BY t.TrainerID, t.FirstName, t.LastName, t.Specialization
HAVING COUNT(fc.ClassID) >= 2
ORDER BY TotalClassesTaught DESC;

-- ---------------------------------------------------------------
-- Query 7: SUBQUERY - Members who spend more than the average payment amount
-- ---------------------------------------------------------------
SELECT 
    CONCAT(m.FirstName, ' ', m.LastName) AS MemberName,
    SUM(p.Amount) AS TotalSpent
FROM Members m
JOIN Payments p ON m.MemberID = p.MemberID
GROUP BY m.MemberID, m.FirstName, m.LastName
HAVING SUM(p.Amount) > (SELECT AVG(Amount) FROM Payments)
ORDER BY TotalSpent DESC;

-- ---------------------------------------------------------------
-- Query 8: CASE Expression - Classify members by fitness goal progress
-- ---------------------------------------------------------------
SELECT 
    CONCAT(m.FirstName, ' ', m.LastName) AS MemberName,
    g.GoalType,
    g.CurrentWeight,
    g.TargetWeight,
    CASE 
        WHEN g.CurrentWeight - g.TargetWeight > 10 THEN 'Long Way to Go'
        WHEN g.CurrentWeight - g.TargetWeight BETWEEN 1 AND 10 THEN 'Getting Close'
        WHEN g.CurrentWeight <= g.TargetWeight THEN 'Goal Achieved!'
        ELSE 'On Track'
    END AS GoalProgress
FROM Members m
JOIN MemberFitnessGoals g ON m.MemberID = g.MemberID
ORDER BY m.LastName;

-- ---------------------------------------------------------------
-- Query 9: WINDOW FUNCTION - Rank members by total spending
-- ---------------------------------------------------------------
SELECT 
    CONCAT(m.FirstName, ' ', m.LastName) AS MemberName,
    SUM(p.Amount)                         AS TotalSpent,
    RANK() OVER (ORDER BY SUM(p.Amount) DESC) AS SpendingRank,
    ROUND(SUM(p.Amount) / SUM(SUM(p.Amount)) OVER () * 100, 2) AS PercentOfTotalRevenue
FROM Members m
JOIN Payments p ON m.MemberID = p.MemberID
GROUP BY m.MemberID, m.FirstName, m.LastName
ORDER BY SpendingRank;

-- ---------------------------------------------------------------
-- Query 10: CTE (WITH) - Monthly revenue summary
-- ---------------------------------------------------------------
WITH MonthlyRevenue AS (
    SELECT 
        DATE_FORMAT(PaymentDate, '%Y-%m') AS Month,
        COUNT(*)                           AS TotalTransactions,
        SUM(Amount)                        AS Revenue
    FROM Payments
    GROUP BY DATE_FORMAT(PaymentDate, '%Y-%m')
)
SELECT 
    Month,
    TotalTransactions,
    Revenue,
    SUM(Revenue) OVER (ORDER BY Month) AS CumulativeRevenue
FROM MonthlyRevenue
ORDER BY Month;

-- ---------------------------------------------------------------
-- Query 11: CTE - Class attendance rate per class
-- ---------------------------------------------------------------
WITH ClassStats AS (
    SELECT 
        fc.ClassID,
        fc.ClassName,
        fc.ClassType,
        CONCAT(t.FirstName, ' ', t.LastName) AS TrainerName,
        COUNT(cb.BookingID)                   AS TotalBookings,
        SUM(CASE WHEN cb.AttendanceStatus = 'Attended' THEN 1 ELSE 0 END) AS Attended
    FROM FitnessClasses fc
    LEFT JOIN ClassBookings cb ON fc.ClassID = cb.ClassID
    LEFT JOIN Trainers t       ON fc.TrainerID = t.TrainerID
    GROUP BY fc.ClassID, fc.ClassName, fc.ClassType, t.FirstName, t.LastName
)
SELECT 
    ClassName,
    ClassType,
    TrainerName,
    TotalBookings,
    Attended,
    CASE WHEN TotalBookings > 0 
         THEN ROUND(Attended / TotalBookings * 100, 1) 
         ELSE 0 
    END AS AttendanceRate
FROM ClassStats
ORDER BY AttendanceRate DESC;

-- ---------------------------------------------------------------
-- Query 12: VIEW - Active Member Summary View
-- ---------------------------------------------------------------
CREATE OR REPLACE VIEW ActiveMemberSummary AS
SELECT 
    m.MemberID,
    CONCAT(m.FirstName, ' ', m.LastName) AS MemberName,
    m.Email,
    mp.PlanName,
    s.EndDate                             AS SubscriptionExpiry,
    COUNT(DISTINCT cb.BookingID)          AS TotalClassBookings,
    SUM(p.Amount)                         AS TotalAmountPaid
FROM Members m
JOIN Subscriptions s    ON m.MemberID = s.MemberID
JOIN MembershipPlans mp ON s.PlanID   = mp.PlanID
LEFT JOIN ClassBookings cb ON m.MemberID = cb.MemberID
LEFT JOIN Payments p    ON m.MemberID = p.MemberID
WHERE m.Status = 'Active'
GROUP BY m.MemberID, m.FirstName, m.LastName, m.Email, mp.PlanName, s.EndDate;

-- Use the view
SELECT * FROM ActiveMemberSummary ORDER BY TotalAmountPaid DESC;

-- ---------------------------------------------------------------
-- Query 13: TRIGGER - Log overdue payments automatically
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PaymentAuditLog (
    LogID       INT          PRIMARY KEY AUTO_INCREMENT,
    MemberID    INT          NOT NULL,
    Action      VARCHAR(100) NOT NULL,
    LogTimestamp DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER trg_OverduePaymentAlert
AFTER UPDATE ON Subscriptions
FOR EACH ROW
BEGIN
    IF NEW.PaymentStatus = 'Overdue' AND OLD.PaymentStatus != 'Overdue' THEN
        INSERT INTO PaymentAuditLog (MemberID, Action)
        VALUES (NEW.MemberID, CONCAT('Subscription #', NEW.SubscriptionID, ' marked as Overdue'));
    END IF;
END$$

DELIMITER ;

-- Test the trigger
UPDATE Subscriptions SET PaymentStatus = 'Overdue' WHERE SubscriptionID = 4;
SELECT * FROM PaymentAuditLog;

-- ---------------------------------------------------------------
-- Query 14: Advanced JOIN - Equipment needing maintenance + trainer responsible
-- ---------------------------------------------------------------
SELECT 
    e.EquipmentName,
    e.Category,
    e.Condition_,
    e.LastMaintained,
    DATEDIFF(CURRENT_DATE, e.LastMaintained) AS DaysSinceLastMaintenance,
    CASE 
        WHEN DATEDIFF(CURRENT_DATE, e.LastMaintained) > 90 THEN 'URGENT'
        WHEN DATEDIFF(CURRENT_DATE, e.LastMaintained) > 60 THEN 'Due Soon'
        ELSE 'OK'
    END AS MaintenanceStatus
FROM Equipment e
ORDER BY DaysSinceLastMaintenance DESC;

-- ============================================================
-- END OF SCRIPT
-- ============================================================
