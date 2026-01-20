public class OnboardingExpirationEvaluator {
  public static Boolean bypassTracking = false;
  private static final Map<String, String> LOOKUP_TO_STATUS_FIELD = new Map<String, String>{
    'LearnUponContactEnrollment__c' => 'LearnUpon_Training_Status__c'
  };

  public static void runExpirationJob() {
    List<Onboarding_Status_Tracking_Config__mdt> configs = [
      SELECT
        Object__c,
        Field__c,
        Expire_Threshold_Days__c,
        Lookup_To_Onboarding__c
      FROM Onboarding_Status_Tracking_Config__mdt
      WHERE IsActive__c = TRUE AND Expire_On_Inactivity__c = TRUE
    ];
    runExpirationJobWithConfigs(configs);
  }

  public static void runExpirationJobWithConfigs(
    List<Onboarding_Status_Tracking_Config__mdt> cmdtConfigs
  ) {
    if (bypassTracking) {
      System.debug('Expiration tracking bypassed.');
      return;
    }

    System.debug('🟦 START runExpirationJobWithConfigs');

    Map<String, Schema.SObjectField> onboardingFields = Schema.SObjectType.Onboarding__c.fields.getMap();
    Map<String, Integer> thresholdByField = new Map<String, Integer>();
    Integer maxThreshold = 0;

    for (Onboarding_Status_Tracking_Config__mdt cfg : cmdtConfigs) {
      String statusField = resolveOnboardingStatusField(cfg, onboardingFields);
      if (String.isBlank(statusField)) {
        continue;
      }

      Integer threshold = cfg.Expire_Threshold_Days__c == null
        ? 0
        : cfg.Expire_Threshold_Days__c.intValue();
      Integer existingThreshold = thresholdByField.get(statusField);
      if (existingThreshold == null || threshold > existingThreshold) {
        thresholdByField.put(statusField, threshold);
      }
      if (threshold > maxThreshold) {
        maxThreshold = threshold;
      }
    }

    if (thresholdByField.isEmpty()) {
      System.debug(
        'No tracked status fields configured. Skipping expiration evaluation.'
      );
      System.debug('🟦 END runExpirationJobWithConfigs');
      return;
    }

    DateTime now = System.now();
    DateTime earliestCutoff = now.addDays(-maxThreshold);

    List<Onboarding__History> recentHistory = [
      SELECT ParentId, Field, CreatedDate
      FROM Onboarding__History
      WHERE
        Field IN :thresholdByField.keySet()
        AND CreatedDate >= :earliestCutoff
    ];

    Map<Id, Set<String>> onboardingToFreshFields = new Map<Id, Set<String>>();

    for (Onboarding__History hist : recentHistory) {
      Integer threshold = thresholdByField.get(hist.Field);
      if (threshold == null) {
        continue;
      }

      DateTime cutoff = now.addDays(-threshold);
      if (hist.CreatedDate >= cutoff) {
        if (!onboardingToFreshFields.containsKey(hist.ParentId)) {
          onboardingToFreshFields.put(hist.ParentId, new Set<String>());
        }
        onboardingToFreshFields.get(hist.ParentId).add(hist.Field);
      }
    }

    List<Onboarding__c> activeList = [
      SELECT Id, Onboarding_Status__c
      FROM Onboarding__c
      WHERE
        Onboarding_Status__c NOT IN (
          'Cancelled',
          'Setup Complete',
          'Expired',
          'Denied'
        )
    ];

    List<Onboarding__c> toExpire = new List<Onboarding__c>();
    Set<String> requiredFields = thresholdByField.keySet();

    for (Onboarding__c onboardingRecord : activeList) {
      Set<String> freshFields = onboardingToFreshFields.get(
        onboardingRecord.Id
      );

      // If any required field is missing, expire the onboarding
      if (freshFields == null || !freshFields.containsAll(requiredFields)) {
        onboardingRecord.Onboarding_Status__c = 'Expired';
        toExpire.add(onboardingRecord);
        System.debug('💡 Expiring onboarding ' + onboardingRecord.Id);
      } else {
        System.debug('✅ Onboarding ' + onboardingRecord.Id + ' is up to date');
      }
    }

    if (!toExpire.isEmpty()) {
      update toExpire;
      System.debug('✅ Expired onboardings: ' + toExpire.size());
    } else {
      System.debug('🔷 No onboardings expired.');
    }

    System.debug('🟦 END runExpirationJobWithConfigs');
  }

  private static String resolveOnboardingStatusField(
    Onboarding_Status_Tracking_Config__mdt cfg,
    Map<String, Schema.SObjectField> onboardingFields
  ) {
    if (cfg == null) {
      return null;
    }

    if (
      cfg.Object__c == 'Onboarding__c' &&
      onboardingFields.containsKey(cfg.Field__c)
    ) {
      return cfg.Field__c;
    }

    if (!String.isBlank(cfg.Lookup_To_Onboarding__c)) {
      if (LOOKUP_TO_STATUS_FIELD.containsKey(cfg.Lookup_To_Onboarding__c)) {
        String overrideField = LOOKUP_TO_STATUS_FIELD.get(
          cfg.Lookup_To_Onboarding__c
        );
        if (onboardingFields.containsKey(overrideField)) {
          return overrideField;
        }
      }

      String candidate =
        cfg.Lookup_To_Onboarding__c.replace('__c', '') + '_Status__c';
      if (onboardingFields.containsKey(candidate)) {
        return candidate;
      }
    }

    if (
      !String.isBlank(cfg.Field__c) &&
      onboardingFields.containsKey(cfg.Field__c)
    ) {
      return cfg.Field__c;
    }

    return null;
  }
}
