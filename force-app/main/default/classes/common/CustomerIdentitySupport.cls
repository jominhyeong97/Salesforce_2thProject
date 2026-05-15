public class CustomerIdentitySupport {
    @TestVisible
    private static final String PERSONAL_COMPANY_PREFIX = '(개인) ';

    public static Boolean isPersonalCompanyName(String companyName) {
        return !String.isBlank(companyName) &&
            companyName.trim().startsWith(PERSONAL_COMPANY_PREFIX);
    }

    public static String buildPersonalCompanyName(String fullName) {
        String normalizedName = String.isBlank(fullName) ? '이름없음' : fullName.trim();
        return truncateValue(PERSONAL_COMPANY_PREFIX + normalizedName, 255);
    }

    private static String truncateValue(String value, Integer maxLength) {
        if (String.isBlank(value) || maxLength == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }
}
