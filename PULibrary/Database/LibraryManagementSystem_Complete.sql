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


-- ===============================================================================
-- SECTION 3: EXPANDED SEED DATA (24 BOOKS, 35 COPIES, LOANS & RESERVATIONS)
-- ===============================================================================

-- 1. Authors
DECLARE @Authors TABLE (name VARCHAR(30));
INSERT INTO @Authors VALUES 
('Robert C. Martin'), ('Martin Fowler'), ('Andrew Hunt'), ('David Thomas'), 
('Thomas H. Cormen'), ('Cal Newport'), ('James Clear'), ('Yuval Noah Harari'), 
('Jared Diamond'), ('Carl Sagan'), ('Neil deGrasse Tyson'), ('Richard Dawkins'), 
('Frank Herbert'), ('William Gibson'), ('Isaac Asimov'), ('George Orwell'), 
('Aldous Huxley'), ('Harper Lee'), ('F. Scott Fitzgerald'), ('Haruki Murakami'), 
('J. R. R. Tolkien');

INSERT INTO [Author] ([author_name])
SELECT a.name FROM @Authors a
WHERE NOT EXISTS (SELECT 1 FROM [Author] WHERE [author_name] = a.name);

-- 2. Publishers
DECLARE @Publishers TABLE (name VARCHAR(30));
INSERT INTO @Publishers VALUES 
('Prentice Hall'), ('Addison-Wesley'), ('MIT Press'), ('Grand Central'), 
('Avery'), ('Harper'), ('W. W. Norton'), ('Oxford University Press'), 
('Chilton Books'), ('Ace Books'), ('Gnome Press'), ('Secker & Warburg'), 
('Chatto & Windus'), ('Scribner'), ('Kodansha'), ('Allen & Unwin');

INSERT INTO [Publisher] ([publisher_name])
SELECT p.name FROM @Publishers p
WHERE NOT EXISTS (SELECT 1 FROM [Publisher] WHERE [publisher_name] = p.name);

-- 3. Categories
DECLARE @Categories TABLE (name VARCHAR(30));
INSERT INTO @Categories VALUES 
('Computer Science'), ('Software Engineering'), ('Productivity'), 
('Anthropology'), ('World History'), ('Astronomy'), ('Physics'), 
('Genetics'), ('Science Fiction'), ('Cyberpunk'), ('Classic Literature'), 
('Fantasy');

INSERT INTO [Category] ([category_name])
SELECT c.name FROM @Categories c
WHERE NOT EXISTS (SELECT 1 FROM [Category] WHERE [category_name] = c.name);

-- 4. Additional Readers
IF NOT EXISTS (SELECT 1 FROM [User] WHERE [username] = 'alex.kim')
    INSERT INTO [User] ([name], [username], [email], [phone], [status], [role_id], [created_at], [password_hash])
    VALUES ('Alex Kim', 'alex.kim', 'alex.kim@jingyi.lib', '0912111222', 'Active', 1, '2026-06-01', '$2a$11$wK1FmZ7jYyEfxm8oT7vHie8O6Zz2j8Y6xK2M5vJ8xZ1j7k8m9o0q2');

IF NOT EXISTS (SELECT 1 FROM [User] WHERE [username] = 'sophia.martinez')
    INSERT INTO [User] ([name], [username], [email], [phone], [status], [role_id], [created_at], [password_hash])
    VALUES ('Sophia Martinez', 'sophia.martinez', 'sophia.m@jingyi.lib', '0912333444', 'Active', 2, '2026-06-10', '$2a$11$wK1FmZ7jYyEfxm8oT7vHie8O6Zz2j8Y6xK2M5vJ8xZ1j7k8m9o0q2');

