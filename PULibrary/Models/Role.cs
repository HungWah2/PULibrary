namespace PULibrary.Models;

public class Role
{
    public short RoleId { get; set; }
    public string RoleName { get; set; } = string.Empty;

    public Policy? Policy { get; set; }
    public ICollection<User> Users { get; set; } = new List<User>();
}
