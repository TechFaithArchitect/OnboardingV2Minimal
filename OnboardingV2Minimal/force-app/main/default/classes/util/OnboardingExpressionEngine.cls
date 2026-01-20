public with sharing class OnboardingExpressionEngine {
    private static Map<String, ParsedExpression> expressionCache = new Map<String, ParsedExpression>();

    public static Boolean evaluate(String expression) {
        return evaluate(expression, new Map<String, Object>());
    }

    public static Boolean evaluate(String expression, Map<String, Object> context) {
        if (String.isBlank(expression)) return false;

        ParsedExpression parsed = expressionCache.get(expression);
        if (parsed == null) {
            parsed = parseExpression(expression);
            expressionCache.put(expression, parsed);
        }

        return evaluateParsed(parsed, context);
    }

    private static ParsedExpression parseExpression(String expression) {
        return new ParsedExpression(expression);
    }

    private static Boolean evaluateParsed(ParsedExpression parsed, Map<String, Object> context) {
        String expr = parsed.expression;

        if (expr == 'true') return true;
        if (expr == 'false') return false;

        throw new IllegalArgumentException('Invalid expression: ' + expr);
    }

    public static void clearCache() {
        expressionCache.clear();
    }

    public class ParsedExpression {
        public String expression;

        public ParsedExpression(String expr) {
            this.expression = expr;
        }
    }
}