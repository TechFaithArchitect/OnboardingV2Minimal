public class RecipientGroupEmailService {
  /**
   * Consolidates RecipientGroupEmailOrchestrator logic - removed orchestrator layer
   */
  public static List<String> getEmailsForVendorProgram(Id vendorProgramId) {
    return RecipientGroupUtil.getEmailsFromVendorProgram(vendorProgramId);
  }

  /**
   * Alias method for backward compatibility (was RecipientGroupEmailOrchestrator.getEmails)
   */
  public static List<String> getEmails(Id vendorProgramId) {
    return getEmailsForVendorProgram(vendorProgramId);
  }
}
