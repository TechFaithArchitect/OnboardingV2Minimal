/**
 * Async validator for Requirement_Field_Value__c records that require cross-field or external checks.
 * Current implementation marks pending records as Valid with a fresh timestamp; extend with real logic as needed.
 */
public with sharing class RequirementFieldAsyncValidator implements Queueable {
  private Set<Id> fieldValueIds;

  public RequirementFieldAsyncValidator(Set<Id> fieldValueIds) {
    this.fieldValueIds = fieldValueIds == null ? new Set<Id>() : fieldValueIds;
  }

  /**
   * Enqueue async validation for pending Requirement_Field_Value__c records.
   */
  public static void enqueue(Set<Id> fieldValueIds) {
    if (fieldValueIds == null || fieldValueIds.isEmpty()) {
      return;
    }
    System.enqueueJob(new RequirementFieldAsyncValidator(fieldValueIds));
  }

  public void execute(QueueableContext context) {
    if (fieldValueIds.isEmpty()) {
      return;
    }

    // Use repository for data access
    List<Requirement_Field_Value__c> valuesToUpdate = RequirementFieldValueRepository.getFieldValuesByIds(
      fieldValueIds
    );

    // Load rules for the field API names we're validating
    Set<String> fieldApis = new Set<String>();
    Set<Id> requirementIds = new Set<Id>();
    for (Requirement_Field_Value__c fieldValue : valuesToUpdate) {
      if (
        fieldValue.Requirement_Field__r != null &&
        String.isNotBlank(fieldValue.Requirement_Field__r.Field_API_Name__c)
      ) {
        fieldApis.add(fieldValue.Requirement_Field__r.Field_API_Name__c);
      }
      if (fieldValue.Onboarding_Requirement__c != null) {
        requirementIds.add(fieldValue.Onboarding_Requirement__c);
      }
    }
    Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = RequirementFieldValidationService.loadRulesByFieldApi(
      fieldApis
    );

    // Gather sibling values for cross-field checks using repository
    Map<Id, Map<String, String>> valuesByRequirement = new Map<Id, Map<String, String>>();
    if (!requirementIds.isEmpty()) {
      // Get all field values for these requirements
      List<Requirement_Field_Value__c> allSiblings = new List<Requirement_Field_Value__c>();
      for (Id reqId : requirementIds) {
        allSiblings.addAll(
          RequirementFieldValueRepository.getFieldValuesByRequirement(reqId)
        );
      }

      for (Requirement_Field_Value__c siblingFieldValue : allSiblings) {
        if (
          siblingFieldValue.Requirement_Field__r == null ||
          String.isBlank(
            siblingFieldValue.Requirement_Field__r.Field_API_Name__c
          )
        )
          continue;
        Map<String, String> mapByApi = valuesByRequirement.get(
          siblingFieldValue.Onboarding_Requirement__c
        );
        if (mapByApi == null) {
          mapByApi = new Map<String, String>();
          valuesByRequirement.put(
            siblingFieldValue.Onboarding_Requirement__c,
            mapByApi
          );
        }
        mapByApi.put(
          siblingFieldValue.Requirement_Field__r.Field_API_Name__c,
          siblingFieldValue.Encrypted_Value__c != null
            ? String.valueOf(siblingFieldValue.Encrypted_Value__c)
            : siblingFieldValue.Value__c
        );
      }
    }

    List<RequirementValidationLogger.LogEntry> validationLogs = new List<RequirementValidationLogger.LogEntry>();
    for (Requirement_Field_Value__c fieldValue : valuesToUpdate) {
      Boolean isBlank =
        String.isBlank(fieldValue.Value__c) &&
        String.isBlank(fieldValue.Encrypted_Value__c);

      Requirement_Field_Validation_Rule__mdt validationRule = (fieldValue.Requirement_Field__r !=
        null)
        ? rulesByApi.get(fieldValue.Requirement_Field__r.Field_API_Name__c)
        : null;
      String validationType = validationRule != null
        ? validationRule.Validation_Type__c
        : (fieldValue.Requirement_Field__r != null
            ? fieldValue.Requirement_Field__r.Validation_Type__c
            : null);
      Boolean isExternal = isExternalValidation(validationType);

      if (
        isExternal &&
        fieldValue.Validation_Status__c != null &&
        fieldValue.Validation_Status__c != 'Pending'
      ) {
        continue;
      }

      if (
        fieldValue.Requirement_Field__r != null &&
        fieldValue.Requirement_Field__r.Required__c &&
        isBlank
      ) {
        fieldValue.Validation_Status__c = 'Needs Correction';
        fieldValue.Validation_Error_Message__c = 'This field is required.';
      } else if (
        validationRule != null &&
        validationRule.Validation_Type__c == 'Cross-Field' &&
        !String.isBlank(validationRule.Validation_Expression__c)
      ) {
        fieldValue.Validation_Status__c = evaluateCrossField(
            validationRule.Validation_Expression__c,
            valuesByRequirement.get(fieldValue.Onboarding_Requirement__c)
          )
          ? 'Valid'
          : 'Invalid';
        fieldValue.Validation_Error_Message__c = fieldValue.Validation_Status__c ==
          'Valid'
          ? null
          : (String.isNotBlank(validationRule.Error_Message__c)
              ? validationRule.Error_Message__c
              : 'Cross-field validation failed.');
      } else if (isExternal) {
        // External validation - enqueue for external validation service
        // For now, mark as Pending. External validator will process separately
        fieldValue.Validation_Status__c = 'Pending';
        fieldValue.Validation_Error_Message__c = 'Awaiting external validation.';
        // TODO: Enqueue for external validation service
        // RequirementFieldExternalValidator.validateExternally(new Set<Id>{fieldValue.Id});
      } else {
        fieldValue.Validation_Status__c = 'Valid';
        fieldValue.Validation_Error_Message__c = null;
      }
      fieldValue.Last_Validated_Date__c = DateTime.now();

      RequirementValidationLogger.LogEntry validationLog = new RequirementValidationLogger.LogEntry();
      validationLog.fieldValueId = fieldValue.Id;
      validationLog.fieldApiName = fieldValue.Requirement_Field__r != null
        ? fieldValue.Requirement_Field__r.Field_API_Name__c
        : null;
      validationLog.validationResult = fieldValue.Validation_Status__c;
      validationLog.validationType = fieldValue.Requirement_Field__r != null
        ? fieldValue.Requirement_Field__r.Validation_Type__c
        : null;
      validationLog.message = fieldValue.Validation_Error_Message__c;
      validationLog.correlationId = String.valueOf(Crypto.getRandomLong());
      validationLog.validatedOn = fieldValue.Last_Validated_Date__c;
      validationLogs.add(validationLog);
    }

    if (!valuesToUpdate.isEmpty()) {
      update valuesToUpdate;
    }

    if (!validationLogs.isEmpty()) {
      RequirementValidationLogger.log(validationLogs);
    }
  }

  /**
   * Enhanced cross-field expression evaluator
   * Supports complex expressions with AND, OR, nested parentheses, and multiple conditions
   *
   * Supported operators:
   * - == (equality)
   * - != (inequality)
   * - AND (logical AND)
   * - OR (logical OR)
   * - ISBLANK(Field__c) (blank check)
   * - ISNOTBLANK(Field__c) (not blank check)
   * - Parentheses for grouping: (condition1 AND condition2) OR condition3
   *
   * Examples:
   * - Field1__c == Field2__c
   * - Field1__c == "literal" AND ISNOTBLANK(Field2__c)
   * - (Field1__c == Field2__c) OR (Field3__c != "value")
   * - ISBLANK(Field1__c) OR Field2__c == Field3__c
   */
  @TestVisible
  private static Boolean evaluateCrossField(
    String expression,
    Map<String, String> valuesByApi
  ) {
    if (String.isBlank(expression))
      return true;
    if (valuesByApi == null)
      valuesByApi = new Map<String, String>();

    // Normalize expression: remove extra whitespace, handle case-insensitive operators
    String normalized = normalizeExpression(expression);

    // Evaluate the expression recursively
    return evaluateExpression(normalized, valuesByApi);
  }

  /**
   * Normalize expression for consistent parsing
   */
  private static String normalizeExpression(String expression) {
    if (String.isBlank(expression))
      return expression;

    // Remove extra whitespace
    String normalized = expression.trim().replaceAll('\\s+', ' ');

    // Normalize operators to uppercase for case-insensitive matching
    normalized = normalized.replaceAll('(?i)\\bAND\\b', 'AND');
    normalized = normalized.replaceAll('(?i)\\bOR\\b', 'OR');

    return normalized;
  }

  /**
   * Recursive expression evaluator
   * Handles parentheses, AND, OR operators
   */
  private static Boolean evaluateExpression(
    String expression,
    Map<String, String> valuesByApi
  ) {
    if (String.isBlank(expression))
      return true;

    expression = expression.trim();

    // Handle OR operator (lower precedence than AND)
    if (expression.contains(' OR ')) {
      List<String> orParts = splitByOperator(expression, ' OR ');
      if (orParts.size() > 1) {
        return evaluateOrExpression(expression, valuesByApi);
      }
    }

    // Handle AND operator
    if (expression.contains(' AND ')) {
      List<String> andParts = splitByOperator(expression, ' AND ');
      if (andParts.size() > 1) {
        return evaluateAndExpression(expression, valuesByApi);
      }
    }

    // Handle function-only expressions before parentheses evaluation
    if (
      expression.startsWith('ISBLANK(') || expression.startsWith('ISNOTBLANK(')
    ) {
      return evaluateSimpleCondition(expression, valuesByApi);
    }

    if (isWrappedInParentheses(expression)) {
      return evaluateExpression(
        expression.substring(1, expression.length() - 1),
        valuesByApi
      );
    }

    // Handle parentheses - evaluate innermost first
    if (expression.contains('(')) {
      return evaluateWithParentheses(expression, valuesByApi);
    }

    // Base case: evaluate simple condition
    return evaluateSimpleCondition(expression, valuesByApi);
  }

  private static Boolean isWrappedInParentheses(String expression) {
    if (
      String.isBlank(expression) ||
      !expression.startsWith('(') ||
      !expression.endsWith(')')
    ) {
      return false;
    }

    Integer depth = 0;
    for (Integer charIndex = 0; charIndex < expression.length(); charIndex++) {
      String currentChar = expression.substring(charIndex, charIndex + 1);
      if (currentChar == '(') {
        depth++;
      } else if (currentChar == ')') {
        depth--;
        if (depth == 0 && charIndex < expression.length() - 1) {
          return false;
        }
      }
    }

    return depth == 0;
  }

  /**
   * Evaluate expression with parentheses
   * Finds innermost parentheses and evaluates recursively
   */
  private static Boolean evaluateWithParentheses(
    String expression,
    Map<String, String> valuesByApi
  ) {
    // Find innermost parentheses
    Integer openParen = expression.lastIndexOf('(');
    if (openParen == -1) {
      return evaluateExpression(expression, valuesByApi);
    }

    Integer closeParen = expression.indexOf(')', openParen);
    if (closeParen == -1) {
      // Mismatched parentheses - evaluate as simple condition
      return evaluateSimpleCondition(expression, valuesByApi);
    }

    // Extract content inside parentheses
    String innerExpression = expression.substring(openParen + 1, closeParen);
    Boolean innerResult = evaluateExpression(innerExpression, valuesByApi);

    // Replace parentheses group with result
    String before = expression.substring(0, openParen);
    String after = expression.substring(closeParen + 1);
    String replaced = before + (innerResult ? 'true' : 'false') + after;

    // Continue evaluating
    return evaluateExpression(replaced, valuesByApi);
  }

  /**
   * Evaluate OR expression
   * Returns true if any condition is true
   */
  private static Boolean evaluateOrExpression(
    String expression,
    Map<String, String> valuesByApi
  ) {
    List<String> parts = splitByOperator(expression, ' OR ');
    for (String part : parts) {
      if (evaluateExpression(part.trim(), valuesByApi)) {
        return true; // OR: return true if any part is true
      }
    }
    return false; // All parts are false
  }

  /**
   * Evaluate AND expression
   * Returns true only if all conditions are true
   */
  private static Boolean evaluateAndExpression(
    String expression,
    Map<String, String> valuesByApi
  ) {
    List<String> parts = splitByOperator(expression, ' AND ');
    for (String part : parts) {
      if (!evaluateExpression(part.trim(), valuesByApi)) {
        return false; // AND: return false if any part is false
      }
    }
    return true; // All parts are true
  }

  /**
   * Split expression by operator, respecting parentheses
   */
  private static List<String> splitByOperator(
    String expression,
    String operator
  ) {
    List<String> parts = new List<String>();
    Integer depth = 0;
    Integer start = 0;

    for (Integer charIndex = 0; charIndex < expression.length(); charIndex++) {
      String currentChar = expression.substring(charIndex, charIndex + 1);
      if (currentChar == '(') {
        depth++;
      } else if (currentChar == ')') {
        depth--;
      } else if (depth == 0 && expression.substring(charIndex).startsWith(operator)) {
        // Found operator at top level
        parts.add(expression.substring(start, charIndex));
        start = charIndex + operator.length();
        charIndex += operator.length() - 1; // Skip operator
      }
    }

    // Add remaining part
    if (start < expression.length()) {
      parts.add(expression.substring(start));
    }

    return parts;
  }

  /**
   * Evaluate simple condition (no AND/OR/parentheses)
   * Supports: ==, !=, ISBLANK(), ISNOTBLANK()
   */
  private static Boolean evaluateSimpleCondition(
    String expression,
    Map<String, String> valuesByApi
  ) {
    expression = expression.trim();

    // Handle boolean literals (from parentheses replacement)
    if (expression.equalsIgnoreCase('true'))
      return true;
    if (expression.equalsIgnoreCase('false'))
      return false;

    // ISBLANK(Field__c)
    if (expression.startsWith('ISBLANK(') && expression.endsWith(')')) {
      String field = expression.substring(8, expression.length() - 1).trim();
      String fieldValueString = valuesByApi.get(field);
      return String.isBlank(fieldValueString);
    }

    // ISNOTBLANK(Field__c)
    if (expression.startsWith('ISNOTBLANK(') && expression.endsWith(')')) {
      String field = expression.substring(11, expression.length() - 1).trim();
      String fieldValueString = valuesByApi.get(field);
      return !String.isBlank(fieldValueString);
    }

    // Equality: Field__c == OtherField__c or Field__c == "literal"
    if (expression.contains('==')) {
      List<String> parts = splitCondition(expression, '==');
      if (parts.size() == 2) {
        String left = parts[0].trim();
        String right = parts[1].trim();
        String leftVal = getFieldValue(left, valuesByApi);
        String rightVal = getFieldValue(right, valuesByApi);
        return stringEquals(leftVal, rightVal);
      }
    }

    // Inequality: Field__c != OtherField__c or Field__c != "literal"
    if (expression.contains('!=')) {
      List<String> parts = splitCondition(expression, '!=');
      if (parts.size() == 2) {
        String left = parts[0].trim();
        String right = parts[1].trim();
        String leftVal = getFieldValue(left, valuesByApi);
        String rightVal = getFieldValue(right, valuesByApi);
        return !stringEquals(leftVal, rightVal);
      }
    }

    // If we cannot interpret the expression, fail-safe to Invalid
    return false;
  }

  /**
   * Split condition by operator, handling quoted literals
   */
  private static List<String> splitCondition(
    String expression,
    String operator
  ) {
    List<String> parts = new List<String>();
    Integer operatorIndex = expression.indexOf(operator);

    if (operatorIndex == -1) {
      return parts;
    }

    String left = expression.substring(0, operatorIndex).trim();
    String right = expression.substring(operatorIndex + operator.length())
      .trim();

    parts.add(left);
    parts.add(right);

    return parts;
  }

  /**
   * Get field value from map or return literal value
   */
  private static String getFieldValue(
    String fieldOrLiteral,
    Map<String, String> valuesByApi
  ) {
    // Check if it's a quoted literal
    if (
      (fieldOrLiteral.startsWith('"') && fieldOrLiteral.endsWith('"')) ||
      (fieldOrLiteral.startsWith('\'') && fieldOrLiteral.endsWith('\''))
    ) {
      // Remove quotes
      return fieldOrLiteral.substring(1, fieldOrLiteral.length() - 1);
    }

    // Check if it's a field reference
    if (valuesByApi.containsKey(fieldOrLiteral)) {
      return valuesByApi.get(fieldOrLiteral);
    }

    // Return as-is (might be a literal without quotes or unknown field)
    return fieldOrLiteral;
  }

  /**
   * String equality comparison (case-insensitive, null-safe)
   */
  private static Boolean stringEquals(String a, String b) {
    if (a == null && b == null)
      return true;
    if (a == null || b == null)
      return false;
    return a.equalsIgnoreCase(b);
  }

  private static Boolean isExternalValidation(String validationType) {
    return String.isNotBlank(validationType) &&
      validationType.toLowerCase().startsWith('external');
  }
}
