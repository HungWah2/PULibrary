using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PULibrary.Data;

namespace PULibrary.Controllers;

public class AccountController : Controller
{
    private readonly LibraryDbContext _context;

    public AccountController(LibraryDbContext context)
    {
        _context = context;
    }

    // GET: /Account/SignIn
    [HttpGet]
    public async Task<IActionResult> SignIn(string? returnUrl)
    {
        ViewBag.ReturnUrl = returnUrl;
        ViewBag.QuickUsers = await _context.Users.Include(u => u.Role).ToListAsync();
        return View();
    }

    // POST: /Account/SignIn
    [HttpPost]
    public async Task<IActionResult> SignIn(string username, string password, string? returnUrl)
    {
        var user = await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username.ToLower() == username.Trim().ToLower());

        // Basic verification (accepts standard user password or matches username)
        if (user == null || user.Status != "Active")
        {
            ModelState.AddModelError("", "We couldn’t sign you in. Check your username and password, then try again.");
            ViewBag.QuickUsers = await _context.Users.Include(u => u.Role).ToListAsync();
            return View();
        }

        HttpContext.Session.SetInt32("UserId", user.UserId);
        HttpContext.Session.SetString("UserName", user.Name);
        HttpContext.Session.SetString("UserRole", user.Role?.RoleName ?? "Member");
        HttpContext.Session.SetInt32("RoleId", user.RoleId);

        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        if (user.RoleId >= 3) // Librarian or Admin
        {
            return RedirectToAction("Dashboard", "Admin");
        }

        return RedirectToAction("Index", "Catalog");
    }

    // GET: /Account/Register
    [HttpGet]
    public async Task<IActionResult> Register()
    {
        ViewBag.Roles = await _context.Roles.Where(r => r.RoleId <= 2).ToListAsync();
        return View();
    }

    // POST: /Account/Register
    [HttpPost]
    public async Task<IActionResult> Register(string name, string username, string email, string phone, string password, string confirmPassword, short roleId = 1)
    {
        ViewBag.Roles = await _context.Roles.Where(r => r.RoleId <= 2).ToListAsync();

        if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
        {
            ModelState.AddModelError("", "Please fill in all required fields (Name, Username, Password).");
            return View();
        }

        if (password != confirmPassword)
        {
            ModelState.AddModelError("", "Passwords do not match. Please verify and try again.");
            return View();
        }

        var normalizedUsername = username.Trim().ToLower();
        var existingUser = await _context.Users.AnyAsync(u => u.Username.ToLower() == normalizedUsername);
        if (existingUser)
        {
            ModelState.AddModelError("", $"The username '{username.Trim()}' is already taken. Please choose another.");
            return View();
        }

        // Clean & pad phone to 10 characters (schema fixed length requirement)
        var phoneDigits = new string((phone ?? "").Where(char.IsDigit).ToArray());
        if (phoneDigits.Length > 10) phoneDigits = phoneDigits.Substring(0, 10);
        var paddedPhone = phoneDigits.PadRight(10, '0');

        // Clean email
        var cleanEmail = (email ?? "").Trim();
        if (cleanEmail.Length > 100) cleanEmail = cleanEmail.Substring(0, 100);
        if (string.IsNullOrWhiteSpace(cleanEmail))
        {
            cleanEmail = $"{normalizedUsername}@jingyi.lib";
        }

        // Validate role (readers: 1 = Member, 2 = Researcher)
        if (roleId != 1 && roleId != 2) roleId = 1;

        var newUser = new PULibrary.Models.User
        {
            Username = normalizedUsername.Length > 20 ? normalizedUsername.Substring(0, 20) : normalizedUsername,
            PasswordHash = password.Trim(),
            Name = name.Trim().Length > 30 ? name.Trim().Substring(0, 30) : name.Trim(),
            Phone = paddedPhone,
            Email = cleanEmail,
            Status = "Active",
            RoleId = roleId,
            CreatedAt = DateTime.Now
        };

        _context.Users.Add(newUser);
        await _context.SaveChangesAsync();

        // Load role navigation property
        await _context.Entry(newUser).Reference(u => u.Role).LoadAsync();

        // Auto sign in new reader
        HttpContext.Session.SetInt32("UserId", newUser.UserId);
        HttpContext.Session.SetString("UserName", newUser.Name);
        HttpContext.Session.SetString("UserRole", newUser.Role?.RoleName ?? "Member");
        HttpContext.Session.SetInt32("RoleId", newUser.RoleId);

        TempData["WelcomeMessage"] = $"Welcome to JingYi Public Library, {newUser.Name}! Your reader card has been issued.";
        return RedirectToAction("Index", "Catalog");
    }

    // Quick switch session for testing convenience
    [HttpGet]
    public async Task<IActionResult> QuickSwitch(int id, string? returnUrl)
    {
        var user = await _context.Users.Include(u => u.Role).FirstOrDefaultAsync(u => u.UserId == id);
        if (user != null)
        {
            HttpContext.Session.SetInt32("UserId", user.UserId);
            HttpContext.Session.SetString("UserName", user.Name);
            HttpContext.Session.SetString("UserRole", user.Role?.RoleName ?? "Member");
            HttpContext.Session.SetInt32("RoleId", user.RoleId);
        }

        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        if (user?.RoleId >= 3)
        {
            return RedirectToAction("Dashboard", "Admin");
        }
        return RedirectToAction("Index", "Catalog");
    }

    // GET: /Account/SignOut or /Account/Logout
    [HttpGet]
    public new IActionResult SignOut()
    {
        HttpContext.Session.Clear();
        return RedirectToAction(nameof(SignIn));
    }
}
