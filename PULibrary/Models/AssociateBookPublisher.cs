namespace PULibrary.Models;

public class AssociateBookPublisher
{
    public short PublisherId { get; set; }
    public int BookId { get; set; }

    public Publisher? Publisher { get; set; }
    public Book? Book { get; set; }
}
