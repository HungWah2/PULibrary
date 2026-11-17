using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PULibrary.Data;

namespace PULibrary.Controllers;

public class UserController : Controller
{
    private readonly LibraryDbContext _context;

    public UserController(LibraryDbContext context)
    {
        _context = context;
    }

    // GET: /User
    public async Task<IActionResult> Index()
    {
        return await Profile(null);
    }

    // GET: /User/Profile or /User/Profile/2481 (Figma node 1:972)
    public async Task<IActionResult> Profile(int? id)
    {
        int targetUserId = id ?? HttpContext.Session.GetInt32("UserId") ?? 2481;

        var user = await _context.Users
            .Include(u => u.Role).ThenInclude(r => r!.Policy)
            .Include(u => u.Loans).ThenInclude(l => l.Copy).ThenInclude(c => c!.Book)
            .Include(u => u.Reservations).ThenInclude(r => r.Book)
            .Include(u => u.Reservations).ThenInclude(r => r.FulfilledCopy)
            .FirstOrDefaultAsync(u => u.UserId == targetUserId);

        if (user == null)
        {
            return NotFound();
        }

        ViewBag.ActiveLoans = user.Loans.Where(l => l.ReturnedAt == null).OrderBy(l => l.DueAt).ToList();
        ViewBag.ReturnedLoans = user.Loans.Where(l => l.ReturnedAt != null).OrderByDescending(l => l.ReturnedAt).ToList();
        ViewBag.Reservations = user.Reservations.OrderByDescending(r => r.ReservedAt).ToList();

        return View("Profile", user);
    }

    // POST: /User/Renew
    [HttpPost]
    public async Task<IActionResult> Renew(int loanId)
    {
        var loan = await _context.Loans
            .Include(l => l.User).ThenInclude(u => u!.Role).ThenInclude(r => r!.Policy)
            .FirstOrDefaultAsync(l => l.LoanId == loanId);

        if (loan == null)
        {
            TempData["ErrorMessage"] = "Loan not found.";
            return RedirectToAction(nameof(Profile));
        }

        var policy = loan.User?.Role?.Policy;
        var maxRenewals = policy?.MaxRenewals ?? 1;
        if (loan.RenewalCount >= maxRenewals)
        {
            TempData["ErrorMessage"] = $"Renewal limit of {maxRenewals} reached for your reader role.";
            return RedirectToAction(nameof(Profile), new { id = loan.UserId });
        }

        int extensionDays = policy?.LoanDays ?? 14;
        loan.RenewalCount++;
        loan.DueAt = loan.DueAt.AddDays(extensionDays);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Loan extended by {extensionDays} days! New due date is {loan.DueAt:dd MMM yyyy}.";
        return RedirectToAction(nameof(Profile), new { id = loan.UserId });
    }
}
