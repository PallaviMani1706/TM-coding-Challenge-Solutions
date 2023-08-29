# TM-coding-Challenge-Solutions

# Apporach Used:
Since the challenge clearly mentioned using an Apex class, I opted for the legacy approach instead of the new HTTP Callout feature in flows.

# Component Design:
1. A record trigger initiates the 'NPS Callout Flow for Fulfilled Orders - V2' flow. The entry criteria are: billtoContactId != null, NPS_Notification_already_Sent__c = false, and Order Status = Fulfilled.
2. The flow utilizes an Apex Action element to invoke the Send NPS Request method from the invocableNPSCalloutActionClass Apex class, which accepts a list of IDs as parameters.
3. The Apex class uses a @future method for the callout, invoked within the Send NPS Request method.
4. Since the NPS application can only process 30 orders at a time, a chunk size of 30 is used.
5. A field named NPS_Notification_already_Sent__c on the Order object prevents duplicate emails.
6. To inform admins about the callout status, a field named NPS_Callout_Response_Details__c is updated with callout details, including any error messages.

# Configuration steps to test this in Scratch Org:
1. deploy the files that are uploaded in the github to scratch org.
2. in the scratch org navigate to Object Manager -> search for 'Order' object and choose -> click 'Fields & Relationships' then search for 'NPS_Notification_already_Sent__c' and 'NPS_Callout_Response_Details__c' field and provide the FLS and assign it to the pagelayout.
3. click setup -> search for 'Flows' in the quick find box and choose -> check if the flow is deployed properly and activate the 'NPS Callout Flow for Fullfilled Orders - V2' flow
4. click setup -> search for named Credentials and select -> make sure the 'NPS_Legacy_Cred' named credential and it holds the end point url and Auth details and its active. if you are planning to create newly you have to click the dropdown next to New and then choose 'New Legacy'.
5. click setup -> search for apex class and choose -> search for the 'invocableNPSCalloutActionClass' available and it s test class
if all this are ready then we are good to perform testing (I assume your order object holds 'Fullfilled' status value in the picklist).

 # flow design
 1.Trigger Object - Order
 2. Configure Trigger(Trigger the flow when) - "A record is updated"
 3. Entry Conditions - "billtoContactId not equal to null, NPS_Notification_already_Sent__c equals to false and order status equals to fullfilled"
 4. When to Run the Flow for Updated Records - "Only when a record is updated to meet the condition requirements"
 5. optimize the flow for - "Actions and Related Records"

 # pre requiste to test
 1. make sure the order is associated with account and contact to trigger notification
 2. you have to associate order with few products.

# things I dint get chance to cover
Inversion way of writing test class. reason- this is something which I was not tried ans to learn adn to it was taking time and I was worried partial implementation might affect my solution, so I thought of now going with the apporach what I am aware off.

# Areas for Improvement:
1. could have used latest HTTP callout feature available in flow
2. tried new named credentials but it as the save and forget concpet for 'Auth parameters' and this was not supporting to our end poind so i used legacy named credential approach
3. can be used queueable with platform events or batch job approach
