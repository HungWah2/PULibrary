using Microsoft.EntityFrameworkCore;
using PULibrary.Models;

namespace PULibrary.Data;

public class LibraryDbContext : DbContext
{
    public LibraryDbContext(DbContextOptions<LibraryDbContext> options) : base(options)
    {
    }

    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Policy> Policies => Set<Policy>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Author> Authors => Set<Author>();
    public DbSet<Publisher> Publishers => Set<Publisher>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Book> Books => Set<Book>();
    public DbSet<AssociateBookAuthor> AssociateBookAuthors => Set<AssociateBookAuthor>();
    public DbSet<AssociateBookPublisher> AssociateBookPublishers => Set<AssociateBookPublisher>();
    public DbSet<AssociateBookCategory> AssociateBookCategories => Set<AssociateBookCategory>();
    public DbSet<BookCopy> BookCopies => Set<BookCopy>();
    public DbSet<Loan> Loans => Set<Loan>();
    public DbSet<Reservation> Reservations => Set<Reservation>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Role
        modelBuilder.Entity<Role>(entity =>
        {
            entity.ToTable("Role");
            entity.HasKey(e => e.RoleId);
            entity.Property(e => e.RoleId).HasColumnName("role_id");
            entity.Property(e => e.RoleName).HasColumnName("role_name").HasMaxLength(50).IsRequired();

            entity.HasOne(e => e.Policy)
                  .WithOne(p => p.Role)
                  .HasForeignKey<Policy>(p => p.RoleId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // Policy
        modelBuilder.Entity<Policy>(entity =>
        {
            entity.ToTable("Policy");
            entity.HasKey(e => e.PolicyId);
            entity.Property(e => e.PolicyId).HasColumnName("policy_id");
            entity.Property(e => e.RoleId).HasColumnName("role_id");
            entity.Property(e => e.LoanDays).HasColumnName("loan_days");
            entity.Property(e => e.MaxLoans).HasColumnName("max_loans");
            entity.Property(e => e.MaxRenewals).HasColumnName("max_renewals");
        });

        // User
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("User");
            entity.HasKey(e => e.UserId);
            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.Username).HasColumnName("username").HasMaxLength(20).IsRequired();
            entity.Property(e => e.PasswordHash).HasColumnName("password_hash").HasMaxLength(255).IsRequired();
            entity.Property(e => e.Name).HasColumnName("name").HasMaxLength(30).IsRequired();
            entity.Property(e => e.Phone).HasColumnName("phone").HasMaxLength(10).IsFixedLength().IsRequired();
            entity.Property(e => e.Email).HasColumnName("email").HasMaxLength(100).IsRequired();
            entity.Property(e => e.CreatedAt).HasColumnName("created_at");
            entity.Property(e => e.UpdatedAt).HasColumnName("updated_at");
            entity.Property(e => e.Status).HasColumnName("status").HasMaxLength(20).IsRequired();
            entity.Property(e => e.RoleId).HasColumnName("role_id");

            entity.HasOne(e => e.Role)
                  .WithMany(r => r.Users)
                  .HasForeignKey(e => e.RoleId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // Author
        modelBuilder.Entity<Author>(entity =>
        {
            entity.ToTable("Author");
            entity.HasKey(e => e.AuthorId);
            entity.Property(e => e.AuthorId).HasColumnName("author_id");
            entity.Property(e => e.AuthorName).HasColumnName("author_name").HasMaxLength(30).IsRequired();
        });

        // Publisher
        modelBuilder.Entity<Publisher>(entity =>
        {
            entity.ToTable("Publisher");
            entity.HasKey(e => e.PublisherId);
            entity.Property(e => e.PublisherId).HasColumnName("publisher_id");
            entity.Property(e => e.PublisherName).HasColumnName("publisher_name").HasMaxLength(30).IsRequired();
        });

        // Category
        modelBuilder.Entity<Category>(entity =>
        {
            entity.ToTable("Category");
            entity.HasKey(e => e.CategoryId);
            entity.Property(e => e.CategoryId).HasColumnName("category_id");
            entity.Property(e => e.CategoryName).HasColumnName("category_name").HasMaxLength(30).IsRequired();
        });

        // Book
        modelBuilder.Entity<Book>(entity =>
        {
            entity.ToTable("Book");
            entity.HasKey(e => e.BookId);
            entity.Property(e => e.BookId).HasColumnName("book_id");
            entity.Property(e => e.Isbn).HasColumnName("isbn").HasMaxLength(13).IsFixedLength();
            entity.Property(e => e.Title).HasColumnName("title").HasMaxLength(50).IsRequired();
            entity.Property(e => e.Language).HasColumnName("language").HasMaxLength(20).IsRequired();
            entity.Property(e => e.Edition).HasColumnName("edition");
            entity.Property(e => e.CoverImage).HasColumnName("cover_image").HasMaxLength(255);
            entity.Property(e => e.PublishedDate).HasColumnName("published_date");
            entity.Property(e => e.Description).HasColumnName("description");
        });

        // Associate_Book_Author
        modelBuilder.Entity<AssociateBookAuthor>(entity =>
        {
            entity.ToTable("Associate_Book_Author");
            entity.HasKey(e => new { e.AuthorId, e.BookId });
            entity.Property(e => e.AuthorId).HasColumnName("author_id");
            entity.Property(e => e.BookId).HasColumnName("book_id");

            entity.HasOne(e => e.Author)
                  .WithMany(a => a.AssociateBookAuthors)
                  .HasForeignKey(e => e.AuthorId);

            entity.HasOne(e => e.Book)
                  .WithMany(b => b.AssociateBookAuthors)
                  .HasForeignKey(e => e.BookId);
        });

        // Associate_Book_Publisher
        modelBuilder.Entity<AssociateBookPublisher>(entity =>
        {
            entity.ToTable("Associate_Book_Publisher");
            entity.HasKey(e => new { e.PublisherId, e.BookId });
            entity.Property(e => e.PublisherId).HasColumnName("publisher_id");
            entity.Property(e => e.BookId).HasColumnName("book_id");

            entity.HasOne(e => e.Publisher)
                  .WithMany(p => p.AssociateBookPublishers)
                  .HasForeignKey(e => e.PublisherId);

            entity.HasOne(e => e.Book)
                  .WithMany(b => b.AssociateBookPublishers)
                  .HasForeignKey(e => e.BookId);
        });

        // Associate_Book_Category
        modelBuilder.Entity<AssociateBookCategory>(entity =>
        {
            entity.ToTable("Associate_Book_Category");
            entity.HasKey(e => new { e.CategoryId, e.BookId });
            entity.Property(e => e.CategoryId).HasColumnName("category_id");
            entity.Property(e => e.BookId).HasColumnName("book_id");

            entity.HasOne(e => e.Category)
                  .WithMany(c => c.AssociateBookCategories)
                  .HasForeignKey(e => e.CategoryId);

            entity.HasOne(e => e.Book)
                  .WithMany(b => b.AssociateBookCategories)
                  .HasForeignKey(e => e.BookId);
        });

        // BookCopy
        modelBuilder.Entity<BookCopy>(entity =>
        {
            entity.ToTable("BookCopy");
            entity.HasKey(e => e.CopyId);
            entity.Property(e => e.CopyId).HasColumnName("copy_id");
            entity.Property(e => e.BookId).HasColumnName("book_id");
            entity.Property(e => e.ShelfLocation).HasColumnName("shelf_location").HasMaxLength(255).IsRequired();
            entity.Property(e => e.CopyCondition).HasColumnName("copy_condition").HasMaxLength(20).IsRequired();
            entity.Property(e => e.Status).HasColumnName("status").HasMaxLength(20).IsRequired();

            entity.HasOne(e => e.Book)
                  .WithMany(b => b.Copies)
                  .HasForeignKey(e => e.BookId);
        });

        // Loan
        modelBuilder.Entity<Loan>(entity =>
        {
            entity.ToTable("Loan");
            entity.HasKey(e => e.LoanId);
            entity.Property(e => e.LoanId).HasColumnName("loan_id");
            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.CopyId).HasColumnName("copy_id");
            entity.Property(e => e.RenewalCount).HasColumnName("renewal_count");
            entity.Property(e => e.BorrowedAt).HasColumnName("borrowed_at");
            entity.Property(e => e.ReturnedAt).HasColumnName("returned_at");
            entity.Property(e => e.DueAt).HasColumnName("due_at");
            entity.Property(e => e.ProcessedBy).HasColumnName("processed_by");

            entity.HasOne(e => e.User)
                  .WithMany(u => u.Loans)
                  .HasForeignKey(e => e.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Copy)
                  .WithMany(c => c.Loans)
                  .HasForeignKey(e => e.CopyId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.ProcessedByUser)
                  .WithMany(u => u.ProcessedLoans)
                  .HasForeignKey(e => e.ProcessedBy)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // Reservation
        modelBuilder.Entity<Reservation>(entity =>
        {
            entity.ToTable("Reservation");
            entity.HasKey(e => e.ReservationId);
            entity.Property(e => e.ReservationId).HasColumnName("reservation_id");
            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.BookId).HasColumnName("book_id");
            entity.Property(e => e.FulfilledCopyId).HasColumnName("fulfilled_copy_id");
            entity.Property(e => e.ReservedAt).HasColumnName("reserved_at");
            entity.Property(e => e.Status).HasColumnName("status").HasMaxLength(20).IsRequired();

            entity.HasOne(e => e.User)
                  .WithMany(u => u.Reservations)
                  .HasForeignKey(e => e.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Book)
                  .WithMany(b => b.Reservations)
                  .HasForeignKey(e => e.BookId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.FulfilledCopy)
                  .WithMany(c => c.FulfilledReservations)
                  .HasForeignKey(e => e.FulfilledCopyId)
                  .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
