using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Message.Creator.Clients
{
    public class DaprReceiverClient
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<DaprReceiverClient> _logger;

        public DaprReceiverClient(IHttpClientFactory httpClientFactory, ILogger<DaprReceiverClient> logger)
        {
            _httpClientFactory = httpClientFactory;
            _logger = logger;
        }


        public async Task<MessageResponse> SendMessageAsync(DeviceMessage message)
        {
            var client = _httpClientFactory.CreateClient("DaprReceiver"); 
            client.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
            MessageResponse receivedResponse = null;
            
            var messageJson = JsonSerializer.Serialize<DeviceMessage>(message);
            var content = new StringContent(messageJson, System.Text.Encoding.UTF8, "application/json");
           
                     
            try
            {

                  var response = await client.PostAsJsonAsync("/v1.0/publish/pubsub/messages", 
            content);

                Console.WriteLine(response.StatusCode);

                if(response.IsSuccessStatusCode){
                    string responseBody = await response.Content.ReadAsStringAsync();
                    Console.WriteLine(responseBody);
                    receivedResponse = new MessageResponse(){
                        Id = message.Id, Status = MessageStatus.Ok, Sender = "message-creator", Host = Environment.MachineName
                    };
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