IF NOT EXISTS (SELECT 1 FROM [User] WHERE [username] = 'liam.nguyen')
    INSERT INTO [User] ([name], [username], [email], [phone], [status], [role_id], [created_at], [password_hash])
    VALUES ('Liam Nguyen', 'liam.nguyen', 'liam.n@jingyi.lib', '0912555666', 'Active', 1, '2026-06-15', '$2a$11$wK1FmZ7jYyEfxm8oT7vHie8O6Zz2j8Y6xK2M5vJ8xZ1j7k8m9o0q2');

IF NOT EXISTS (SELECT 1 FROM [User] WHERE [username] = 'elena.rostova')
    INSERT INTO [User] ([name], [username], [email], [phone], [status], [role_id], [created_at], [password_hash])
    VALUES ('Elena Rostova', 'elena.rostova', 'elena.r@jingyi.lib', '0912777888', 'Active', 2, '2026-07-01', '$2a$11$wK1FmZ7jYyEfxm8oT7vHie8O6Zz2j8Y6xK2M5vJ8xZ1j7k8m9o0q2');
GO

-- 5. Helper procedure to safely insert a book and associations
CREATE OR ALTER PROCEDURE #sp_SeedBook
    @bookId INT,
    @isbn VARCHAR(13),
    @title NVARCHAR(100),
    @language VARCHAR(20),
    @edition SMALLINT,
    @publishedDate DATETIME,
    @description NVARCHAR(MAX),
    @authorName VARCHAR(30),
    @pubName VARCHAR(30),
    @catName VARCHAR(30)
AS
BEGIN
    SET IDENTITY_INSERT [Book] ON;
    IF NOT EXISTS (SELECT 1 FROM [Book] WHERE [book_id] = @bookId)
    BEGIN
        DECLARE @cover NVARCHAR(100) = CONCAT('/covers/book', @bookId, '.jpg');
        INSERT INTO [Book] ([book_id], [isbn], [title], [language], [edition], [cover_image], [published_date], [description])
        VALUES (@bookId, @isbn, @title, @language, @edition, @cover, @publishedDate, @description);
    END
    SET IDENTITY_INSERT [Book] OFF;

    DECLARE @aid SMALLINT = (SELECT TOP 1 [author_id] FROM [Author] WHERE [author_name] = @authorName);
    DECLARE @pid SMALLINT = (SELECT TOP 1 [publisher_id] FROM [Publisher] WHERE [publisher_name] = @pubName);
    DECLARE @cid SMALLINT = (SELECT TOP 1 [category_id] FROM [Category] WHERE [category_name] = @catName);

    IF @aid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [Associate_Book_Author] WHERE [book_id] = @bookId AND [author_id] = @aid)
        INSERT INTO [Associate_Book_Author] ([book_id], [author_id]) VALUES (@bookId, @aid);

    IF @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [Associate_Book_Publisher] WHERE [book_id] = @bookId AND [publisher_id] = @pid)
        INSERT INTO [Associate_Book_Publisher] ([book_id], [publisher_id]) VALUES (@bookId, @pid);

    IF @cid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [Associate_Book_Category] WHERE [book_id] = @bookId AND [category_id] = @cid)
        INSERT INTO [Associate_Book_Category] ([book_id], [category_id]) VALUES (@bookId, @cid);
END;
GO

