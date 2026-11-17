namespace PULibrary.Models;

public class Book
{
    public int BookId { get; set; }
    public string? Isbn { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Language { get; set; } = "English"; // Chinese, English
    public short Edition { get; set; } = 1;
    public string? CoverImage { get; set; }
    public DateTime? PublishedDate { get; set; }
    public string? Description { get; set; }

    public ICollection<AssociateBookAuthor> AssociateBookAuthors { get; set; } = new List<AssociateBookAuthor>();
    public ICollection<AssociateBookPublisher> AssociateBookPublishers { get; set; } = new List<AssociateBookPublisher>();
    public ICollection<AssociateBookCategory> AssociateBookCategories { get; set; } = new List<AssociateBookCategory>();
    public ICollection<BookCopy> Copies { get; set; } = new List<BookCopy>();
    public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
}
