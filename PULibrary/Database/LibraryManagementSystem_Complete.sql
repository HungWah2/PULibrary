/***************************************************************************************************
 * Database Creation, Schema DDL & Seed Data Script
 * Database: LibraryManagementSystem (JingYi Public Library)
 * Target: Microsoft SQL Server 2019 / 2022
 * Generated: 2026-11-23 14:59:53
 ***************************************************************************************************/

USE [master];
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'LibraryManagementSystem')
BEGIN
    CREATE DATABASE [LibraryManagementSystem];
END
GO

USE [LibraryManagementSystem];
GO

/***************************************************************************************************
 * SECTION 1: CREATE TABLES (SCHEMA DDL)
 ***************************************************************************************************/

-- 1. Role
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Role')
BEGIN
    CREATE TABLE [Role] (
        [role_id] SMALLINT IDENTITY(1,1) NOT NULL,
        [role_name] VARCHAR(50) NOT NULL,
        CONSTRAINT [PK_Role] PRIMARY KEY CLUSTERED ([role_id] ASC)
    );
END
GO

-- 2. Policy
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Policy')
BEGIN
    CREATE TABLE [Policy] (
        [policy_id] SMALLINT IDENTITY(1,1) NOT NULL,
        [role_id] SMALLINT NOT NULL,
        [loan_days] SMALLINT NOT NULL,
        [max_loans] SMALLINT NOT NULL,
        [max_renewals] SMALLINT NOT NULL,
        CONSTRAINT [PK_Policy] PRIMARY KEY CLUSTERED ([policy_id] ASC),
        CONSTRAINT [FK_Policy_Role] FOREIGN KEY ([role_id]) REFERENCES [Role]([role_id])
    );
END
GO

-- 3. User
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'User')
BEGIN
    CREATE TABLE [User] (
        [user_id] INT IDENTITY(1001,1) NOT NULL,
        [username] VARCHAR(20) NOT NULL,
        [password_hash] VARCHAR(255) NOT NULL,
        [name] VARCHAR(30) NOT NULL,
        [phone] CHAR(10) NOT NULL,
        [email] VARCHAR(100) NOT NULL,
        [created_at] DATETIME2 NOT NULL,
        [updated_at] DATETIME2 NULL,
        [status] VARCHAR(20) NOT NULL,
        [role_id] SMALLINT NOT NULL,
        CONSTRAINT [PK_User] PRIMARY KEY CLUSTERED ([user_id] ASC),
        CONSTRAINT [FK_User_Role] FOREIGN KEY ([role_id]) REFERENCES [Role]([role_id])
    );
END
GO

-- 4. Author
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Author')
BEGIN
    CREATE TABLE [Author] (
        [author_id] SMALLINT IDENTITY(1,1) NOT NULL,
        [author_name] VARCHAR(30) NOT NULL,
        CONSTRAINT [PK_Author] PRIMARY KEY CLUSTERED ([author_id] ASC)
    );
END
GO

-- 5. Publisher
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Publisher')
BEGIN
    CREATE TABLE [Publisher] (
        [publisher_id] SMALLINT IDENTITY(1,1) NOT NULL,
        [publisher_name] VARCHAR(30) NOT NULL,
        CONSTRAINT [PK_Publisher] PRIMARY KEY CLUSTERED ([publisher_id] ASC)
    );
END
GO

-- 6. Category
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Category')
BEGIN
    CREATE TABLE [Category] (
        [category_id] SMALLINT IDENTITY(1,1) NOT NULL,
        [category_name] VARCHAR(30) NOT NULL,
        CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED ([category_id] ASC)
    );
END
GO

-- 7. Book
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Book')
BEGIN
    CREATE TABLE [Book] (
        [book_id] INT IDENTITY(101,1) NOT NULL,
        [isbn] CHAR(13) NULL,
        [title] VARCHAR(50) NOT NULL,
        [language] VARCHAR(20) NOT NULL,
        [edition] SMALLINT NOT NULL,
        [cover_image] VARCHAR(255) NULL,
        [published_date] DATE NULL,
        [description] VARCHAR(MAX) NULL,
        CONSTRAINT [PK_Book] PRIMARY KEY CLUSTERED ([book_id] ASC)
    );