EXEC #sp_SeedBook 107, '9780132350884', N'Clean Code: Agile Software Craftsmanship', 'English', 1, '2008-08-01', N'Even bad code can function. But if code isn''t clean, it can bring a development organization to its knees.', 'Robert C. Martin', 'Prentice Hall', 'Software Engineering';
EXEC #sp_SeedBook 108, '9780201485677', N'Refactoring: Improving Existing Code', 'English', 2, '2018-11-20', N'Refactoring is about improving the design of existing code without changing its external behavior.', 'Martin Fowler', 'Addison-Wesley', 'Software Engineering';
EXEC #sp_SeedBook 109, '9780135957059', N'The Pragmatic Programmer: 20th Anniversary', 'English', 2, '2019-09-13', N'Illustrates the best approaches and major pitfalls of many different aspects of software development.', 'Andrew Hunt', 'Addison-Wesley', 'Computer Science';
EXEC #sp_SeedBook 110, '9780262033848', N'Introduction to Algorithms', 'English', 3, '2009-07-31', N'A comprehensive textbook and standard reference on modern computer algorithms.', 'Thomas H. Cormen', 'MIT Press', 'Computer Science';
EXEC #sp_SeedBook 111, '9781455586691', N'Deep Work: Rules for Focused Success', 'English', 1, '2016-01-05', N'Deep work is the ability to focus without distraction on a cognitively demanding task.', 'Cal Newport', 'Grand Central', 'Productivity';
EXEC #sp_SeedBook 112, '9780735211292', N'Atomic Habits', 'English', 1, '2018-10-16', N'Tiny Changes, Remarkable Results: An easy & proven way to build good habits and break bad ones.', 'James Clear', 'Avery', 'Productivity';
EXEC #sp_SeedBook 113, '9780062316097', N'Sapiens: A Brief History of Humankind', 'English', 1, '2015-02-10', N'From a renowned historian comes a groundbreaking narrative of humanity’s creation and evolution.', 'Yuval Noah Harari', 'Harper', 'World History';
EXEC #sp_SeedBook 114, '9780062464316', N'Homo Deus: A Brief History of Tomorrow', 'English', 1, '2017-02-21', N'Yuval Noah Harari envisions a not-too-distant world in which we face a new set of challenges.', 'Yuval Noah Harari', 'Harper', 'Anthropology';
EXEC #sp_SeedBook 115, '9780393317558', N'Guns, Germs, and Steel', 'English', 1, '1999-04-17', N'The fates of human societies through geography, agriculture, immunity and technological development.', 'Jared Diamond', 'W. W. Norton', 'World History';
EXEC #sp_SeedBook 116, '9780345539434', N'Cosmos', 'English', 1, '2013-12-10', N'Carl Sagan explores fifteen billion years of cosmic evolution and the science of the universe.', 'Carl Sagan', 'Random House', 'Astronomy';
EXEC #sp_SeedBook 117, '9780393609393', N'Astrophysics for People in a Hurry', 'English', 1, '2017-05-02', N'The essential universe, from the Big Bang to black holes, quarks to quantum mechanics.', 'Neil deGrasse Tyson', 'W. W. Norton', 'Physics';
EXEC #sp_SeedBook 118, '9780198788607', N'The Selfish Gene', 'English', 4, '2016-08-01', N'The gene-centric view of evolution and the biology of animal behavior and natural selection.', 'Richard Dawkins', 'Oxford University Press', 'Genetics';
EXEC #sp_SeedBook 119, '9780441172719', N'Dune', 'English', 1, '1965-08-01', N'Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides and the spice melange.', 'Frank Herbert', 'Chilton Books', 'Science Fiction';
EXEC #sp_SeedBook 120, '9780441569595', N'Neuromancer', 'English', 1, '1984-07-01', N'Case was the sharpest data-thief in the matrix until the wrong people hurt his nervous system.', 'William Gibson', 'Ace Books', 'Cyberpunk';
EXEC #sp_SeedBook 121, '9780553293357', N'Foundation', 'English', 1, '1951-05-01', N'The Galactic Empire has ruled for 12,000 years, but Hari Seldon foresees a catastrophic collapse.', 'Isaac Asimov', 'Gnome Press', 'Science Fiction';
EXEC #sp_SeedBook 122, '9780451524935', N'1984', 'English', 1, '1949-06-08', N'Winston Smith lives in a dystopian totalitarian society ruled by Big Brother and the Party.', 'George Orwell', 'Secker & Warburg', 'Classic Literature';
EXEC #sp_SeedBook 123, '9780060850524', N'Brave New World', 'English', 1, '1932-01-01', N'A dystopian society controlled through psychological conditioning and mandatory hedonism.', 'Aldous Huxley', 'Chatto & Windus', 'Classic Literature';
EXEC #sp_SeedBook 124, '9780061120084', N'To Kill a Mockingbird', 'English', 1, '1960-07-11', N'A lawyer in the Depression-era South defends a black man falsely accused of a crime.', 'Harper Lee', 'Harper', 'Classic Literature';
EXEC #sp_SeedBook 125, '9780743273565', N'The Great Gatsby', 'English', 1, '1925-04-10', N'The tragic story of Jay Gatsby and his unrequited love for the beautiful Daisy Buchanan.', 'F. Scott Fitzgerald', 'Scribner', 'Classic Literature';
EXEC #sp_SeedBook 126, '9780375704024', N'Norwegian Wood', 'English', 1, '2000-09-12', N'Toru Watanabe hears a Beatles song and reminisces about his days as a college student in Tokyo.', 'Haruki Murakami', 'Kodansha', 'Classic Literature';
EXEC #sp_SeedBook 127, '9780547928210', N'The Fellowship of the Ring', 'English', 1, '1954-07-29', N'Frodo Baggins begins the perilous quest across Middle-earth to destroy the One Ring.', 'J. R. R. Tolkien', 'Allen & Unwin', 'Fantasy';
GO

