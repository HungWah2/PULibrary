using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using PULibrary.Models;

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

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View("~/Views/Shared/Error.cshtml", new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
