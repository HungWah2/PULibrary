using Microsoft.AspNetCore.Mvc;

namespace PULibrary.Controllers;

public class HomeController : Controller
{
    public IActionResult Index()
    {
        int roleId = HttpContext.Session.GetInt32("RoleId") ?? 0;
        if (roleId >= 3)
        {
            return RedirectToAction("Dashboard", "Admin");
        }
        return RedirectToAction("Index", "Catalog");
    }

    public IActionResult Privacy()
    {
        return View();
    }
}