-- 6. Insert Physical Copies
SET IDENTITY_INSERT [BookCopy] ON;

DECLARE @Copies TABLE (cid INT, bid INT, shelf VARCHAR(20), cond VARCHAR(20), st VARCHAR(20));
INSERT INTO @Copies VALUES
(10801, 107, 'SH-10801', 'Good', 'Available'),
(10802, 107, 'SH-10802', 'Good', 'Borrowed'),
(10803, 107, 'SH-10803', 'Good', 'Available'),
(10901, 108, 'SH-10901', 'Good', 'Available'),
(10902, 108, 'SH-10902', 'Good', 'Borrowed'),
(11001, 109, 'SH-11001', 'Good', 'Available'),
(11002, 109, 'SH-11002', 'Good', 'Reserved'),
(11101, 110, 'SH-11101', 'Good', 'Available'),
(11102, 110, 'SH-11102', 'Damaged', 'Available'),
(11201, 111, 'SH-11201', 'Good', 'Available'),
(11202, 111, 'SH-11202', 'Good', 'Borrowed'),
(11301, 112, 'SH-11301', 'Good', 'Available'),
(11302, 112, 'SH-11302', 'Good', 'Available'),
(11401, 113, 'SH-11401', 'Good', 'Available'),
(11402, 113, 'SH-11402', 'Good', 'Borrowed'),
(11501, 114, 'SH-11501', 'Good', 'Available'),
(11601, 115, 'SH-11601', 'Good', 'Available'),
(11602, 115, 'SH-11602', 'Good', 'Available'),
(11701, 116, 'SH-11701', 'Good', 'Available'),
(11702, 116, 'SH-11702', 'Good', 'Borrowed'),
(11801, 117, 'SH-11801', 'Good', 'Available'),
(11901, 118, 'SH-11901', 'Good', 'Available'),
(12001, 119, 'SH-12001', 'Good', 'Available'),
(12002, 119, 'SH-12002', 'Good', 'Borrowed'),
(12101, 120, 'SH-12101', 'Good', 'Available'),
(12201, 121, 'SH-12201', 'Good', 'Available'),
(12202, 121, 'SH-12202', 'Good', 'Reserved'),
(12301, 122, 'SH-12301', 'Good', 'Available'),
(12302, 122, 'SH-12302', 'Good', 'Borrowed'),
(12401, 123, 'SH-12401', 'Good', 'Available'),
(12501, 124, 'SH-12501', 'Good', 'Available'),
(12601, 125, 'SH-12601', 'Good', 'Available'),
(12701, 126, 'SH-12701', 'Good', 'Available'),
(12801, 127, 'SH-12801', 'Good', 'Available'),
(12802, 127, 'SH-12802', 'Good', 'Borrowed');

