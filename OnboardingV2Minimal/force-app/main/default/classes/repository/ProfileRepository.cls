/**
 * Repository for Profile queries
 * Handles all data access operations related to User Profiles
 */
public with sharing class ProfileRepository {
    
    /**
     * Gets the profile name by profile ID
     * @param profileId The profile ID
     * @return Profile name, or empty string if not found
     */
    public static String getProfileNameById(Id profileId) {
        if (profileId == null) {
            return '';
        }
        
        List<Profile> profiles = [
            SELECT Name 
            FROM Profile 
            WHERE Id = :profileId 
            LIMIT 1
        ];
        
        return profiles.isEmpty() ? '' : profiles[0].Name;
    }
}