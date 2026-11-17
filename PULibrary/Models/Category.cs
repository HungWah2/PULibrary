namespace PULibrary.Models;

public class Category
{
    public short CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;

    public ICollection<AssociateBookCategory> AssociateBookCategories { get; set; } = new List<AssociateBookCategory>();
}
