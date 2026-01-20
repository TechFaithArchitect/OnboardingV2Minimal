public with sharing class ZipCodeTerritoryAssignment {
    public Id ownerId;
    public String division;
    public String region;
    public String territory;

    public ZipCodeTerritoryAssignment(Id ownerId, String division, String region, String territory) {
        this.ownerId = ownerId;
        this.division = division;
        this.region = region;
        this.territory = territory;
    }
}