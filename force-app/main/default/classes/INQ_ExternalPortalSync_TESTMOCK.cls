/**
 * @author      WDCi (Xirouh)
 * @date        June 2024
 * @group       
 * @description HTTP Callout Mock for inq test class
 * @changehistory
 * ISS-001978 24-06-2024  Xirouh - new class
 */
@isTest
global class INQ_ExternalPortalSync_TESTMOCK implements HttpCalloutMock {
    HttpResponse res;

	/***************************************************
    * @description Constructor
    * @param HttpResponse The HttpResponse to return
    ****************************************************/
    public INQ_ExternalPortalSync_TESTMOCK(HttpResponse r) {
        res = r;
    }

    /***************************************************
    * @description HttpCalloutMock Interface method to return the response
    * @param HttpRequest The request
    * @return HttpResponse The Response
    ****************************************************/
    global HTTPResponse respond(HTTPRequest req) {
        return res;
    }
}