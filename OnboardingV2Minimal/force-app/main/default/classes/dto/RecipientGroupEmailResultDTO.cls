public class RecipientGroupEmailResultDTO {
    @InvocableVariable(label='Email Addresses')
    public List<String> emailAddresses;

    public RecipientGroupEmailResultDTO(List<String> emails) {
        this.emailAddresses = emails;
    }
}