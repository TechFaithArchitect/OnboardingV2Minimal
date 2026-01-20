/**
 * Strategy interface for object-specific activation logic
 * Follows Open/Closed Principle - new object types can be added without modifying existing code
 */
public interface ActivationStrategy {
    /**
     * Activates a record of the specific object type
     * @param recordId The ID of the record to activate
     */
    void activate(Id recordId);
}