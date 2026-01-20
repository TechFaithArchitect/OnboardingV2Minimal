public class RecipientGroupEmailAction {
  @InvocableMethod(label='Get Emails from Vendor Program Recipient Group')
  public static List<RecipientGroupEmailResultDTO> fetchEmails(
    List<RecipientGroupEmailRequestDTO> requests
  ) {
    List<RecipientGroupEmailResultDTO> emailResultDTOList = new List<RecipientGroupEmailResultDTO>();

    for (RecipientGroupEmailRequestDTO emailRequest : requests) {
      List<String> emails = RecipientGroupEmailService.getEmails(
        emailRequest.vendorProgramId
      );
      emailResultDTOList.add(new RecipientGroupEmailResultDTO(emails));
    }

    return emailResultDTOList;
  }
}