END
GO

-- 8. Associate_Book_Author
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Associate_Book_Author')
BEGIN
    CREATE TABLE [Associate_Book_Author] (
        [author_id] SMALLINT NOT NULL,
        [book_id] INT NOT NULL,
        CONSTRAINT [PK_Associate_Book_Author] PRIMARY KEY CLUSTERED ([author_id] ASC, [book_id] ASC),
        CONSTRAINT [FK_ABA_Author] FOREIGN KEY ([author_id]) REFERENCES [Author]([author_id]),
        CONSTRAINT [FK_ABA_Book] FOREIGN KEY ([book_id]) REFERENCES [Book]([book_id])
    );
END
GO

-- 9. Associate_Book_Publisher
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Associate_Book_Publisher')
BEGIN
    CREATE TABLE [Associate_Book_Publisher] (
        [publisher_id] SMALLINT NOT NULL,
        [book_id] INT NOT NULL,
        CONSTRAINT [PK_Associate_Book_Publisher] PRIMARY KEY CLUSTERED ([publisher_id] ASC, [book_id] ASC),
        CONSTRAINT [FK_ABP_Publisher] FOREIGN KEY ([publisher_id]) REFERENCES [Publisher]([publisher_id]),
        CONSTRAINT [FK_ABP_Book] FOREIGN KEY ([book_id]) REFERENCES [Book]([book_id])
    );
END
GO

-- 10. Associate_Book_Category
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Associate_Book_Category')
BEGIN
    CREATE TABLE [Associate_Book_Category] (
        [category_id] SMALLINT NOT NULL,
        [book_id] INT NOT NULL,
        CONSTRAINT [PK_Associate_Book_Category] PRIMARY KEY CLUSTERED ([category_id] ASC, [book_id] ASC),
        CONSTRAINT [FK_ABC_Category] FOREIGN KEY ([category_id]) REFERENCES [Category]([category_id]),
        CONSTRAINT [FK_ABC_Book] FOREIGN KEY ([book_id]) REFERENCES [Book]([book_id])
    );
END
GO

-- 11. BookCopy
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BookCopy')
BEGIN
    CREATE TABLE [BookCopy] (
        [copy_id] INT IDENTITY(10481,1) NOT NULL,
        [book_id] INT NOT NULL,
        [shelf_location] VARCHAR(255) NOT NULL,
        [copy_condition] VARCHAR(20) NOT NULL,
        [status] VARCHAR(20) NOT NULL,
        CONSTRAINT [PK_BookCopy] PRIMARY KEY CLUSTERED ([copy_id] ASC),
        CONSTRAINT [FK_BookCopy_Book] FOREIGN KEY ([book_id]) REFERENCES [Book]([book_id])
    );
END
GO

-- 12. Loan
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Loan')
BEGIN
    CREATE TABLE [Loan] (
        [loan_id] INT IDENTITY(5001,1) NOT NULL,
        [user_id] INT NOT NULL,
        [copy_id] INT NOT NULL,
        [renewal_count] SMALLINT NOT NULL,
        [borrowed_at] DATETIME2 NOT NULL,
        [returned_at] DATETIME2 NULL,
        [due_at] DATETIME2 NOT NULL,
        [processed_by] INT NULL,
        CONSTRAINT [PK_Loan] PRIMARY KEY CLUSTERED ([loan_id] ASC),
        CONSTRAINT [FK_Loan_User] FOREIGN KEY ([user_id]) REFERENCES [User]([user_id]),
        CONSTRAINT [FK_Loan_BookCopy] FOREIGN KEY ([copy_id]) REFERENCES [BookCopy]([copy_id]),
        CONSTRAINT [FK_Loan_Staff] FOREIGN KEY ([processed_by]) REFERENCES [User]([user_id])
    );
