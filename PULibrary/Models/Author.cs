namespace PULibrary.Models;

public class Author
{
    public short AuthorId { get; set; }
    public string AuthorName { get; set; } = string.Empty;

    public ICollection<AssociateBookAuthor> AssociateBookAuthors { get; set; } = new List<AssociateBookAuthor>();
}
