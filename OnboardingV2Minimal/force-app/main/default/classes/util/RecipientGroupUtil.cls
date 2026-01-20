public with sharing class RecipientGroupUtil {
    public static List<String> getEmailsFromVendorProgram(Id vendorProgramId) {
        if (vendorProgramId == null) {
            return new List<String>();
        }

        List<User> users = RecipientGroupResolver.resolveUsersForVendorProgram(vendorProgramId);

        List<String> emails = new List<String>();
        for (User u : users) {
            if (String.isNotBlank(u.Email)) {
                emails.add(u.Email);
            }
        }

        return emails;
    }
}