END
GO

-- 13. Reservation
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Reservation')
BEGIN
    CREATE TABLE [Reservation] (
        [reservation_id] INT IDENTITY(7001,1) NOT NULL,
        [user_id] INT NOT NULL,
        [book_id] INT NOT NULL,
        [fulfilled_copy_id] INT NULL,
        [reserved_at] DATETIME2 NOT NULL,
        [status] VARCHAR(20) NOT NULL,
        CONSTRAINT [PK_Reservation] PRIMARY KEY CLUSTERED ([reservation_id] ASC),
        CONSTRAINT [FK_Reservation_User] FOREIGN KEY ([user_id]) REFERENCES [User]([user_id]),
        CONSTRAINT [FK_Reservation_Book] FOREIGN KEY ([book_id]) REFERENCES [Book]([book_id]),
        CONSTRAINT [FK_Reservation_FulfilledCopy] FOREIGN KEY ([fulfilled_copy_id]) REFERENCES [BookCopy]([copy_id])
    );
END
GO

/***************************************************************************************************
 * SECTION 2: POPULATE SEED DATA
 ***************************************************************************************************/
/*******************************************************************************
 * Table: [Role] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [Role] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [Role] WHERE [role_id] = 1)
    INSERT INTO [Role] ([role_id], [role_name]) VALUES (1, N'Member');
IF NOT EXISTS (SELECT 1 FROM [Role] WHERE [role_id] = 2)
    INSERT INTO [Role] ([role_id], [role_name]) VALUES (2, N'Researcher');
IF NOT EXISTS (SELECT 1 FROM [Role] WHERE [role_id] = 3)
    INSERT INTO [Role] ([role_id], [role_name]) VALUES (3, N'Librarian');
IF NOT EXISTS (SELECT 1 FROM [Role] WHERE [role_id] = 4)
    INSERT INTO [Role] ([role_id], [role_name]) VALUES (4, N'Admin');
SET IDENTITY_INSERT [Role] OFF;
GO

/*******************************************************************************
 * Table: [Policy] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [Policy] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [Policy] WHERE [policy_id] = 1)
    INSERT INTO [Policy] ([policy_id], [role_id], [loan_days], [max_loans], [max_renewals]) VALUES (1, 1, 14, 3, 1);
IF NOT EXISTS (SELECT 1 FROM [Policy] WHERE [policy_id] = 2)
    INSERT INTO [Policy] ([policy_id], [role_id], [loan_days], [max_loans], [max_renewals]) VALUES (2, 2, 30, 8, 2);
IF NOT EXISTS (SELECT 1 FROM [Policy] WHERE [policy_id] = 3)
    INSERT INTO [Policy] ([policy_id], [role_id], [loan_days], [max_loans], [max_renewals]) VALUES (3, 3, 60, 15, 5);
IF NOT EXISTS (SELECT 1 FROM [Policy] WHERE [policy_id] = 4)
    INSERT INTO [Policy] ([policy_id], [role_id], [loan_days], [max_loans], [max_renewals]) VALUES (4, 4, 90, 20, 10);
SET IDENTITY_INSERT [Policy] OFF;
GO

/*******************************************************************************
 * Table: [User] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [User] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [User] WHERE [user_id] = 1001)
    INSERT INTO [User] ([user_id], [username], [password_hash], [name], [phone], [email], [created_at], [updated_at], [status], [role_id]) VALUES (1001, N'jamie lee', N'AQAAAAIAAYagAAAAEStaffPass123Hash', N'Jamie Lee', N'0912345678', N'jamie.lee@library.org', '2026-01-01 08:00:00.000', '2026-11-23 11:25:19.865', N'Active', 4);
IF NOT EXISTS (SELECT 1 FROM [User] WHERE [user_id] = 1826)
    INSERT INTO [User] ([user_id], [username], [password_hash], [name], [phone], [email], [created_at], [updated_at], [status], [role_id]) VALUES (1826, N'dbrooks', N'AQAAAAIAAYagAAAAEReaderPass123Hash', N'Daniel Brooks', N'0945678901', N'daniel.brooks@univ.edu', '2026-02-15 10:00:00.000', '2026-05-10 11:00:00.000', N'Active', 2);
IF NOT EXISTS (SELECT 1 FROM [User] WHERE [user_id] = 1935)
    INSERT INTO [User] ([user_id], [username], [password_hash], [name], [phone], [email], [created_at], [updated_at], [status], [role_id]) VALUES (1935, N'nwilliams', N'AQAAAAIAAYagAAAAEReaderPass123Hash', N'Nora Williams', N'0956789012', N'nora.williams@univ.edu', '2026-03-01 14:00:00.000', '2026-07-20 15:00:00.000', N'Active', 1);
IF NOT EXISTS (SELECT 1 FROM [User] WHERE [user_id] = 2413)
    INSERT INTO [User] ([user_id], [username], [password_hash], [name], [phone], [email], [created_at], [updated_at], [status], [role_id]) VALUES (2413, N'pshah', N'AQAAAAIAAYagAAAAEReaderPass123Hash', N'Priya Shah', N'0923456789', N'priya.shah@univ.edu', '2026-04-10 11:00:00.000', '2026-08-15 12:00:00.000', N'Active', 1);
IF NOT EXISTS (SELECT 1 FROM [User] WHERE [user_id] = 2481)
    INSERT INTO [User] ([user_id], [username], [password_hash], [name], [phone], [email], [created_at], [updated_at], [status], [role_id]) VALUES (2481, N'mchen', N'AQAAAAIAAYagAAAAEReaderPass123Hash', N'Maya Chen', N'0912345678', N'maya.chen@university.edu', '2026-05-01 09:30:00.000', '2026-06-01 09:00:00.000', N'Active', 2);
SET IDENTITY_INSERT [User] OFF;
GO

/*******************************************************************************
 * Table: [Author] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [Author] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [Author] WHERE [author_id] = 1)
    INSERT INTO [Author] ([author_id], [author_name]) VALUES (1, N'Owen Johnson');
IF NOT EXISTS (SELECT 1 FROM [Author] WHERE [author_id] = 2)
    INSERT INTO [Author] ([author_id], [author_name]) VALUES (2, N'David More');
IF NOT EXISTS (SELECT 1 FROM [Author] WHERE [author_id] = 3)
    INSERT INTO [Author] ([author_id], [author_name]) VALUES (3, N'Robin Wall Kimmerer');
IF NOT EXISTS (SELECT 1 FROM [Author] WHERE [author_id] = 4)
    INSERT INTO [Author] ([author_id], [author_name]) VALUES (4, N'Rick Rubin');
IF NOT EXISTS (SELECT 1 FROM [Author] WHERE [author_id] = 5)
    INSERT INTO [Author] ([author_id], [author_name]) VALUES (5, N'Daniel Kahneman');
IF NOT EXISTS (SELECT 1 FROM [Author] WHERE [author_id] = 6)
    INSERT INTO [Author] ([author_id], [author_name]) VALUES (6, N'George Saunders');
IF NOT EXISTS (SELECT 1 FROM [Author] WHERE [author_id] = 7)
    INSERT INTO [Author] ([author_id], [author_name]) VALUES (7, N'Peter Wohlleben');
SET IDENTITY_INSERT [Author] OFF;
GO

/*******************************************************************************
 * Table: [Publisher] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [Publisher] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [Publisher] WHERE [publisher_id] = 1)
    INSERT INTO [Publisher] ([publisher_id], [publisher_name]) VALUES (1, N'Collins');
IF NOT EXISTS (SELECT 1 FROM [Publisher] WHERE [publisher_id] = 2)
    INSERT INTO [Publisher] ([publisher_id], [publisher_name]) VALUES (2, N'HarperCollins');
IF NOT EXISTS (SELECT 1 FROM [Publisher] WHERE [publisher_id] = 3)
    INSERT INTO [Publisher] ([publisher_id], [publisher_name]) VALUES (3, N'Milkweed Editions');
IF NOT EXISTS (SELECT 1 FROM [Publisher] WHERE [publisher_id] = 4)
    INSERT INTO [Publisher] ([publisher_id], [publisher_name]) VALUES (4, N'Penguin Press');
IF NOT EXISTS (SELECT 1 FROM [Publisher] WHERE [publisher_id] = 5)
    INSERT INTO [Publisher] ([publisher_id], [publisher_name]) VALUES (5, N'Farrar, Straus and Giroux');
IF NOT EXISTS (SELECT 1 FROM [Publisher] WHERE [publisher_id] = 6)
    INSERT INTO [Publisher] ([publisher_id], [publisher_name]) VALUES (6, N'Random House');
IF NOT EXISTS (SELECT 1 FROM [Publisher] WHERE [publisher_id] = 7)
    INSERT INTO [Publisher] ([publisher_id], [publisher_name]) VALUES (7, N'Greystone Books');
SET IDENTITY_INSERT [Publisher] OFF;
GO

/*******************************************************************************
 * Table: [Category] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [Category] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 1)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (1, N'Nature & ecology');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 2)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (2, N'Science');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 3)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (3, N'Indigenous studies');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 4)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (4, N'Ecology');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 5)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (5, N'Philosophy');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 6)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (6, N'Creativity');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 7)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (7, N'Psychology');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 8)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (8, N'Behavioral Economics');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 9)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (9, N'Literary criticism');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 10)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (10, N'Fiction writing');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 11)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (11, N'Forestry');
IF NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_id] = 12)
    INSERT INTO [Category] ([category_id], [category_name]) VALUES (12, N'Natural history');
SET IDENTITY_INSERT [Category] OFF;
GO

/*******************************************************************************
 * Table: [Book] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [Book] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [Book] WHERE [book_id] = 101)
    INSERT INTO [Book] ([book_id], [isbn], [title], [language], [edition], [cover_image], [published_date], [description]) VALUES (101, N'9780007207516', N'A Field Guide to Trees', N'English', 1, N'/covers/book101.jpg', '2004-05-01 00:00:00.000', N'A comprehensive photographic and illustrated guide to over 850 trees of Britain and northern Europe.');
IF NOT EXISTS (SELECT 1 FROM [Book] WHERE [book_id] = 102)
    INSERT INTO [Book] ([book_id], [isbn], [title], [language], [edition], [cover_image], [published_date], [description]) VALUES (102, N'9781571313560', N'Braiding Sweetgrass', N'English', 1, N'/covers/book102.jpg', '2013-10-15 00:00:00.000', N'Indigenous wisdom, scientific knowledge, and the teachings of plants by Robin Wall Kimmerer.');
IF NOT EXISTS (SELECT 1 FROM [Book] WHERE [book_id] = 103)
    INSERT INTO [Book] ([book_id], [isbn], [title], [language], [edition], [cover_image], [published_date], [description]) VALUES (103, N'9780593652886', N'The Creative Act', N'English', 1, N'/covers/book103.jpg', '2023-01-17 00:00:00.000', N'A legendary music producer shares his wisdom on the nature of artistic creation and inspiration.');
IF NOT EXISTS (SELECT 1 FROM [Book] WHERE [book_id] = 104)
    INSERT INTO [Book] ([book_id], [isbn], [title], [language], [edition], [cover_image], [published_date], [description]) VALUES (104, N'9780374533557', N'Thinking, Fast and Slow', N'English', 1, N'/covers/book104.jpg', '2011-10-25 00:00:00.000', N'Exploration of the two systems that drive the way we think by Nobel laureate Daniel Kahneman.');
IF NOT EXISTS (SELECT 1 FROM [Book] WHERE [book_id] = 105)
    INSERT INTO [Book] ([book_id], [isbn], [title], [language], [edition], [cover_image], [published_date], [description]) VALUES (105, N'9781984856029', N'A Swim in a Pond in the Rain', N'English', 1, N'/covers/book105.jpg', '2021-01-12 00:00:00.000', N'George Saunders reads seven classic Russian short stories and explains why they work.');
IF NOT EXISTS (SELECT 1 FROM [Book] WHERE [book_id] = 106)
    INSERT INTO [Book] ([book_id], [isbn], [title], [language], [edition], [cover_image], [published_date], [description]) VALUES (106, N'9781771642484', N'The Hidden Life of Trees', N'English', 1, N'/covers/book106.jpg', '2016-09-13 00:00:00.000', N'What trees feel, how they communicate, and their secret community underground.');
SET IDENTITY_INSERT [Book] OFF;
GO

/*******************************************************************************
 * Table: [Associate_Book_Author] Data Export
 *******************************************************************************/
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Author] WHERE [author_id] = 1 AND [book_id] = 101)
    INSERT INTO [Associate_Book_Author] ([author_id], [book_id]) VALUES (1, 101);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Author] WHERE [author_id] = 2 AND [book_id] = 101)
    INSERT INTO [Associate_Book_Author] ([author_id], [book_id]) VALUES (2, 101);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Author] WHERE [author_id] = 3 AND [book_id] = 102)
    INSERT INTO [Associate_Book_Author] ([author_id], [book_id]) VALUES (3, 102);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Author] WHERE [author_id] = 4 AND [book_id] = 103)
    INSERT INTO [Associate_Book_Author] ([author_id], [book_id]) VALUES (4, 103);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Author] WHERE [author_id] = 5 AND [book_id] = 104)
    INSERT INTO [Associate_Book_Author] ([author_id], [book_id]) VALUES (5, 104);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Author] WHERE [author_id] = 6 AND [book_id] = 105)
    INSERT INTO [Associate_Book_Author] ([author_id], [book_id]) VALUES (6, 105);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Author] WHERE [author_id] = 7 AND [book_id] = 106)
    INSERT INTO [Associate_Book_Author] ([author_id], [book_id]) VALUES (7, 106);
