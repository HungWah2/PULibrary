using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PULibrary.Data;
using PULibrary.Models;
using PULibrary.Services;

namespace PULibrary.Controllers;

public class AccountController : Controller
{
    private readonly LibraryDbContext _context;
    private readonly IWebHostEnvironment _env;

    public AccountController(LibraryDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    // GET: /Account/SignIn
    [HttpGet]
    public async Task<IActionResult> SignIn(string? returnUrl)
    {
        ViewBag.ReturnUrl = returnUrl;
        ViewBag.IsDevelopment = _env.IsDevelopment();

        if (_env.IsDevelopment())
        {
            ViewBag.QuickUsers = await _context.Users.Include(u => u.Role).ToListAsync();
        }
        else
        {
            ViewBag.QuickUsers = new List<User>();
        }

        return View();
    }

    // POST: /Account/SignIn
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SignIn(string username, string password, string? returnUrl)
    {
        ViewBag.ReturnUrl = returnUrl;
        ViewBag.IsDevelopment = _env.IsDevelopment();

        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
        {
            ModelState.AddModelError("", "Please enter both username and password.");
            await PopulateQuickUsersIfDevelopment();
            return View();
        }

        var normalizedUsername = username.Trim().ToLower();
        var user = await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username.ToLower() == normalizedUsername);

        // Security check 1: Check account existence & Active status
        if (user == null || user.Status != "Active")
        {
            ModelState.AddModelError("", "We couldn’t sign you in. Check your username and password, then try again.");
            await PopulateQuickUsersIfDevelopment();
            return View();
        }

        // Security check 2: Verify password using BCrypt (or legacy compatibility)
        if (!PasswordHelper.VerifyPassword(password, user.PasswordHash, out bool needsRehash))
        {
            ModelState.AddModelError("", "We couldn’t sign you in. Check your username and password, then try again.");
            await PopulateQuickUsersIfDevelopment();
            return View();
        }

        // Seamless transparent migration: if legacy password was verified, upgrade to secure BCrypt hash
        if (needsRehash)
        {
            user.PasswordHash = PasswordHelper.HashPassword(password);
            var now = DateTime.Now;
            user.UpdatedAt = now > user.CreatedAt ? now : user.CreatedAt.AddSeconds(1);
            await _context.SaveChangesAsync();
        }

        // Establish secure session
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
    public IActionResult Register()
    {
        return View();
    }

    // POST: /Account/Register
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(string name, string username, string email, string phone, string password, string confirmPassword)
    {
        // 1. Validate required fields
        if (string.IsNullOrWhiteSpace(name))
        {
            ModelState.AddModelError("name", "Full name is required.");
        }
        else if (name.Trim().Length > 30)
        {
            ModelState.AddModelError("name", "Full name cannot exceed 30 characters.");
        }

        // 2. Validate username
        string normalizedUsername = "";
        if (string.IsNullOrWhiteSpace(username))
        {
            ModelState.AddModelError("username", "Username is required.");
        }
        else
        {
            normalizedUsername = username.Trim().ToLower();
            if (normalizedUsername.Length < 3 || normalizedUsername.Length > 20)
            {
                ModelState.AddModelError("username", "Username must be between 3 and 20 characters.");
            }
            else if (!Regex.IsMatch(normalizedUsername, @"^[a-z0-9_.-]+$"))
            {
                ModelState.AddModelError("username", "Username can only contain letters, numbers, dots, hyphens, and underscores.");
            }
            else
            {
                var exists = await _context.Users.AnyAsync(u => u.Username.ToLower() == normalizedUsername);
                if (exists)
                {
                    ModelState.AddModelError("username", $"The username '{username.Trim()}' is already taken. Please choose another.");
                }
            }
        }

        // 3. Validate email
        var cleanEmail = (email ?? "").Trim();
        if (string.IsNullOrWhiteSpace(cleanEmail))
        {
            ModelState.AddModelError("email", "Email address is required.");
        }
        else if (cleanEmail.Length > 100)
        {
            ModelState.AddModelError("email", "Email address cannot exceed 100 characters.");
        }
        else if (!new EmailAddressAttribute().IsValid(cleanEmail))
        {
            ModelState.AddModelError("email", "Please provide a valid email address (e.g. reader@example.com).");
        }

        // 4. Validate phone number (must be exact 10 digits as required by database schema)
        var phoneDigits = new string((phone ?? "").Where(char.IsDigit).ToArray());
        if (string.IsNullOrWhiteSpace(phone) || phoneDigits.Length != 10)
        {
            ModelState.AddModelError("phone", "Phone number must be exactly 10 digits (e.g. 0912345678).");
        }

        // 5. Validate password
        if (string.IsNullOrWhiteSpace(password))
        {
            ModelState.AddModelError("password", "Password is required.");
        }
        else if (password.Length < 6)
        {
            ModelState.AddModelError("password", "Password must be at least 6 characters long.");
        }
        else if (password != confirmPassword)
        {
            ModelState.AddModelError("confirmPassword", "Passwords do not match. Please verify and try again.");
        }

        if (!ModelState.IsValid)
        {
            return View();
        }

        // Security check: newly registered users are ALWAYS assigned RoleId = 1 (Member / Reader).
        // Higher privileges (Researcher, Librarian, Admin) must be granted by administrators in the portal.
        const short standardMemberRoleId = 1;

        var newUser = new User
        {
            Username = normalizedUsername,
            PasswordHash = PasswordHelper.HashPassword(password),
            Name = name.Trim(),
            Phone = phoneDigits,
            Email = cleanEmail,
            Status = "Active",
            RoleId = standardMemberRoleId,
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

    // Quick switch session for testing convenience - STRICTLY LIMITED TO DEVELOPMENT ENVIRONMENT
    [HttpGet]
    public async Task<IActionResult> QuickSwitch(int id, string? returnUrl)
    {
        // Block quick switch entirely in production / staging
        if (!_env.IsDevelopment())
        {
            return NotFound();
        }

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

    // POST: /Account/SignOut (Secured with CSRF)
    [HttpPost]
    [ValidateAntiForgeryToken]
    public new IActionResult SignOut()
    {
        HttpContext.Session.Clear();
        return RedirectToAction(nameof(SignIn));
    }

    // GET: /Account/SignOut or /Account/Logout fallback
    [HttpGet]
    public IActionResult Logout()
    {
        HttpContext.Session.Clear();
        return RedirectToAction(nameof(SignIn));
    }

    private async Task PopulateQuickUsersIfDevelopment()
    {
        if (_env.IsDevelopment())
        {
            ViewBag.QuickUsers = await _context.Users.Include(u => u.Role).ToListAsync();
        }
        else
        {
            ViewBag.QuickUsers = new List<User>();
        }
    }
}
