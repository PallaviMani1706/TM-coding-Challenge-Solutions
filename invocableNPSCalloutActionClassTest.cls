@isTest
public class invocableNPSCalloutActionClassTest {
    
    @testSetup
    static void setup() {
        //Create test Account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Create test Contact associated with Account
        Contact con = new Contact(LastName='Test Contact', Email='test@example.com', AccountId=acc.Id);
        insert con;
        
        // Create test Orders
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 100; i++) {
            Order ord = new Order();
            ord.BillToContactId = con.Id; 
            ord.NPS_Notification_already_Sent__c = false;
            orders.add(ord);
        }
        insert orders;
    }
    
    static testMethod void testCallNPSCalloutRequest() {
      // Get the Ids of the setup Orders
        List<Id> orderIds = new List<Id>();
        for (Order ord : [SELECT Id FROM Order]) {
            orderIds.add(ord.Id);
        }
        
        Test.startTest();
        
        // Mock the HTTP Callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call the method to test
        invocableNPSCalloutActionClass.callNPSCalloutRequest(orderIds);

        Test.stopTest();
        
        // Validate the orders
        List<Order> updatedOrders = [SELECT Id, NPS_Notification_already_Sent__c, NPS_Callout_Response_Details__c FROM Order WHERE Id IN :orderIds];
        
        for (Order ord : updatedOrders) {
            System.assertEquals(true, ord.NPS_Notification_already_Sent__c);
            System.assertEquals('Successfully sent the order details.', ord.NPS_Callout_Response_Details__c);
        }
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}