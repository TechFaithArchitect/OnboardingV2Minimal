public interface OnboardingAppValidationRule {
    void validate(List<SObject> newList, Map<Id, SObject> oldMap);
}