/**
 * Validates presence and ordering of the Vendor Program Onboarding process and components.
 */
public with sharing class OnboardingHealthService {
  public class HealthItem {
    @AuraEnabled
    public String type;
    @AuraEnabled
    public String message;
  }

  private static final String PROCESS_NAME = 'Vendor Program Onboarding';
  private static final List<String> EXPECTED_COMPONENTS = new List<String>{
    'vendorProgramOnboardingVendor',
    'vendorProgramOnboardingVendorProgramSearchOrCreate',
    'vendorProgramOnboardingRequirementSetOrCreate',
    'vendorProgramOnboardingRequirementGroupLinking',
    'vendorProgramOnboardingRequiredCredentials',
    'vendorProgramOnboardingTrainingRequirements',
    'vendorProgramOnboardingStatusRulesEngine',
    'vendorProgramOnboardingRecipientGroup',
    'vendorProgramOnboardingCommunicationTemplate',
    'vendorProgramOnboardingFinalize'
  };

  @AuraEnabled(cacheable=true)
  public static List<HealthItem> runHealthCheck() {
    List<HealthItem> healthItems = new List<HealthItem>();

    Map<String, Id> componentLibraryMap = OnboardingHealthRepository.getComponentLibraryByApiName();
    for (String apiName : EXPECTED_COMPONENTS) {
      if (!componentLibraryMap.containsKey(apiName)) {
        healthItems.add(
          item('component', 'Missing component library entry: ' + apiName)
        );
      }
    }

    List<Onboarding_Application_Process__c> processes = OnboardingHealthRepository.fetchActiveProcessesByName(
      PROCESS_NAME
    );
    if (processes.isEmpty()) {
      healthItems.add(
        item('process', 'Active process not found: ' + PROCESS_NAME)
      );
      return healthItems;
    }

    Id processId = processes[0].Id;
    List<Onboarding_Application_Stage__c> stages = OnboardingHealthRepository.fetchStagesForProcess(
      processId
    );

    if (stages.size() != EXPECTED_COMPONENTS.size()) {
      healthItems.add(
        item(
          'stage',
          'Stage count mismatch. Expected ' +
            EXPECTED_COMPONENTS.size() +
            ', found ' +
            stages.size()
        )
      );
    }

    Map<Integer, Onboarding_Application_Stage__c> stagesByOrder = new Map<Integer, Onboarding_Application_Stage__c>();
    for (Onboarding_Application_Stage__c onboardingStage : stages) {
      stagesByOrder.put(
        (Integer) onboardingStage.Display_Order__c,
        onboardingStage
      );
    }

    for (Integer componentIndex = 0; componentIndex < EXPECTED_COMPONENTS.size(); componentIndex++) {
      Integer order = componentIndex + 1;
      Onboarding_Application_Stage__c onboardingStage = stagesByOrder.get(
        order
      );
      if (onboardingStage == null) {
        healthItems.add(item('stage', 'Missing stage at order ' + order));
        continue;
      }
      String expectedApi = EXPECTED_COMPONENTS[componentIndex];
      if (onboardingStage.Onboarding_Component_Library__c == null) {
        healthItems.add(
          item('stage', 'Stage ' + order + ' has no component link')
        );
        continue;
      }
      // Fetch component api names once for comparison
      String actualApi = null;
      for (String componentApiName : componentLibraryMap.keySet()) {
        if (
          componentLibraryMap.get(componentApiName) ==
          onboardingStage.Onboarding_Component_Library__c
        ) {
          actualApi = componentApiName;
          break;
        }
      }
      if (actualApi == null || actualApi != expectedApi) {
        healthItems.add(
          item(
            'stage',
            'Stage ' +
              order +
              ' component mismatch. Expected ' +
              expectedApi +
              ', found ' +
              (actualApi == null ? 'unknown' : actualApi)
          )
        );
      }
    }

    if (healthItems.isEmpty()) {
      healthItems.add(item('ok', 'Component library and process are aligned.'));
    }
    return healthItems;
  }

  private static HealthItem item(String type, String healthItemMessage) {
    HealthItem healthItem = new HealthItem();
    healthItem.type = type;
    healthItem.message = healthItemMessage;
    return healthItem;
  }
}
