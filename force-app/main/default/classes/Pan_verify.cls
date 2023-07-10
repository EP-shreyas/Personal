public class Pan_verify {
	public void sendPostRequest() {
        String cid='CF231180CCR8H6584OK74C7OSGL0';
        Long curTime = Math.round(DateTime.now().getTime() / 1000.0);
        System.debug(curTime);
        String curTimeStr = String.valueOf(curTime);
        String encodeData = cid + '.' + curTimeStr;
        string publicKey='MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAgDn4uX9EDm1PMh29VVDybq3ukh6ITwSy08NrmZ6kNjX9TTJiNWTbgy7eWhg/xxB5c5G5YIzZP5E/NF2Oa3sroWp5ibBLd+kz0Bzjgr1noKyWZd11Jv0tXl0oF/D2twW1G8MLv5BGQzQsV7PMS4NiZ4zc19OuX9pfrE0PTuO7y8o0wU6c3q6L1U6Kp0RmdrlDBoG1nsQ2omxV0lWhmYMPG5f5FGZa5kn/zDCIbX9vj40DdJmEBEDn8SKNw+MPopNtNvACtWZd8fQ/ffX9bz9ryG8hiOG+OJzshp0CTtPvnOZd2+ucIVvyfMZPvEwhGJuW8cYR0/d+Hl5J5bZfW8Z0wQIDAQAB';  // your private key
        Blob key = EncodingUtil.base64Decode(publicKey);
        blob rs256sig = Crypto.sign(
            'RSA-SHA256', 
            Blob.valueOf(encodeData), 
            key);
        String endpoint = 'https://api.cashfree.com/verification/pan';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-client-id',cid);
        req.setHeader('x-client-secret','154f7accb1236766e205ac611bd2cc83ba901773');
        req.setHeader('x-Cf-signature', 'LlELeRxqE7X5r/j2UTib3il84o+9Z0miLTSIFr9VeaAEV+CjwTPhxduh+awFwYgEYs8wQQaSbJxb0g5aZK7rfgWoy/V6ucLgCSoYoHajmYSuixqYfuJBrgrBRDI/javFzlskcVtajFbbUHhVy+mxFnnr0oElbi4MYuRpgcN2drtEgNWJoKjE18Z2xvqXyEgxDiVddVCM7RGHcc9gTHl718ZP+Dylvnk6EF+6Vi9v+ieLgCLaFQZ/kYzFez3Ej1GvkOspkh576bHtTVwU54l6rgHMS59V3gGd6QqrROmgv5O+VkH83EqlA7FWcIA7Um0g+L4uKPWiUUk2aWhrcdF6qg==');
        req.setBody('{"pan":"CDEPJ2456D"}');
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            // Success, handle response
            String responseBody = res.getBody();
            // TODO: handle response body
        } else {
            String status = res.getStatus();
            Integer statusCode = res.getStatusCode();
            String errorMessage = 'API request failed with status ' + statusCode + ' ' + status;
        }
    } 
}