using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PULibrary.Data;
using PULibrary.Models;

namespace PULibrary.Controllers;

public class AdminController : Controller
{
    private readonly LibraryDbContext _context;

    public AdminController(LibraryDbContext context)
    {
        _context = context;
    }

    public override void OnActionExecuting(Microsoft.AspNetCore.Mvc.Filters.ActionExecutingContext context)
    {
        base.OnActionExecuting(context);
        int? roleId = context.HttpContext.Session.GetInt32("RoleId");
        if (roleId.HasValue && roleId.Value < 3)
        {
            context.Result = new RedirectToActionResult("Index", "Catalog", null);
            TempData["ErrorMessage"] = "Access restricted: The Librarian Workspace is reserved for staff members.";
        }
    }

    // GET: /Admin or /Admin/Index or /Admin/Dashboard
    public async Task<IActionResult> Index()
    {
        return await Dashboard();
    }

    public async Task<IActionResult> Dashboard()
    {
        var now = DateTime.Now;

        var activeLoansQuery = _context.Loans
            .Include(l => l.User)
            .Include(l => l.Copy)
                .ThenInclude(c => c!.Book)
            .Where(l => l.ReturnedAt == null);

        var activeLoansList = await activeLoansQuery.ToListAsync();

        var overdueLoansList = activeLoansList
            .Where(l => l.DueAt < now)
            .OrderBy(l => l.DueAt)
            .ToList();

        var normalActiveLoansList = activeLoansList
            .Where(l => l.DueAt >= now)
            .OrderBy(l => l.DueAt)
            .ToList();

        var pendingRes = await _context.Reservations
            .Include(r => r.User)
            .Include(r => r.Book)
            .FirstOrDefaultAsync(r => r.Status == "PENDING");

        int? suggestedCopyId = null;
        if (pendingRes != null)
        {
            var avCopy = await _context.BookCopies
                .FirstOrDefaultAsync(c => c.BookId == pendingRes.BookId && c.Status == "Available");
            suggestedCopyId = avCopy?.CopyId;
        }

        var fulfilledRes = await _context.Reservations
            .Include(r => r.User)
            .Include(r => r.Book)
            .Include(r => r.FulfilledCopy)
            .FirstOrDefaultAsync(r => r.Status == "FULFILLED");

        var copyInRepair = await _context.BookCopies
            .Include(c => c.Book)
            .FirstOrDefaultAsync(c => c.CopyCondition == "Damaged");

        var totalCopies = await _context.BookCopies.CountAsync();
        var availableCopies = await _context.BookCopies.CountAsync(c => c.Status == "Available");
        var awaitingFulfillment = await _context.Reservations.CountAsync(r => r.Status == "PENDING");
        var copiesInRepairCount = await _context.BookCopies.CountAsync(c => c.CopyCondition == "Damaged");
        var totalBooks = await _context.Books.CountAsync();

        var vm = new AdminDashboardViewModel
        {
            ActiveLoansCount = activeLoansList.Count,
            OverdueLoansCount = overdueLoansList.Count,
            AwaitingFulfillmentCount = awaitingFulfillment,
            CopiesInRepairCount = copiesInRepairCount,
            AvailableCopiesCount = availableCopies,
            TotalCopiesCount = totalCopies,
            TotalBooksCount = totalBooks,
            OverdueLoans = overdueLoansList.Select(l => new LoanItemViewModel
            {
                LoanId = l.LoanId,
                UserId = l.UserId,
                BorrowerName = l.User?.Name ?? "Unknown",
                BookTitle = l.Copy?.Book?.Title ?? "Unknown Title",
                CopyId = l.CopyId,
                ShelfLocation = l.Copy?.ShelfLocation ?? "",
                BorrowedAt = l.BorrowedAt,
                DueAt = l.DueAt,
                RenewalCount = l.RenewalCount,
                IsOverdue = true
            }).ToList(),
            ActiveLoans = normalActiveLoansList.Select(l => new LoanItemViewModel
            {
                LoanId = l.LoanId,
                UserId = l.UserId,
                BorrowerName = l.User?.Name ?? "Unknown",
                BookTitle = l.Copy?.Book?.Title ?? "Unknown Title",
                CopyId = l.CopyId,
                ShelfLocation = l.Copy?.ShelfLocation ?? "",
                BorrowedAt = l.BorrowedAt,
                DueAt = l.DueAt,
                RenewalCount = l.RenewalCount,
                IsOverdue = false
            }).ToList(),
            PendingReservation = pendingRes == null ? null : new ReservationItemViewModel
            {
                ReservationId = pendingRes.ReservationId,
                UserId = pendingRes.UserId,
                ReaderName = pendingRes.User?.Name ?? "",
                BookId = pendingRes.BookId,
                BookTitle = pendingRes.Book?.Title ?? "",
                ReservedAt = pendingRes.ReservedAt,
                Status = pendingRes.Status,
                SuggestedAvailableCopyId = suggestedCopyId
            },
            FulfilledReservation = fulfilledRes == null ? null : new ReservationItemViewModel
            {
                ReservationId = fulfilledRes.ReservationId,
                UserId = fulfilledRes.UserId,
                ReaderName = fulfilledRes.User?.Name ?? "",
                BookId = fulfilledRes.BookId,
                BookTitle = fulfilledRes.Book?.Title ?? "",
                FulfilledCopyId = fulfilledRes.FulfilledCopyId,
                ReservedAt = fulfilledRes.ReservedAt,
                Status = fulfilledRes.Status
            },
            CopyInRepair = copyInRepair == null ? null : new BookCopyItemViewModel
            {
                CopyId = copyInRepair.CopyId,
                BookId = copyInRepair.BookId,
                BookTitle = copyInRepair.Book?.Title ?? "",
                ShelfLocation = copyInRepair.ShelfLocation,
                CopyCondition = copyInRepair.CopyCondition,
                Status = copyInRepair.Status
            }
        };

        return View("Dashboard", vm);
    }

