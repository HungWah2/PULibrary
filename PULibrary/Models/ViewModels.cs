namespace PULibrary.Models;

public class AdminDashboardViewModel
{
    public int ActiveLoansCount { get; set; }
    public int OverdueLoansCount { get; set; }
    public int AwaitingFulfillmentCount { get; set; }
    public int CopiesInRepairCount { get; set; }
    public int AvailableCopiesCount { get; set; }
    public int TotalCopiesCount { get; set; }
    public int TotalBooksCount { get; set; }

    public List<LoanItemViewModel> OverdueLoans { get; set; } = new();
    public List<LoanItemViewModel> ActiveLoans { get; set; } = new();
    public ReservationItemViewModel? PendingReservation { get; set; }
    public ReservationItemViewModel? FulfilledReservation { get; set; }
    public BookCopyItemViewModel? CopyInRepair { get; set; }
}

public class LoanItemViewModel
{
    public int LoanId { get; set; }
    public int UserId { get; set; }
    public string BorrowerName { get; set; } = string.Empty;
    public string BookTitle { get; set; } = string.Empty;
    public int CopyId { get; set; }
    public string ShelfLocation { get; set; } = string.Empty;
    public DateTime BorrowedAt { get; set; }
    public DateTime DueAt { get; set; }
    public short RenewalCount { get; set; }
    public bool IsOverdue { get; set; }
}

public class ReservationItemViewModel
{
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public string ReaderName { get; set; } = string.Empty;
    public int BookId { get; set; }
    public string BookTitle { get; set; } = string.Empty;
    public int? FulfilledCopyId { get; set; }
    public DateTime ReservedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public int? SuggestedAvailableCopyId { get; set; }
}

public class BookCopyItemViewModel
{
    public int CopyId { get; set; }
    public int BookId { get; set; }
    public string BookTitle { get; set; } = string.Empty;
    public string ShelfLocation { get; set; } = string.Empty;
    public string CopyCondition { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

public class BookCatalogViewModel
{
    public string? SearchQuery { get; set; }
    public string? SelectedCategory { get; set; }
    public string? SelectedLanguage { get; set; }
    public string? SelectedAvailability { get; set; }

    public List<BookCatalogItemViewModel> Books { get; set; } = new();
    public List<string> AllCategories { get; set; } = new();
    public List<string> AllLanguages { get; set; } = new();
    public int TotalBooksCount { get; set; }
    public int TotalPhysicalCopiesCount { get; set; }
}

public class BookCatalogItemViewModel
{
    public int BookId { get; set; }
    public string? Isbn { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Language { get; set; } = string.Empty;
    public short Edition { get; set; }
    public string? CoverImage { get; set; }
    public List<string> Authors { get; set; } = new();
    public List<string> Publishers { get; set; } = new();
    public List<string> Categories { get; set; } = new();
    public int TotalCopies { get; set; }
    public int AvailableCopies { get; set; }
}

public class CirculationDeskViewModel
{
    public List<User> ActiveUsers { get; set; } = new();
    public List<BookCopy> AvailableCopies { get; set; } = new();
    public List<Loan> ActiveLoans { get; set; } = new();
    public string? Message { get; set; }
    public string? Error { get; set; }
}
