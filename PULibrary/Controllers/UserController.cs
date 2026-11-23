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

    // GET: /User/Profile or /User/Profile/1001
    public async Task<IActionResult> Profile(int? id)
    {
        int targetUserId = id ?? HttpContext.Session.GetInt32("UserId") ?? 1001;

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

    // POST: /User/CancelReservation
    [HttpPost]
    public async Task<IActionResult> CancelReservation(int reservationId)
    {
        int currentUserId = HttpContext.Session.GetInt32("UserId") ?? 1001;
        var res = await _context.Reservations
            .Include(r => r.FulfilledCopy)
            .FirstOrDefaultAsync(r => r.ReservationId == reservationId && r.UserId == currentUserId);

        if (res != null)
        {
            if (res.FulfilledCopy != null)
            {
                res.FulfilledCopy.Status = "Available";
            }
            res.Status = "CANCELLED";
            await _context.SaveChangesAsync();
            TempData["SuccessMessage"] = $"Reservation #{reservationId} has been cancelled.";
        }

        return RedirectToAction(nameof(Profile), new { id = currentUserId });
    }

    // POST: /User/UpdateProfile
    [HttpPost]
    public async Task<IActionResult> UpdateProfile(int? userId, string name, string? username, string email, string phone, string? newPassword)
    {
        int targetUserId = userId ?? HttpContext.Session.GetInt32("UserId") ?? 1001;
        var user = await _context.Users.Include(u => u.Role).FirstOrDefaultAsync(u => u.UserId == targetUserId);
        if (user == null)
        {
            TempData["ErrorMessage"] = "User account not found.";
            return RedirectToAction(nameof(Profile), new { id = targetUserId });
        }

        if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(email))
        {
            TempData["ErrorMessage"] = "Name and Email are required fields.";
            return RedirectToAction(nameof(Profile), new { id = targetUserId });
        }

        // Validate and update username if provided
        if (!string.IsNullOrWhiteSpace(username))
        {
            var cleanUsername = username.Trim().ToLower();
            if (cleanUsername.Length > 20) cleanUsername = cleanUsername.Substring(0, 20);

            var isTaken = await _context.Users.AnyAsync(u => u.UserId != targetUserId && u.Username.ToLower() == cleanUsername);
            if (isTaken)
            {
                TempData["ErrorMessage"] = $"The username '{cleanUsername}' is already taken by another account. Please choose a different username.";
                return RedirectToAction(nameof(Profile), new { id = targetUserId });
            }

            user.Username = cleanUsername;
        }

        user.Name = name.Trim().Length > 30 ? name.Trim().Substring(0, 30) : name.Trim();
        user.Email = email.Trim().Length > 100 ? email.Trim().Substring(0, 100) : email.Trim();

        if (!string.IsNullOrWhiteSpace(phone))
        {
            var digits = new string(phone.Where(char.IsDigit).ToArray());
            if (digits.Length > 10) digits = digits.Substring(0, 10);
            user.Phone = digits.PadRight(10, '0');
        }

        if (!string.IsNullOrWhiteSpace(newPassword) && newPassword.Trim().Length >= 4)
        {
            user.PasswordHash = newPassword.Trim();
        }

        // Ensure updated_at > created_at for updated_after check constraint
        var now = DateTime.Now;
        user.UpdatedAt = now > user.CreatedAt ? now : user.CreatedAt.AddSeconds(1);
        await _context.SaveChangesAsync();

        // Update session identity so the UI updates immediately if this is the active user
        int? sessionUserId = HttpContext.Session.GetInt32("UserId");
        if (sessionUserId == null || sessionUserId == user.UserId)
        {
            HttpContext.Session.SetInt32("UserId", user.UserId);
            HttpContext.Session.SetString("UserName", user.Name);
            HttpContext.Session.SetString("UserRole", user.Role?.RoleName ?? "Member");
            HttpContext.Session.SetInt32("RoleId", user.RoleId);
        }

        TempData["SuccessMessage"] = "Your account profile and login username have been customized successfully!";
        return RedirectToAction(nameof(Profile), new { id = user.UserId });
    }
}
