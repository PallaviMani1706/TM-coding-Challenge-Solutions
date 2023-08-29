/*
 * Purpose: to do HTTP callouts to a NPS Service, whenever an Order got fulfilled and send notification to customer
* Methods:
* callNPSCalloutRequest: invokable method to use in flow
* fetchOrders : to query and return the list of order records for the order IDs passed from flow
* preparePayloads: to prepare the request body or payload to be sent during the request to NPS
* chunkPayloads: as the NPS system accepts only 30 order at once so chunkifying the records and passing each 3o chunks at once
* processChunks: returns the chunked record lists in the String payload format to pass it to the request body
* makeNPSCalloutForNotification: future method makes callout and update operation
* buildHttpRequest: return the request body in the format the callout requires
* RequestPayload wrapper class: used to format the variables required for request body
*/
public class invocableNPSCalloutActionClass {
    private static final Integer CHUNK_SIZE = 30; 
    
    @InvocableMethod(label='Send NPS Request' description='Send a NPS request for a fulfilled order')
    public static void callNPSCalloutRequest(List<Id> orderIds) {
        List<Order> ordersToProcess = fetchOrders(orderIds);
        List<RequestPayload> requestPayloads = preparePayloads(ordersToProcess);
        List<List<RequestPayload>> chunks = chunkPayloads(requestPayloads);
        // Process chunks and collect responses
        processChunks(chunks);
    }
    
    private static List<Order> fetchOrders(List<Id> orderIds) {
        return [SELECT Id, OrderNumber, BillToContactId, BillToContact.Email,NPS_Notification_already_Sent__c FROM Order 
                WHERE Id IN :orderIds and NPS_Notification_already_Sent__c=false];
    }
    
    private static List<RequestPayload> preparePayloads(List<Order> orders) {
        List<RequestPayload> requestPayloads = new List<RequestPayload>();
        for(Order orderRec: orders) {
            requestPayloads.add(new RequestPayload(orderRec.Id, orderRec.OrderNumber, orderRec.BillToContact.Email));
        }
        return requestPayloads;
    }
    
    private static List<List<RequestPayload>> chunkPayloads(List<RequestPayload> payloads) {
        List<List<RequestPayload>> result = new List<List<RequestPayload>>();
        List<RequestPayload> chunk = new List<RequestPayload>();
            for(RequestPayload payload : payloads) {
                chunk.add(payload);
        
                if(chunk.size() == CHUNK_SIZE) {
                    result.add(chunk);
                    chunk = new List<RequestPayload>();
                }
            }
        
            // If there are remaining records in the chunk that have not been added
            if(chunk.size() > 0) {
                result.add(chunk);
            }
        return result;
    }
    
    private static void processChunks(List<List<RequestPayload>> chunks) {
        while(chunks.size() > 0) {
            List<RequestPayload> currentChunk = chunks.remove(0);
            String jsonString = JSON.serialize(currentChunk);
            System.debug('jsonString::'+jsonString);
            makeNPSCalloutForNotification(jsonString);
        }
    }
    
    @future(callout=true)
    private static void makeNPSCalloutForNotification(String payloads) {
        String calloutResponseDetails;
        Boolean isSuccessful = false; // Flag to indicate successful callout
        List<Order> ordersToUpdate = new List<Order>();
        HttpRequest req = buildHttpRequest(payloads);        
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('res::'+res);
            if (res.getStatusCode() == 200) {
                calloutResponseDetails = 'Successfully sent the order details.';
                isSuccessful = true;
            } 
            else {
                calloutResponseDetails = 'Failed to send order details. Status code: ' + res.getStatusCode();
            }
        } catch (System.CalloutException e) {
            calloutResponseDetails = 'Callout error: ' + e.getMessage();
        }
        finally {
        	// Update the Order records with either success or error details
        	List<RequestPayload> deserializedPayloads = (List<RequestPayload>) JSON.deserialize(payloads, List<RequestPayload>.class);
            List<Id> sfIds = new List<Id>();
            System.debug('deserializedPayloads::'+deserializedPayloads);
            for(RequestPayload payload : deserializedPayloads) {
                sfIds.add(payload.sfId);
            }
            System.debug('sfIds::'+sfIds);
            for(Id sfId : sfIds) {
                Order order = new Order(
                    Id = sfId,
                    NPS_Callout_Response_Details__c = calloutResponseDetails
                );
                if(isSuccessful) {
                    order.NPS_Notification_already_Sent__c = true;
                }
                
                ordersToUpdate.add(order);
            }
            
            if(!ordersToUpdate.isEmpty()){
                update ordersToUpdate;
            }
        }
    }
    
    private static HttpRequest buildHttpRequest(String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:NPS_Legacy_Cred/orders');
        req.setMethod('POST');
        req.setBody(body);
        return req;
    }
    
    public class RequestPayload {
    public String sfId {get; set;}
    public String orderNumber {get; set;}
    public String customerEmail {get; set;}

    public RequestPayload(String sfId, String orderNumber, String customerEmail) {
        this.sfId = sfId;
        this.orderNumber = orderNumber;
        this.customerEmail = customerEmail;
    }
}
    
}
