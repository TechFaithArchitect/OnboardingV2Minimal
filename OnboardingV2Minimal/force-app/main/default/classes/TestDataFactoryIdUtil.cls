public class TestDataFactoryIdUtil {
    public static String uniqueSuffix() {
        return String.valueOf(DateTime.now().getTime()) +
               Math.mod(Crypto.getRandomInteger(), 1000);
    }

    public static String generateFakeId(String prefix) {
        if (String.isBlank(prefix) || prefix.length() != 3) {
            prefix = '001'; // Default to Account prefix
        }
        String baseId = prefix + '000000000000'; // 15 chars so Id.valueOf can generate a valid checksum
        return String.valueOf(Id.valueOf(baseId));
    }

    public static String fakeAsyncId() {
        return generateFakeId('0Af');
    }

    public static String fakeJobId() {
        return generateFakeId('707');
    }

    public static String fakeIdForSObject(Schema.SObjectType sObjType) {
        return generateFakeId(sObjType.getDescribe().getKeyPrefix());
    }

    public static Id safeFakeId(String prefix) {
        return Id.valueOf(generateFakeId(prefix));
    }

    /**
     * Generates a safe fake Id for an SObject type.
     * Handles cases where the key prefix might be null or invalid.
     * Uses a fallback prefix if the object's key prefix cannot be determined.
     * 
     * @param sObjType The SObject type to generate a fake ID for
     * @return A valid fake Id (always returns a value, never null)
     */
    public static Id safeFakeIdForSObject(Schema.SObjectType sObjType) {
        if (sObjType == null) {
            // Fallback to Account prefix if object type is null
            return safeFakeId('001');
        }
        
        try {
            String keyPrefix = sObjType.getDescribe().getKeyPrefix();
            if (String.isBlank(keyPrefix) || keyPrefix.length() != 3) {
                // Fallback to a generic prefix if key prefix is invalid
                keyPrefix = '001'; // Default to Account prefix
            }
            String fakeIdString = generateFakeId(keyPrefix);
            return Id.valueOf(fakeIdString);
        } catch (Exception e) {
            // If Id conversion fails (e.g., invalid format), use fallback prefix
            // This can happen with certain standard objects that have non-standard key prefixes
            return safeFakeId('001');
        }
    }
}