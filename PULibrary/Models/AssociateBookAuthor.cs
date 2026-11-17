namespace PULibrary.Models;

public class AssociateBookAuthor
{
    public short AuthorId { get; set; }
    public int BookId { get; set; }

    public Author? Author { get; set; }
    public Book? Book { get; set; }
}