INSERT INTO [BookCopy] ([copy_id], [book_id], [shelf_location], [copy_condition], [status])
SELECT c.cid, c.bid, c.shelf, c.cond, c.st
FROM @Copies c
WHERE NOT EXISTS (SELECT 1 FROM [BookCopy] WHERE [copy_id] = c.cid);

SET IDENTITY_INSERT [BookCopy] OFF;
GO

-- 7. Insert Loans
SET IDENTITY_INSERT [Loan] ON;

DECLARE @Loans TABLE (lid INT, uid INT, cid INT, renewals SMALLINT, borrowed DATETIME, returned DATETIME, due DATETIME, [proc] INT);
INSERT INTO @Loans VALUES
(5010, 1001, 10802, 0, '2026-11-10 10:00:00', NULL, '2026-12-10 10:00:00', 1001),
(5011, 1826, 10902, 0, '2026-11-15 14:00:00', NULL, '2026-11-29 14:00:00', 1001),
(5012, 1935, 11202, 1, '2026-11-05 09:30:00', NULL, '2026-12-05 09:30:00', 1001),
(5013, 2413, 11402, 0, '2026-10-01 11:00:00', NULL, '2026-10-15 11:00:00', 1001),
(5014, 2481, 11702, 0, '2026-09-20 15:00:00', NULL, '2026-10-20 15:00:00', 1001),
(5015, 1826, 12002, 0, '2026-10-12 16:00:00', NULL, '2026-10-26 16:00:00', 1001),
(5016, 1935, 10481, 1, '2026-08-01 10:00:00', '2026-08-25 11:00:00', '2026-08-29 10:00:00', 1001),
(5017, 2481, 10482, 0, '2026-07-15 13:00:00', '2026-08-10 14:30:00', '2026-08-15 13:00:00', 1001),
(5018, 1001, 10602, 0, '2026-06-01 09:00:00', '2026-06-28 10:15:00', '2026-07-01 09:00:00', 1001),
(5019, 2413, 10701, 0, '2026-09-01 11:30:00', '2026-09-14 16:45:00', '2026-09-15 11:30:00', 1001),
(5020, 1826, 11301, 0, '2026-08-10 10:00:00', '2026-08-22 15:00:00', '2026-08-24 10:00:00', 1001);

INSERT INTO [Loan] ([loan_id], [user_id], [copy_id], [renewal_count], [borrowed_at], [returned_at], [due_at], [processed_by])
SELECT l.lid, l.uid, l.cid, l.renewals, l.borrowed, l.returned, l.due, l.[proc]
FROM @Loans l
WHERE NOT EXISTS (SELECT 1 FROM [Loan] WHERE [loan_id] = l.lid);

SET IDENTITY_INSERT [Loan] OFF;
GO

-- 8. Additional Reservations
SET IDENTITY_INSERT [Reservation] ON;

IF NOT EXISTS (SELECT 1 FROM [Reservation] WHERE [reservation_id] = 8010)
    INSERT INTO [Reservation] ([reservation_id], [user_id], [book_id], [fulfilled_copy_id], [reserved_at], [status])
    VALUES (8010, 1826, 109, 11002, '2026-11-20 09:00:00', 'FULFILLED');

IF NOT EXISTS (SELECT 1 FROM [Reservation] WHERE [reservation_id] = 8011)
    INSERT INTO [Reservation] ([reservation_id], [user_id], [book_id], [fulfilled_copy_id], [reserved_at], [status])
    VALUES (8011, 2413, 121, 12202, '2026-11-22 14:00:00', 'FULFILLED');

IF NOT EXISTS (SELECT 1 FROM [Reservation] WHERE [reservation_id] = 8012)
    INSERT INTO [Reservation] ([reservation_id], [user_id], [book_id], [fulfilled_copy_id], [reserved_at], [status])
    VALUES (8012, 2481, 112, NULL, '2026-11-23 11:30:00', 'PENDING');

SET IDENTITY_INSERT [Reservation] OFF;
GO
