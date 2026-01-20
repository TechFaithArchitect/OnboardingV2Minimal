public with sharing class EmailAttachmentRepository {
    
    /**
     * Fetches legacy Attachment records by their IDs.
     * @param attachmentIds List of Attachment IDs
     * @return List of Attachment records with Name, Body, and ContentType
     */
    public static List<Attachment> getLegacyAttachments(List<Id> attachmentIds) {
        if (attachmentIds == null || attachmentIds.isEmpty()) {
            return new List<Attachment>();
        }
        return [
            SELECT Name, Body, ContentType 
            FROM Attachment 
            WHERE Id IN :attachmentIds
        ];
    }
    
    /**
     * Fetches ContentVersion records by ContentDocument IDs.
     * @param contentDocumentIds List of ContentDocument IDs
     * @return List of ContentVersion records with Title, VersionData, and FileExtension
     */
    public static List<ContentVersion> getContentVersions(List<Id> contentDocumentIds) {
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            return new List<ContentVersion>();
        }
        return [
            SELECT Title, VersionData, FileExtension 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds
        ];
    }
}