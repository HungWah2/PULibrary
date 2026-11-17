namespace PULibrary.Models;

public class BookCopy
{
    public int CopyId { get; set; }
    public int BookId { get; set; }
    public string ShelfLocation { get; set; } = string.Empty;
    public string CopyCondition { get; set; } = "Good"; // Good, Fair, Poor, Damaged
    public string Status { get; set; } = "Available";   // Available, Borrowed, Reserved

    public Book? Book { get; set; }
    public ICollection<Loan> Loans { get; set; } = new List<Loan>();
    public ICollection<Reservation> FulfilledReservations { get; set; } = new List<Reservation>();
}
