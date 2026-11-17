namespace PULibrary.Models;

public class Publisher
{
    public short PublisherId { get; set; }
    public string PublisherName { get; set; } = string.Empty;

    public ICollection<AssociateBookPublisher> AssociateBookPublishers { get; set; } = new List<AssociateBookPublisher>();
}
