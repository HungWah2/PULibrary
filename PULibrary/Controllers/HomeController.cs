using Microsoft.AspNetCore.Mvc;

namespace PULibrary.Controllers;

public class HomeController : Controller
{
    public IActionResult Index()
    {
        return RedirectToAction("Index", "Catalog");
    }

    public IActionResult Privacy()
    {
        return View();
    }
}
