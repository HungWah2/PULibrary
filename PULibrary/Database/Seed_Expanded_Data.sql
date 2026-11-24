-- ====================================================================================================
-- JINGYI PUBLIC LIBRARY: SEED EXPANDED DATA SCRIPT
-- Adds 24 diverse books, authority metadata, copies, users, loans, and reservations for pagination testing.
-- ====================================================================================================
USE [LibraryManagementSystem];
GO

SET NOCOUNT ON;

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

-- 5. Helper procedure to safely insert a book and associations
GO
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

-- 7. Insert Loans (Mix of active, overdue, returned)
SET IDENTITY_INSERT [Loan] ON;

DECLARE @Loans TABLE (lid INT, uid INT, cid INT, renewals SMALLINT, borrowed DATETIME, returned DATETIME, due DATETIME, [proc] INT);
INSERT INTO @Loans VALUES
-- Active loans
(5010, 1001, 10802, 0, '2026-11-10 10:00:00', NULL, '2026-12-10 10:00:00', 1001),
(5011, 1826, 10902, 0, '2026-11-15 14:00:00', NULL, '2026-11-29 14:00:00', 1001),
(5012, 1935, 11202, 1, '2026-11-05 09:30:00', NULL, '2026-12-05 09:30:00', 1001),
-- Overdue loans
(5013, 2413, 11402, 0, '2026-10-01 11:00:00', NULL, '2026-10-15 11:00:00', 1001),
(5014, 2481, 11702, 0, '2026-09-20 15:00:00', NULL, '2026-10-20 15:00:00', 1001),
(5015, 1826, 12002, 0, '2026-10-12 16:00:00', NULL, '2026-10-26 16:00:00', 1001),
-- Returned loans (History)
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

-- 8. Additional Reservations (Fulfilled & Pending)
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

PRINT 'Seed expanded data executed successfully.';
GO
