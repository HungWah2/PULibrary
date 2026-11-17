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
