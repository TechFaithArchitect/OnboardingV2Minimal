@isTest
public class TestProductFactory {

    private static final String DEFAULT_VENDOR = 'DIRECTV';
    private static final String DEFAULT_FAMILY = 'DirecTV';

    public static ProductWrapper create(Boolean doInsert, Boolean isSerialized, String productName) {
        Product2 product = new Product2(
            Name = productName,
            IsSerialized = isSerialized,
            IsActive = true,
            Family = DEFAULT_FAMILY,
            FSL_Product__c = true,
            FSL_Vendor__c = DEFAULT_VENDOR
        );

        if (doInsert) {
            insert product;
        }

        return new ProductWrapper(product);
    }

    public class ProductWrapper {
        public Product2 product;

        public ProductWrapper(Product2 product) {
            this.product = product;
        }
    }
}