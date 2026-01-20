public with sharing class OrgWideEmailAddressRepository {
    
    /**
     * Fetches all OrgWideEmailAddress records.
     * @return List of OrgWideEmailAddress records with Id, Address, DisplayName, and IsAllowAllProfiles
     */
    public static List<OrgWideEmailAddress> getAll() {
        return [
            SELECT Id, Address, DisplayName, IsAllowAllProfiles 
            FROM OrgWideEmailAddress
        ];
    }
}