public with sharing class Utilities {
    public class ListViewWrapper {
        public List<String> fields {get; set;}
        public List<String> columnNames {get; set;}
        public List<List<Sobject>> allRecords {get; set;}

        private String objectName;
        private String listId;

        public ListViewWrapper(String objectName, String listId) {
            this.objectName = objectName;
            this.listId = listId;

            fields = new List<String>();
            columnNames = new List<String>();
            allRecords = new List<List<Sobject>>();
        }

        public void fetchListViewDetail() {
            // Http callout 
            HttpRequest httpRequest = new HttpRequest();
           
            String endpoint = String.format(
                '{0}/services/data/v59.0/sobjects/{1}/listviews/{2}/describe', 
                new List<String> {
                    System.Url.getOrgDomainUrl().toExternalForm(),
                    objectName, listId
                }
            );

            httpRequest.setEndpoint(endpoint);
            httpRequest.setMethod('GET');
            httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
            httpRequest.setHeader('Content-Type', 'application/json');
            HttpResponse httpResponse = new Http().send(httpRequest);
            Map<String,Object> jsonRoot = (Map<String, Object>)JSON.deserializeUntyped(httpResponse.getBody());

            // Nested list logic to overcome collection limit
            List<Sobject> recordList = new List<Sobject>();
            for(Sobject salesforceObject : Database.query((String)jsonRoot.get('query'))){
                recordList.add(salesforceObject);
                if (recordList.size() == 10000) {
                    allRecords.add(recordList);
                    recordList = new List<sObject>();
                }
             }
             
            if (!recordList.isEmpty()) {
                allRecords.add(recordList);
            }
            
            // Parsing JSON string to get the column details
            List<Utilities.Columns> parsedColumns =
                (List<Utilities.Columns>) System.JSON.deserialize(
                    JSON.serialize(jsonRoot.get('columns')), 
                    List<Utilities.Columns>.class
                );

            for (Utilities.Columns column : parsedColumns) {
                if(column.hidden == false && column.fieldNameOrPath != Null){
                    fields.add(column.fieldNameOrPath);
                    columnNames.add(column.label);
                }
            }
        }
    }

    public class Columns {
        public String ascendingLabel;
        public String descendingLabel;
        public String fieldNameOrPath;
        public Boolean hidden;
        public String label;
        public String selectListItem;
        public String sortDirection;
        public Integer sortIndex;
        public Boolean sortable;
        public String type;
    }
}