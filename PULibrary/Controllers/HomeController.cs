using Microsoft.AspNetCore.Mvc;

namespace PULibrary.Controllers;

public class HomeController : Controller
{
    public IActionResult Index()
    {
        return RedirectToAction("Dashboard", "Admin");
    }

    public IActionResult Privacy()
    {
        return View();
    }
}
