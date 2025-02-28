-- Step 1: Create a Single User
CREATE USER electricity_user IDENTIFIED BY electricity_pass;

-- Step 2: Grant Necessary Privileges
GRANT CONNECT, RESOURCE, CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, CREATE TRIGGER TO electricity_user;

-- Step 3: Switch to the User Schema
ALTER SESSION SET CURRENT_SCHEMA = electricity_user;

-- Step 4: Create Customers Table
CREATE TABLE Customers (
    CustomerID NUMBER PRIMARY KEY,
    FullName VARCHAR2(100) NOT NULL,
    Address VARCHAR2(255) NOT NULL,
    PhoneNumber VARCHAR2(15) UNIQUE NOT NULL,
    Email VARCHAR2(100) UNIQUE NOT NULL,
    MeterNumber VARCHAR2(20) UNIQUE NOT NULL,
    RegistrationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sequence & Trigger for Customers
CREATE SEQUENCE Customer_Seq START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER Customer_BI
BEFORE INSERT ON Customers
FOR EACH ROW
BEGIN
    SELECT Customer_Seq.NEXTVAL INTO :NEW.CustomerID FROM DUAL;
END;
/

-- Step 5: Create Meters Table
CREATE TABLE Meters (
    MeterNumber VARCHAR2(20) PRIMARY KEY,
    CustomerID NUMBER,
    MeterType VARCHAR2(20) CHECK (MeterType IN ('Residential', 'Commercial', 'Industrial')),
    InstallationDate DATE NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE
);

-- Step 6: Create Billing Table
CREATE TABLE Billing (
    BillID NUMBER PRIMARY KEY,
    CustomerID NUMBER,
    MeterNumber VARCHAR2(20),
    BillingMonth VARCHAR2(10) NOT NULL,
    UnitsConsumed NUMBER NOT NULL,
    RatePerUnit NUMBER(10,2) DEFAULT 5.50 NOT NULL,
    TotalAmount NUMBER(10,2) GENERATED ALWAYS AS (UnitsConsumed * RatePerUnit) VIRTUAL,
    DueDate DATE NOT NULL,
    Status VARCHAR2(10) DEFAULT 'Pending',
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (MeterNumber) REFERENCES Meters(MeterNumber) ON DELETE CASCADE
);

-- Add the CHECK constraint separately
ALTER TABLE Billing ADD CONSTRAINT chk_billing_status CHECK (Status IN ('Pending', 'Paid', 'Overdue'));


-- Sequence & Trigger for Billing
CREATE SEQUENCE Billing_Seq START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER Billing_BI
BEFORE INSERT ON Billing
FOR EACH ROW
BEGIN
    SELECT Billing_Seq.NEXTVAL INTO :NEW.BillID FROM DUAL;
END;
/

-- Step 7: Create Payments Table
CREATE TABLE Payments (
    PaymentID NUMBER PRIMARY KEY,
    BillID NUMBER,
    CustomerID NUMBER,
    PaymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    AmountPaid NUMBER(10,2) NOT NULL,
    AmountDue NUMBER(10,2) NOT NULL,
    PaymentMethod VARCHAR2(20) CHECK (PaymentMethod IN ('Cash', 'Credit Card', 'Debit Card', 'Online')),
    FOREIGN KEY (BillID) REFERENCES Billing(BillID) ON DELETE CASCADE,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE
);

-- Sequence & Trigger for Payments
CREATE SEQUENCE Payment_Seq START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER Payment_BI
BEFORE INSERT ON Payments
FOR EACH ROW
BEGIN
    SELECT Payment_Seq.NEXTVAL INTO :NEW.PaymentID FROM DUAL;
END;
/

-- Step 8: Create Admins Table
CREATE TABLE Admins (
    AdminID NUMBER PRIMARY KEY,
    Username VARCHAR2(50) UNIQUE NOT NULL,
    PasswordHash VARCHAR2(255) NOT NULL,
    FullName VARCHAR2(100) NOT NULL,
    Role VARCHAR2(20) CHECK (Role IN ('Manager', 'Clerk', 'Support')),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sequence & Trigger for Admins
CREATE SEQUENCE Admin_Seq START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER Admin_BI
BEFORE INSERT ON Admins
FOR EACH ROW
BEGIN
    SELECT Admin_Seq.NEXTVAL INTO :NEW.AdminID FROM DUAL;
END;
/

-- Step 9: Insert Sample Data
INSERT INTO Admins (Username, PasswordHash, FullName, Role)
VALUES ('admin', 'admin123', 'System Admin', 'Manager');

INSERT INTO Customers (FullName, Address, PhoneNumber, Email, MeterNumber)
VALUES ('John Doe', '123 Main St', '9876543210', 'john.doe@email.com', 'MTR123456');

INSERT INTO Meters (MeterNumber, CustomerID, MeterType, InstallationDate)
VALUES ('MTR123456', (SELECT CustomerID FROM Customers WHERE MeterNumber = 'MTR123456'), 'Residential', '2024-01-01');

INSERT INTO Billing (CustomerID, MeterNumber, BillingMonth, UnitsConsumed, DueDate)
VALUES ((SELECT CustomerID FROM Customers WHERE MeterNumber = 'MTR123456'), 'MTR123456', 'Feb-2024', 200, '2024-02-28');

INSERT INTO Payments (BillID, CustomerID, AmountPaid, PaymentMethod)
VALUES ((SELECT BillID FROM Billing WHERE BillingMonth = 'Feb-2024'), 
        (SELECT CustomerID FROM Customers WHERE MeterNumber = 'MTR123456'),
        1100.00, 'Online');

COMMIT;
