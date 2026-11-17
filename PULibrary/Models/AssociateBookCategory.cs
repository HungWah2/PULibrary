namespace PULibrary.Models;

public class AssociateBookCategory
{
    public short CategoryId { get; set; }
    public int BookId { get; set; }

    public Category? Category { get; set; }
    public Book? Book { get; set; }
}