GO

/*******************************************************************************
 * Table: [Associate_Book_Publisher] Data Export
 *******************************************************************************/
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Publisher] WHERE [publisher_id] = 1 AND [book_id] = 101)
    INSERT INTO [Associate_Book_Publisher] ([publisher_id], [book_id]) VALUES (1, 101);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Publisher] WHERE [publisher_id] = 2 AND [book_id] = 101)
    INSERT INTO [Associate_Book_Publisher] ([publisher_id], [book_id]) VALUES (2, 101);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Publisher] WHERE [publisher_id] = 3 AND [book_id] = 102)
    INSERT INTO [Associate_Book_Publisher] ([publisher_id], [book_id]) VALUES (3, 102);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Publisher] WHERE [publisher_id] = 4 AND [book_id] = 103)
    INSERT INTO [Associate_Book_Publisher] ([publisher_id], [book_id]) VALUES (4, 103);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Publisher] WHERE [publisher_id] = 5 AND [book_id] = 104)
    INSERT INTO [Associate_Book_Publisher] ([publisher_id], [book_id]) VALUES (5, 104);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Publisher] WHERE [publisher_id] = 6 AND [book_id] = 105)
    INSERT INTO [Associate_Book_Publisher] ([publisher_id], [book_id]) VALUES (6, 105);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Publisher] WHERE [publisher_id] = 7 AND [book_id] = 106)
    INSERT INTO [Associate_Book_Publisher] ([publisher_id], [book_id]) VALUES (7, 106);
