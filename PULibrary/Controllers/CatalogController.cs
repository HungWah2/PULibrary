using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PULibrary.Data;
using PULibrary.Models;

namespace PULibrary.Controllers;

public class CatalogController : Controller
{
    private readonly LibraryDbContext _context;

    public CatalogController(LibraryDbContext context)
    {
        _context = context;
    }

    // GET: /Catalog or /Catalog/Index
    public async Task<IActionResult> Index(string? search, string? category, int page = 1, int pageSize = 9)
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
                                     b.AssociateBookAuthors.Any(a => a.Author!.AuthorName.ToLower().Contains(term)));
        }

        if (!string.IsNullOrWhiteSpace(category) && category != "All")
        {
            query = query.Where(b => b.AssociateBookCategories.Any(c => c.Category!.CategoryName == category));
        }

        query = query.OrderBy(b => b.Title);

        int totalCount = await query.CountAsync();
        int totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        page = Math.Max(1, Math.Min(page, totalPages > 0 ? totalPages : 1));

        var books = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        ViewBag.Search = search;
        ViewBag.Category = category;
        ViewBag.AllCategories = await _context.Categories.Select(c => c.CategoryName).Distinct().OrderBy(c => c).ToListAsync();
        ViewBag.CurrentPage = page;
        ViewBag.TotalPages = totalPages;
        ViewBag.TotalCount = totalCount;
        ViewBag.PageSize = pageSize;

        return View(books);
    }

    // GET: /Catalog/Detail/101 (Figma node 1:2628)
    public async Task<IActionResult> Detail(int id)
    {
        var book = await _context.Books
            .Include(b => b.AssociateBookAuthors).ThenInclude(aba => aba.Author)
            .Include(b => b.AssociateBookPublishers).ThenInclude(abp => abp.Publisher)
            .Include(b => b.AssociateBookCategories).ThenInclude(abc => abc.Category)
            .Include(b => b.Copies).ThenInclude(c => c.Loans)
            .FirstOrDefaultAsync(b => b.BookId == id);

        if (book == null)
        {
            return NotFound();
        }

        int currentUserId = HttpContext.Session.GetInt32("UserId") ?? 1001; // Default to Jamie Lee if anonymous
        ViewBag.CurrentUserId = currentUserId;

        return View(book);
    }

    // POST: /Catalog/Reserve
    [HttpPost]
    public async Task<IActionResult> Reserve(int bookId)
    {
        int currentUserId = HttpContext.Session.GetInt32("UserId") ?? 1001;

        var user = await _context.Users.FindAsync(currentUserId);
        if (user == null || user.Status != "Active")
        {
            TempData["ErrorMessage"] = "Reader account not found or suspended.";
            return RedirectToAction(nameof(Detail), new { id = bookId });
        }

        var existingPending = await _context.Reservations
            .FirstOrDefaultAsync(r => r.UserId == currentUserId && r.BookId == bookId && r.Status == "PENDING");

        if (existingPending != null)
        {
            TempData["ErrorMessage"] = "You already have an active hold queue reservation for this book!";
            return RedirectToAction(nameof(Detail), new { id = bookId });
        }

        var res = new Reservation
        {
            UserId = currentUserId,
            BookId = bookId,
            ReservedAt = DateTime.Now,
            Status = "PENDING"
        };

        _context.Reservations.Add(res);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = "Reservation confirmed! Your hold request has been placed in the queue.";
        return RedirectToAction(nameof(Detail), new { id = bookId });
    }
}
