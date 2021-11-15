public without sharing class ManagePaymentServiceHelper {
    public static void handleInsertDML(SObject sobj){
        insert sobj;
    }
    public static void handleUpsertDML(List<SObject> sobjList){
        upsert sobjList;
    }

}