GO

/*******************************************************************************
 * Table: [Associate_Book_Category] Data Export
 *******************************************************************************/
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 1 AND [book_id] = 101)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (1, 101);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 2 AND [book_id] = 101)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (2, 101);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 3 AND [book_id] = 102)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (3, 102);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 4 AND [book_id] = 102)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (4, 102);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 5 AND [book_id] = 103)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (5, 103);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 6 AND [book_id] = 103)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (6, 103);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 7 AND [book_id] = 104)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (7, 104);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 8 AND [book_id] = 104)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (8, 104);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 9 AND [book_id] = 105)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (9, 105);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 10 AND [book_id] = 105)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (10, 105);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 11 AND [book_id] = 106)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (11, 106);
IF NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [category_id] = 12 AND [book_id] = 106)
    INSERT INTO [Associate_Book_Category] ([category_id], [book_id]) VALUES (12, 106);
GO

/*******************************************************************************
 * Table: [BookCopy] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [BookCopy] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 9201)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (9201, 106, N'STACK-F-01', N'Good', N'Available');
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 10481)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (10481, 101, N'STACK-A-01', N'Good', N'Available');
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 10482)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (10482, 101, N'STACK-A-02', N'Good', N'Available');
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 10484)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (10484, 101, N'STACK-A-03', N'Good', N'Borrowed');
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 10485)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (10485, 101, N'STACK-A-04', N'Damaged', N'Available');
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 10501)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (10501, 102, N'STACK-B-01', N'Good', N'Borrowed');
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 10502)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (10502, 102, N'STACK-B-02', N'Good', N'Reserved');
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 10601)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (10601, 103, N'STACK-C-01', N'Good', N'Borrowed');
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 10602)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (10602, 103, N'STACK-C-02', N'Good', N'Available');
IF NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = 10701)
    INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status]) VALUES (10701, 104, N'STACK-D-01', N'Good', N'Available');
SET IDENTITY_INSERT [BookCopy] OFF;
GO

/*******************************************************************************
 * Table: [Loan] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [Loan] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [Loan] WHERE [loan_id] = 5001)
    INSERT INTO [Loan] ([loan_id], [user_id], [copy_id], [renewal_count], [borrowed_at], [returned_at], [due_at], [processed_by]) VALUES (5001, 2481, 10484, 0, '2026-10-15 11:00:00.000', NULL, '2026-11-03 15:00:00.000', 1001);
IF NOT EXISTS (SELECT 1 FROM [Loan] WHERE [loan_id] = 5003)
    INSERT INTO [Loan] ([loan_id], [user_id], [copy_id], [renewal_count], [borrowed_at], [returned_at], [due_at], [processed_by]) VALUES (5003, 2413, 10501, 0, '2026-10-08 14:00:00.000', NULL, '2026-10-22 14:00:00.000', 1001);
IF NOT EXISTS (SELECT 1 FROM [Loan] WHERE [loan_id] = 5004)
    INSERT INTO [Loan] ([loan_id], [user_id], [copy_id], [renewal_count], [borrowed_at], [returned_at], [due_at], [processed_by]) VALUES (5004, 2481, 10601, 0, '2026-10-10 10:00:00.000', NULL, '2026-10-24 10:00:00.000', 1001);
SET IDENTITY_INSERT [Loan] OFF;
GO

/*******************************************************************************
 * Table: [Reservation] Data Export
 *******************************************************************************/
SET IDENTITY_INSERT [Reservation] ON;
GO
IF NOT EXISTS (SELECT 1 FROM [Reservation] WHERE [reservation_id] = 7002)
    INSERT INTO [Reservation] ([reservation_id], [user_id], [book_id], [fulfilled_copy_id], [reserved_at], [status]) VALUES (7002, 1935, 102, 10502, '2026-10-23 09:00:00.000', N'FULFILLED');
IF NOT EXISTS (SELECT 1 FROM [Reservation] WHERE [reservation_id] = 8001)
    INSERT INTO [Reservation] ([reservation_id], [user_id], [book_id], [fulfilled_copy_id], [reserved_at], [status]) VALUES (8001, 1935, 101, NULL, '2026-11-17 16:40:55.178', N'PENDING');
SET IDENTITY_INSERT [Reservation] OFF;
GO