    // GET: /Admin/Books
    public async Task<IActionResult> Books(string? search, string? category, string? language, string? availability, int page = 1, int pageSize = 10)
    {
        var query = _context.Books
            .Include(b => b.AssociateBookAuthors).ThenInclude(aba => aba.Author)
            .Include(b => b.AssociateBookPublishers).ThenInclude(abp => abp.Publisher)
            .Include(b => b.AssociateBookCategories).ThenInclude(abc => abc.Category)
            .Include(b => b.Copies)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(b => b.Title.ToLower().Contains(term) ||
                                     (b.Isbn != null && b.Isbn.Contains(term)) ||
                                     b.AssociateBookAuthors.Any(a => a.Author!.AuthorName.ToLower().Contains(term)) ||
                                     b.AssociateBookPublishers.Any(p => p.Publisher!.PublisherName.ToLower().Contains(term)));
        }

        if (!string.IsNullOrWhiteSpace(language) && language != "All")
        {
            query = query.Where(b => b.Language == language);
        }

        if (!string.IsNullOrWhiteSpace(category) && category != "All")
        {
            query = query.Where(b => b.AssociateBookCategories.Any(c => c.Category!.CategoryName == category));
        }

        if (availability == "Available")
        {
            query = query.Where(b => b.Copies.Any(c => c.Status == "Available"));
        }

        query = query.OrderBy(b => b.Title);

        int totalCount = await query.CountAsync();
        int totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        page = Math.Max(1, Math.Min(page, totalPages > 0 ? totalPages : 1));

        var books = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        var allCats = await _context.Categories.Select(c => c.CategoryName).Distinct().OrderBy(c => c).ToListAsync();
        var allLangs = await _context.Books.Select(b => b.Language).Distinct().OrderBy(l => l).ToListAsync();
        var totalPhysicalCopies = await _context.BookCopies.CountAsync();

        var bookItems = books.Select(b => new BookCatalogItemViewModel
        {
            BookId = b.BookId,
            Isbn = b.Isbn,
            Title = b.Title,
            Language = b.Language,
            Edition = b.Edition,
            CoverImage = b.CoverImage,
            Authors = b.AssociateBookAuthors.Select(a => a.Author?.AuthorName ?? "").Where(s => !string.IsNullOrEmpty(s)).ToList(),
            Publishers = b.AssociateBookPublishers.Select(p => p.Publisher?.PublisherName ?? "").Where(s => !string.IsNullOrEmpty(s)).ToList(),
            Categories = b.AssociateBookCategories.Select(c => c.Category?.CategoryName ?? "").Where(s => !string.IsNullOrEmpty(s)).ToList(),
            TotalCopies = b.Copies.Count,
            AvailableCopies = b.Copies.Count(c => c.Status == "Available")
        }).ToList();

        var vm = new BookCatalogViewModel
        {
            SearchQuery = search,
            SelectedCategory = category,
            SelectedLanguage = language,
            SelectedAvailability = availability,
            Books = bookItems,
            AllCategories = allCats,
            AllLanguages = allLangs,
            TotalBooksCount = totalCount,
            TotalPhysicalCopiesCount = totalPhysicalCopies,
            CurrentPage = page,
            TotalPages = totalPages,
            PageSize = pageSize
        };

