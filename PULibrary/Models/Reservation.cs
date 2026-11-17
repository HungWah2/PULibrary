namespace PULibrary.Models;

public class Reservation
{
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public int BookId { get; set; }
    public int? FulfilledCopyId { get; set; }
    public DateTime ReservedAt { get; set; }
    public string Status { get; set; } = "PENDING"; // PENDING, READY, FULFILLED, CANCELLED, REJECTED

    public User? User { get; set; }
    public Book? Book { get; set; }
    public BookCopy? FulfilledCopy { get; set; }
}
