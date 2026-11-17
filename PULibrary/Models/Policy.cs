namespace PULibrary.Models;

public class Policy
{
    public short PolicyId { get; set; }
    public short RoleId { get; set; }
    public short LoanDays { get; set; }
    public short MaxLoans { get; set; }
    public short MaxRenewals { get; set; }

    public Role? Role { get; set; }
}