        return View(vm);
    }

    // POST: /Admin/AddBook
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddBook(string title, string isbn, string language, short edition, string? description, string authorName, string publisherName, string categoryName)
    {
        var book = new Book
        {
            Title = title.Trim(),
            Isbn = string.IsNullOrWhiteSpace(isbn) ? null : isbn.Trim(),
            Language = string.IsNullOrWhiteSpace(language) ? "English" : language.Trim(),
            Edition = edition > 0 ? edition : (short)1,
            Description = description?.Trim(),
            PublishedDate = DateTime.Now
        };

        _context.Books.Add(book);
        await _context.SaveChangesAsync();

        if (!string.IsNullOrWhiteSpace(authorName))
        {
            var author = await _context.Authors.FirstOrDefaultAsync(a => a.AuthorName == authorName.Trim())
                         ?? new Author { AuthorName = authorName.Trim() };
            if (author.AuthorId == 0)
            {
                _context.Authors.Add(author);
                await _context.SaveChangesAsync();
            }
            _context.AssociateBookAuthors.Add(new AssociateBookAuthor { BookId = book.BookId, AuthorId = author.AuthorId });
        }

        if (!string.IsNullOrWhiteSpace(publisherName))
        {
            var pub = await _context.Publishers.FirstOrDefaultAsync(p => p.PublisherName == publisherName.Trim())
                      ?? new Publisher { PublisherName = publisherName.Trim() };
            if (pub.PublisherId == 0)
            {
                _context.Publishers.Add(pub);
                await _context.SaveChangesAsync();
            }
            _context.AssociateBookPublishers.Add(new AssociateBookPublisher { BookId = book.BookId, PublisherId = pub.PublisherId });
        }

        if (!string.IsNullOrWhiteSpace(categoryName))
        {
            var cat = await _context.Categories.FirstOrDefaultAsync(c => c.CategoryName == categoryName.Trim())
                      ?? new Category { CategoryName = categoryName.Trim() };
            if (cat.CategoryId == 0)
            {
                _context.Categories.Add(cat);
                await _context.SaveChangesAsync();
            }
            _context.AssociateBookCategories.Add(new AssociateBookCategory { BookId = book.BookId, CategoryId = cat.CategoryId });
        }

        // Add 1 default copy with unique shelf location
        var copy = new BookCopy
        {
            BookId = book.BookId,
            ShelfLocation = $"SH-{book.BookId:D4}-01",
            CopyCondition = "Good",
            Status = "Available"
        };
        _context.BookCopies.Add(copy);

        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Book '{title}' added successfully with initial copy!";
        return RedirectToAction(nameof(Books));
    }

    // POST: /Admin/UpdateBook
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateBook(int bookId, string title, string? isbn, string language, short edition, string? description, string authorName, string publisherName, string categoryName)
    {
        var book = await _context.Books
            .Include(b => b.AssociateBookAuthors)
            .Include(b => b.AssociateBookPublishers)
            .Include(b => b.AssociateBookCategories)
            .FirstOrDefaultAsync(b => b.BookId == bookId);

        if (book == null)
        {
            TempData["ErrorMessage"] = "Book not found.";
            return RedirectToAction(nameof(Books));
        }

        book.Title = title.Trim();
        book.Isbn = string.IsNullOrWhiteSpace(isbn) ? null : isbn.Trim();
        book.Language = string.IsNullOrWhiteSpace(language) ? "English" : language.Trim();
        book.Edition = edition > 0 ? edition : (short)1;
        book.Description = description?.Trim();

        // Update Author
        if (!string.IsNullOrWhiteSpace(authorName))
        {
            var author = await _context.Authors.FirstOrDefaultAsync(a => a.AuthorName.ToLower() == authorName.Trim().ToLower())
                         ?? new Author { AuthorName = authorName.Trim() };
            if (author.AuthorId == 0)
            {
                _context.Authors.Add(author);
                await _context.SaveChangesAsync();
            }
            _context.AssociateBookAuthors.RemoveRange(book.AssociateBookAuthors);
            book.AssociateBookAuthors.Add(new AssociateBookAuthor { BookId = book.BookId, AuthorId = author.AuthorId });
        }

        // Update Publisher
        if (!string.IsNullOrWhiteSpace(publisherName))
        {
            var pub = await _context.Publishers.FirstOrDefaultAsync(p => p.PublisherName.ToLower() == publisherName.Trim().ToLower())
                      ?? new Publisher { PublisherName = publisherName.Trim() };
            if (pub.PublisherId == 0)
            {
                _context.Publishers.Add(pub);
                await _context.SaveChangesAsync();
            }
            _context.AssociateBookPublishers.RemoveRange(book.AssociateBookPublishers);
            book.AssociateBookPublishers.Add(new AssociateBookPublisher { BookId = book.BookId, PublisherId = pub.PublisherId });
        }

        // Update Category
        if (!string.IsNullOrWhiteSpace(categoryName))
        {
            var cat = await _context.Categories.FirstOrDefaultAsync(c => c.CategoryName.ToLower() == categoryName.Trim().ToLower())
                      ?? new Category { CategoryName = categoryName.Trim() };
            if (cat.CategoryId == 0)
            {
                _context.Categories.Add(cat);
                await _context.SaveChangesAsync();
            }
            _context.AssociateBookCategories.RemoveRange(book.AssociateBookCategories);
            book.AssociateBookCategories.Add(new AssociateBookCategory { BookId = book.BookId, CategoryId = cat.CategoryId });
        }

        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Book #{book.BookId} '{book.Title}' updated successfully!";
        return RedirectToAction(nameof(Books));
    }

    // POST: /Admin/DeleteBook
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteBook(int bookId)
    {
        var book = await _context.Books
            .Include(b => b.Copies).ThenInclude(c => c.Loans)
            .Include(b => b.Reservations)
            .Include(b => b.AssociateBookAuthors)
            .Include(b => b.AssociateBookPublishers)
            .Include(b => b.AssociateBookCategories)
            .FirstOrDefaultAsync(b => b.BookId == bookId);

        if (book == null)
        {
            TempData["ErrorMessage"] = "Book not found.";
            return RedirectToAction(nameof(Books));
        }

        if (book.Copies.Any(c => c.Status == "Borrowed" || c.Loans.Any(l => l.ReturnedAt == null)))
        {
            TempData["ErrorMessage"] = $"Cannot delete book '{book.Title}' because copies are currently borrowed or on active loan.";
            return RedirectToAction(nameof(Books));
        }

        foreach (var copy in book.Copies)
        {
            _context.Loans.RemoveRange(copy.Loans);
        }
        _context.BookCopies.RemoveRange(book.Copies);
        _context.Reservations.RemoveRange(book.Reservations);
        _context.AssociateBookAuthors.RemoveRange(book.AssociateBookAuthors);
        _context.AssociateBookPublishers.RemoveRange(book.AssociateBookPublishers);
        _context.AssociateBookCategories.RemoveRange(book.AssociateBookCategories);

        _context.Books.Remove(book);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Book '{book.Title}' deleted from collection.";
        return RedirectToAction(nameof(Books));
    }

    // GET: /Admin/Copies
    public async Task<IActionResult> Copies(string? status, string? condition, string? search, int page = 1, int pageSize = 15)
    {
        var query = _context.BookCopies
            .Include(c => c.Book)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(c => c.Book!.Title.ToLower().Contains(term) ||
                                     c.ShelfLocation.ToLower().Contains(term) ||
                                     c.CopyId.ToString().Contains(term));
        }

        if (!string.IsNullOrWhiteSpace(status) && status != "All")
        {
            query = query.Where(c => c.Status == status);
        }

        if (!string.IsNullOrWhiteSpace(condition) && condition != "All")
        {
            query = query.Where(c => c.CopyCondition == condition);
        }

        query = query.OrderBy(c => c.BookId).ThenBy(c => c.CopyId);

        int totalCount = await query.CountAsync();
        int totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        page = Math.Max(1, Math.Min(page, totalPages > 0 ? totalPages : 1));

        var copies = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        ViewBag.Search = search;
        ViewBag.Status = status;
        ViewBag.Condition = condition;
        ViewBag.CurrentPage = page;
        ViewBag.TotalPages = totalPages;
        ViewBag.TotalCount = totalCount;
        ViewBag.PageSize = pageSize;
        ViewBag.Books = await _context.Books.OrderBy(b => b.Title).ToListAsync();

        return View(copies);
    }

    // POST: /Admin/AddCopy
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddCopy(int bookId, string shelfLocation, string copyCondition)
    {
        if (string.IsNullOrWhiteSpace(shelfLocation))
        {
            TempData["ErrorMessage"] = "Shelf location cannot be empty.";
            return RedirectToAction(nameof(Copies));
        }

        string cleanShelf = shelfLocation.Trim();
        bool shelfExists = await _context.BookCopies.AnyAsync(c => c.ShelfLocation.ToLower() == cleanShelf.ToLower());
        if (shelfExists)
        {
            TempData["ErrorMessage"] = $"Shelf location '{cleanShelf}' is already assigned to another physical copy. Each shelf location must be unique.";
            return RedirectToAction(nameof(Copies));
        }

        var copy = new BookCopy
        {
            BookId = bookId,
            ShelfLocation = cleanShelf,
            CopyCondition = string.IsNullOrWhiteSpace(copyCondition) ? "Good" : copyCondition,
            Status = "Available"
        };

        _context.BookCopies.Add(copy);
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Physical copy #{copy.CopyId} added at shelf location '{copy.ShelfLocation}'!";
        return RedirectToAction(nameof(Copies));
    }

    // POST: /Admin/DeleteCopy
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteCopy(int copyId)
    {
        var copy = await _context.BookCopies
            .Include(c => c.Loans)
            .FirstOrDefaultAsync(c => c.CopyId == copyId);

        if (copy == null)
        {
            TempData["ErrorMessage"] = "Copy not found.";
            return RedirectToAction(nameof(Copies));
        }

        if (copy.Status == "Borrowed" || copy.Loans.Any(l => l.ReturnedAt == null))
        {
            TempData["ErrorMessage"] = $"Cannot delete physical copy #{copyId} because it is currently borrowed.";
            return RedirectToAction(nameof(Copies));
        }

        _context.Loans.RemoveRange(copy.Loans);
        _context.BookCopies.Remove(copy);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Physical copy #{copyId} removed from inventory.";
        return RedirectToAction(nameof(Copies));
    }

    // POST: /Admin/UpdateCopyCondition
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateCopyCondition(int copyId, string condition, string status)
    {
        var copy = await _context.BookCopies.FindAsync(copyId);
        if (copy != null)
        {
            copy.CopyCondition = condition;
            copy.Status = status;
            await _context.SaveChangesAsync();
            TempData["SuccessMessage"] = $"Copy #{copyId} updated!";
        }
        return RedirectToAction(nameof(Copies));
    }

    // GET: /Admin/Loans
    public async Task<IActionResult> Loans(string? filter, int page = 1, int pageSize = 10)
    {
        var query = _context.Loans
            .Include(l => l.User)
            .Include(l => l.Copy).ThenInclude(c => c!.Book)
            .Include(l => l.ProcessedByUser)
            .AsQueryable();

        var now = DateTime.Now;
        if (filter == "overdue")
        {
            query = query.Where(l => l.ReturnedAt == null && l.DueAt < now);
        }
        else if (filter == "active")
        {
            query = query.Where(l => l.ReturnedAt == null);
        }
        else if (filter == "returned")
        {
            query = query.Where(l => l.ReturnedAt != null);
        }

        query = query.OrderByDescending(l => l.BorrowedAt);

        int totalCount = await query.CountAsync();
        int totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        page = Math.Max(1, Math.Min(page, totalPages > 0 ? totalPages : 1));

        var loans = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        ViewBag.CurrentFilter = filter ?? "all";
        ViewBag.CurrentPage = page;
        ViewBag.TotalPages = totalPages;
        ViewBag.TotalCount = totalCount;
        ViewBag.PageSize = pageSize;

        return View(loans);
    }

    // GET: /Admin/Circulation
    public async Task<IActionResult> Circulation()
    {
        var users = await _context.Users
            .Include(u => u.Role).ThenInclude(r => r!.Policy)
            .Where(u => u.Status == "Active")
            .OrderBy(u => u.Name)
            .ToListAsync();

        var availableCopies = await _context.BookCopies
            .Include(c => c.Book)
            .Where(c => c.Status == "Available")
            .OrderBy(c => c.Book!.Title)
            .ToListAsync();

        var activeLoans = await _context.Loans
            .Include(l => l.User)
            .Include(l => l.Copy).ThenInclude(c => c!.Book)
            .Where(l => l.ReturnedAt == null)
            .OrderBy(l => l.DueAt)
            .ToListAsync();

        var fulfilledReservations = await _context.Reservations
            .Include(r => r.User)
            .Include(r => r.Book)
            .Include(r => r.FulfilledCopy)
            .Where(r => r.Status == "FULFILLED")
            .OrderBy(r => r.ReservedAt)
            .ToListAsync();

        var vm = new CirculationDeskViewModel
        {
            ActiveUsers = users,
            AvailableCopies = availableCopies,
            ActiveLoans = activeLoans,
            FulfilledReservations = fulfilledReservations
        };

        return View(vm);
    }

    // POST: /Admin/CheckOutReservation
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CheckOutReservation(int reservationId)
    {
        var res = await _context.Reservations
            .Include(r => r.User).ThenInclude(u => u!.Role).ThenInclude(ro => ro!.Policy)
            .Include(r => r.FulfilledCopy)
            .FirstOrDefaultAsync(r => r.ReservationId == reservationId);

        if (res == null || res.Status != "FULFILLED" || res.FulfilledCopy == null || res.User == null)
        {
            TempData["ErrorMessage"] = "Fulfilled reservation not found or invalid.";
            return RedirectToAction(nameof(Circulation));
        }

        var policy = res.User.Role?.Policy;
        int loanDays = policy?.LoanDays ?? 14;

        var loan = new Loan
        {
            UserId = res.UserId,
            CopyId = res.FulfilledCopyId!.Value,
            BorrowedAt = DateTime.Now,
            DueAt = DateTime.Now.AddDays(loanDays),
            RenewalCount = 0,
            ProcessedBy = HttpContext.Session.GetInt32("UserId") ?? 1001
        };

        res.FulfilledCopy.Status = "Borrowed";
        res.Status = "COMPLETED";

        _context.Loans.Add(loan);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Reserved copy #{loan.CopyId} checked out to {res.User.Name}! Due date: {loan.DueAt:dd MMM yyyy}.";
        return RedirectToAction(nameof(Circulation));
    }

    // POST: /Admin/IssueBook
    [HttpPost]
    public async Task<IActionResult> IssueBook(int userId, int copyId)
    {
        var user = await _context.Users
            .Include(u => u.Role).ThenInclude(r => r!.Policy)
            .Include(u => u.Loans)
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null || user.Status != "Active")
        {
            TempData["ErrorMessage"] = "Reader not found or account is suspended.";
            return RedirectToAction(nameof(Circulation));
        }

        var policy = user.Role?.Policy;
        var activeLoansCount = user.Loans.Count(l => l.ReturnedAt == null);
        if (policy != null && activeLoansCount >= policy.MaxLoans)
        {
            TempData["ErrorMessage"] = $"Reader has reached their maximum borrowing limit of {policy.MaxLoans} books.";
            return RedirectToAction(nameof(Circulation));
        }

        var copy = await _context.BookCopies.FindAsync(copyId);
        if (copy == null || copy.Status != "Available")
        {
            TempData["ErrorMessage"] = "Selected copy is not available for loan.";
            return RedirectToAction(nameof(Circulation));
        }

        int loanDays = policy?.LoanDays ?? 14;
        var loan = new Loan
        {
            UserId = userId,
            CopyId = copyId,
            RenewalCount = 0,
            BorrowedAt = DateTime.Now,
            DueAt = DateTime.Now.AddDays(loanDays),
            ProcessedBy = 1001 // Staff Jamie Lee
        };

        copy.Status = "Borrowed";
        _context.Loans.Add(loan);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Loan {loan.LoanId} successfully created for {user.Name}! Due date: {loan.DueAt:dd MMM yyyy}.";
        return RedirectToAction(nameof(Circulation));
    }

    // POST: /Admin/ReturnLoan
    [HttpPost]
    public async Task<IActionResult> ReturnLoan(int loanId, string? returnUrl)
    {
        var loan = await _context.Loans
            .Include(l => l.Copy)
            .FirstOrDefaultAsync(l => l.LoanId == loanId);

        if (loan == null)
        {
            TempData["ErrorMessage"] = "Loan not found.";
            return RedirectToAction(nameof(Dashboard));
        }

        loan.ReturnedAt = DateTime.Now;
        if (loan.Copy != null)
        {
            loan.Copy.Status = "Available";
        }

        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Loan {loanId} successfully marked as returned!";

        if (!string.IsNullOrEmpty(returnUrl))
        {
            return Redirect(returnUrl);
        }
        return RedirectToAction(nameof(Dashboard));
    }

    // POST: /Admin/RenewLoan
    [HttpPost]
    public async Task<IActionResult> RenewLoan(int loanId, string? returnUrl)
    {
        var loan = await _context.Loans
            .Include(l => l.User).ThenInclude(u => u!.Role).ThenInclude(r => r!.Policy)
            .FirstOrDefaultAsync(l => l.LoanId == loanId);

        if (loan == null)
        {
            TempData["ErrorMessage"] = "Loan not found.";
            return RedirectToAction(nameof(Circulation));
        }

        var policy = loan.User?.Role?.Policy;
        var maxRenewals = policy?.MaxRenewals ?? 1;
        if (loan.RenewalCount >= maxRenewals)
        {
            TempData["ErrorMessage"] = $"Cannot renew: Maximum renewals ({maxRenewals}) reached for this reader's role.";
            return RedirectToAction(nameof(Circulation));
        }

        int extensionDays = policy?.LoanDays ?? 14;
        loan.RenewalCount++;
        loan.DueAt = loan.DueAt.AddDays(extensionDays);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Loan {loanId} renewed! New due date: {loan.DueAt:dd MMM yyyy}. Renewal count: {loan.RenewalCount}/{maxRenewals}.";
        if (!string.IsNullOrEmpty(returnUrl))
        {
            return Redirect(returnUrl);
        }
        return RedirectToAction(nameof(Circulation));
    }

    // GET: /Admin/Reservations
    public async Task<IActionResult> Reservations()
    {
        var reservations = await _context.Reservations
            .Include(r => r.User)
            .Include(r => r.Book)
            .Include(r => r.FulfilledCopy)
            .OrderByDescending(r => r.ReservedAt)
            .ToListAsync();

        ViewBag.AvailableCopies = await _context.BookCopies
            .Where(c => c.Status == "Available")
            .ToListAsync();

        return View(reservations);
    }

    // POST: /Admin/FulfillReservation
    [HttpPost]
    public async Task<IActionResult> FulfillReservation(int reservationId, int? copyId, string? returnUrl)
    {
        var res = await _context.Reservations
            .Include(r => r.Book)
            .FirstOrDefaultAsync(r => r.ReservationId == reservationId);

        if (res == null)
        {
            TempData["ErrorMessage"] = "Reservation not found.";
            return RedirectToAction(nameof(Dashboard));
        }

        BookCopy? copy = null;
        if (copyId.HasValue)
        {
            copy = await _context.BookCopies.FindAsync(copyId.Value);
        }
        else
        {
            copy = await _context.BookCopies.FirstOrDefaultAsync(c => c.BookId == res.BookId && c.Status == "Available");
        }

        if (copy == null)
        {
            TempData["ErrorMessage"] = "No available copy found to fulfill this reservation.";
            return RedirectToAction(nameof(Dashboard));
        }

        res.FulfilledCopyId = copy.CopyId;
        res.Status = "FULFILLED";
        copy.Status = "Reserved";

        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Reservation {reservationId} fulfilled with Copy {copy.CopyId}!";

        if (!string.IsNullOrEmpty(returnUrl))
        {
            return Redirect(returnUrl);
        }
        return RedirectToAction(nameof(Dashboard));
    }

    // GET: /Admin/Users
    public async Task<IActionResult> Users()
    {
        ViewBag.Roles = await _context.Roles.ToListAsync();
        var users = await _context.Users
            .Include(u => u.Role).ThenInclude(r => r!.Policy)
            .Include(u => u.Loans)
            .ToListAsync();
        return View(users);
    }

    // POST: /Admin/UpdateUser
    [HttpPost]
    public async Task<IActionResult> UpdateUser(int userId, string name, string email, string phone, string status, short roleId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user != null)
        {
            user.Name = name.Trim().Length > 30 ? name.Trim().Substring(0, 30) : name.Trim();
            user.Email = email.Trim().Length > 100 ? email.Trim().Substring(0, 100) : email.Trim();
            if (!string.IsNullOrWhiteSpace(phone))
            {
                var digits = new string(phone.Where(char.IsDigit).ToArray());
                if (digits.Length > 10) digits = digits.Substring(0, 10);
                user.Phone = digits.PadRight(10, '0');
            }
            // Database constraint status_enum allows only 'Active' or 'Suspend'
            user.Status = string.Equals(status, "Active", StringComparison.OrdinalIgnoreCase) ? "Active" : "Suspend";
            user.RoleId = roleId;

            // Ensure updated_at > created_at for updated_after check constraint
            var now = DateTime.Now;
            user.UpdatedAt = now > user.CreatedAt ? now : user.CreatedAt.AddSeconds(1);

            await _context.SaveChangesAsync();
            TempData["SuccessMessage"] = $"User #{userId} ({user.Name}) account customized successfully!";
        }
        return RedirectToAction(nameof(Users));
    }

    // GET: /Admin/Policies
    public async Task<IActionResult> Policies()
    {
        var roles = await _context.Roles
            .Include(r => r.Policy)
            .Include(r => r.Users)
            .ToListAsync();
        return View(roles);
    }

    // POST: /Admin/UpdatePolicy
    [HttpPost]
    public async Task<IActionResult> UpdatePolicy(short policyId, short loanDays, short maxLoans, short maxRenewals)
    {
        var policy = await _context.Policies.FindAsync(policyId);
        if (policy != null)
        {
            policy.LoanDays = loanDays;
            policy.MaxLoans = maxLoans;
            policy.MaxRenewals = maxRenewals;
            await _context.SaveChangesAsync();
            TempData["SuccessMessage"] = "Borrowing policy updated successfully!";
        }
        return RedirectToAction(nameof(Policies));
    }

    // GET: /Admin/Metadata
    public async Task<IActionResult> Metadata()
    {
        ViewBag.Authors = await _context.Authors.Include(a => a.AssociateBookAuthors).OrderBy(a => a.AuthorName).ToListAsync();
        ViewBag.Publishers = await _context.Publishers.Include(p => p.AssociateBookPublishers).OrderBy(p => p.PublisherName).ToListAsync();
        ViewBag.Categories = await _context.Categories.Include(c => c.AssociateBookCategories).OrderBy(c => c.CategoryName).ToListAsync();
        return View();
    }

    // POST: /Admin/AddAuthor
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddAuthor(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            TempData["ErrorMessage"] = "Author name cannot be empty.";
            return RedirectToAction(nameof(Metadata));
        }

        string trimmedName = name.Trim();
        if (trimmedName.Length > 30)
        {
            TempData["ErrorMessage"] = "Author name cannot exceed 30 characters.";
            return RedirectToAction(nameof(Metadata));
        }

        bool exists = await _context.Authors.AnyAsync(a => a.AuthorName.ToLower() == trimmedName.ToLower());
        if (exists)
        {
            TempData["ErrorMessage"] = $"Author '{trimmedName}' already exists.";
            return RedirectToAction(nameof(Metadata));
        }

        _context.Authors.Add(new Author { AuthorName = trimmedName });
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Author '{trimmedName}' added successfully.";
        return RedirectToAction(nameof(Metadata));
    }

    // POST: /Admin/UpdateAuthor
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateAuthor(short authorId, string name)
    {
        var author = await _context.Authors.FindAsync(authorId);
        if (author == null)
        {
            TempData["ErrorMessage"] = "Author not found.";
            return RedirectToAction(nameof(Metadata));
        }

        if (string.IsNullOrWhiteSpace(name))
        {
            TempData["ErrorMessage"] = "Author name cannot be empty.";
            return RedirectToAction(nameof(Metadata));
        }

        string trimmedName = name.Trim();
        if (trimmedName.Length > 30)
        {
            TempData["ErrorMessage"] = "Author name cannot exceed 30 characters.";
            return RedirectToAction(nameof(Metadata));
        }

        bool duplicate = await _context.Authors.AnyAsync(a => a.AuthorId != authorId && a.AuthorName.ToLower() == trimmedName.ToLower());
        if (duplicate)
        {
            TempData["ErrorMessage"] = $"Another author with the name '{trimmedName}' already exists.";
            return RedirectToAction(nameof(Metadata));
        }

        author.AuthorName = trimmedName;
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Author '{trimmedName}' updated successfully.";
        return RedirectToAction(nameof(Metadata));
    }

    // POST: /Admin/DeleteAuthor
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteAuthor(short authorId)
    {
        var author = await _context.Authors.Include(a => a.AssociateBookAuthors).FirstOrDefaultAsync(a => a.AuthorId == authorId);
        if (author == null)
        {
            TempData["ErrorMessage"] = "Author not found.";
            return RedirectToAction(nameof(Metadata));
        }

        if (author.AssociateBookAuthors.Any())
        {
            TempData["ErrorMessage"] = $"Cannot delete '{author.AuthorName}' because it is linked to {author.AssociateBookAuthors.Count} book title(s).";
            return RedirectToAction(nameof(Metadata));
        }

        _context.Authors.Remove(author);
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Author '{author.AuthorName}' deleted successfully.";
        return RedirectToAction(nameof(Metadata));
    }

    // POST: /Admin/AddPublisher
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddPublisher(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            TempData["ErrorMessage"] = "Publisher name cannot be empty.";
            return RedirectToAction(nameof(Metadata));
        }

        string trimmedName = name.Trim();
        if (trimmedName.Length > 30)
        {
            TempData["ErrorMessage"] = "Publisher name cannot exceed 30 characters.";
            return RedirectToAction(nameof(Metadata));
        }

        bool exists = await _context.Publishers.AnyAsync(p => p.PublisherName.ToLower() == trimmedName.ToLower());
        if (exists)
        {
            TempData["ErrorMessage"] = $"Publisher '{trimmedName}' already exists.";
            return RedirectToAction(nameof(Metadata));
        }

        _context.Publishers.Add(new Publisher { PublisherName = trimmedName });
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Publisher '{trimmedName}' added successfully.";
        return RedirectToAction(nameof(Metadata));
    }

    // POST: /Admin/UpdatePublisher
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdatePublisher(short publisherId, string name)
    {
        var pub = await _context.Publishers.FindAsync(publisherId);
        if (pub == null)
        {
            TempData["ErrorMessage"] = "Publisher not found.";
            return RedirectToAction(nameof(Metadata));
        }

        if (string.IsNullOrWhiteSpace(name))
        {
            TempData["ErrorMessage"] = "Publisher name cannot be empty.";
            return RedirectToAction(nameof(Metadata));
        }

        string trimmedName = name.Trim();
        if (trimmedName.Length > 30)
        {
            TempData["ErrorMessage"] = "Publisher name cannot exceed 30 characters.";
            return RedirectToAction(nameof(Metadata));
        }

        bool duplicate = await _context.Publishers.AnyAsync(p => p.PublisherId != publisherId && p.PublisherName.ToLower() == trimmedName.ToLower());
        if (duplicate)
        {
            TempData["ErrorMessage"] = $"Another publisher with the name '{trimmedName}' already exists.";
            return RedirectToAction(nameof(Metadata));
        }

        pub.PublisherName = trimmedName;
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Publisher '{trimmedName}' updated successfully.";
        return RedirectToAction(nameof(Metadata));
    }

    // POST: /Admin/DeletePublisher
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeletePublisher(short publisherId)
    {
        var pub = await _context.Publishers.Include(p => p.AssociateBookPublishers).FirstOrDefaultAsync(p => p.PublisherId == publisherId);
        if (pub == null)
        {
            TempData["ErrorMessage"] = "Publisher not found.";
            return RedirectToAction(nameof(Metadata));
        }

        if (pub.AssociateBookPublishers.Any())
        {
            TempData["ErrorMessage"] = $"Cannot delete '{pub.PublisherName}' because it is linked to {pub.AssociateBookPublishers.Count} book title(s).";
            return RedirectToAction(nameof(Metadata));
        }

        _context.Publishers.Remove(pub);
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Publisher '{pub.PublisherName}' deleted successfully.";
        return RedirectToAction(nameof(Metadata));
    }

    // POST: /Admin/AddCategory
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddCategory(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            TempData["ErrorMessage"] = "Category name cannot be empty.";
            return RedirectToAction(nameof(Metadata));
        }

        string trimmedName = name.Trim();
        if (trimmedName.Length > 30)
        {
            TempData["ErrorMessage"] = "Category name cannot exceed 30 characters.";
            return RedirectToAction(nameof(Metadata));
        }

        bool exists = await _context.Categories.AnyAsync(c => c.CategoryName.ToLower() == trimmedName.ToLower());
        if (exists)
        {
            TempData["ErrorMessage"] = $"Category '{trimmedName}' already exists.";
            return RedirectToAction(nameof(Metadata));
        }

        _context.Categories.Add(new Category { CategoryName = trimmedName });
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Category '{trimmedName}' added successfully.";
        return RedirectToAction(nameof(Metadata));
    }

    // POST: /Admin/UpdateCategory
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateCategory(short categoryId, string name)
    {
        var cat = await _context.Categories.FindAsync(categoryId);
        if (cat == null)
        {
            TempData["ErrorMessage"] = "Category not found.";
            return RedirectToAction(nameof(Metadata));
        }

        if (string.IsNullOrWhiteSpace(name))
        {
            TempData["ErrorMessage"] = "Category name cannot be empty.";
            return RedirectToAction(nameof(Metadata));
        }

        string trimmedName = name.Trim();
        if (trimmedName.Length > 30)
        {
            TempData["ErrorMessage"] = "Category name cannot exceed 30 characters.";
            return RedirectToAction(nameof(Metadata));
        }

        bool duplicate = await _context.Categories.AnyAsync(c => c.CategoryId != categoryId && c.CategoryName.ToLower() == trimmedName.ToLower());
        if (duplicate)
        {
            TempData["ErrorMessage"] = $"Another category with the name '{trimmedName}' already exists.";
            return RedirectToAction(nameof(Metadata));
        }

        cat.CategoryName = trimmedName;
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Category '{trimmedName}' updated successfully.";
        return RedirectToAction(nameof(Metadata));
    }

    // POST: /Admin/DeleteCategory
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteCategory(short categoryId)
    {
        var cat = await _context.Categories.Include(c => c.AssociateBookCategories).FirstOrDefaultAsync(c => c.CategoryId == categoryId);
        if (cat == null)
        {
            TempData["ErrorMessage"] = "Category not found.";
            return RedirectToAction(nameof(Metadata));
        }

        if (cat.AssociateBookCategories.Any())
        {
            TempData["ErrorMessage"] = $"Cannot delete '{cat.CategoryName}' because it is linked to {cat.AssociateBookCategories.Count} book title(s).";
            return RedirectToAction(nameof(Metadata));
        }

        _context.Categories.Remove(cat);
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Category '{cat.CategoryName}' deleted successfully.";
        return RedirectToAction(nameof(Metadata));
    }
}
