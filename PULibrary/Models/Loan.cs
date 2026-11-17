namespace PULibrary.Models;

public class Loan
{
    public int LoanId { get; set; }
    public int UserId { get; set; }
    public int CopyId { get; set; }
    public short RenewalCount { get; set; } = 0;
    public DateTime BorrowedAt { get; set; }
    public DateTime? ReturnedAt { get; set; }
    public DateTime DueAt { get; set; }
    public int? ProcessedBy { get; set; }

    public User? User { get; set; }
    public BookCopy? Copy { get; set; }
    public User? ProcessedByUser { get; set; }

    public bool IsActive => ReturnedAt == null;
    public bool IsOverdue => ReturnedAt == null && DueAt < DateTime.Now;
}
