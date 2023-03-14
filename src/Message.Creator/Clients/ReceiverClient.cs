using System.Net;
using System.Text.Json;


namespace Message.Creator.Clients
{
    public class ReceiverClient
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<ReceiverClient> _logger;

        public ReceiverClient(IHttpClientFactory httpClientFactory, ILogger<ReceiverClient> logger)
        {
            _httpClientFactory = httpClientFactory;
            _logger = logger;
        }


        public async Task<MessageResponse> SendMessageAsync(DeviceMessage message)
        {
            var client = _httpClientFactory.CreateClient("Receiver"); 
            client.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
            MessageResponse receivedResponse = null;
            var response = await client.PostAsJsonAsync("/v1.0/invoke/message-receiver/method/receive", 
            message, 
            new System.Text.Json.JsonSerializerOptions(){
                WriteIndented = true,
                PropertyNameCaseInsensitive = true
            });
            
            try
            {
                Console.WriteLine(response.StatusCode);

                if(response.IsSuccessStatusCode){
                    string responseBody = await response.Content.ReadAsStringAsync();
                    Console.WriteLine(responseBody);
                    var sinkResponse = JsonSerializer.Deserialize<MessageResponse>(responseBody)!;
                    receivedResponse = new MessageResponse(){
                        Id = message.Id, Status = MessageStatus.Ok, Sender = "message-creator", Host = Environment.MachineName
                    };
                    receivedResponse.Dependency = sinkResponse;
                }
                else{
                    if (response.StatusCode == HttpStatusCode.TooManyRequests){
                            receivedResponse = new MessageResponse(){
                            Id = message.Id, Status = MessageStatus.Throttled, Sender = "message-creator", Host = Environment.MachineName
                        };
                    }else{
                        receivedResponse = new MessageResponse(){
                            Id = message.Id, Status = MessageStatus.Failed, Sender = "message-creator", Host = Environment.MachineName
                        };
                    }     
                }
            }
            catch (System.Exception ex)
            {
                _logger.LogError(ex, ex.Message);
                receivedResponse = new MessageResponse(){
                        Id = message.Id, Status = MessageStatus.Failed, Sender = "message-receiver", Host = Environment.MachineName
                    };
            }

            return receivedResponse;
        }
    }
}