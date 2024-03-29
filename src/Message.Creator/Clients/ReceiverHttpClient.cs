using System.Net;
using System.Text.Json;


namespace Message.Creator.Clients
{
    public class ReceiverHttpClient : IReceiverClient
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<ReceiverHttpClient> _logger;

        public ReceiverHttpClient(IHttpClientFactory httpClientFactory, ILogger<ReceiverHttpClient> logger)
        {
            _httpClientFactory = httpClientFactory;
            _logger = logger;
        }

        public async Task<MessageResponse> PublishMessageAsync(DeviceMessage message)
        {           

            return new MessageResponse(){
                        Id = message.Id, Status = MessageStatus.Failed, Sender = "message-receiver", Host = Environment.MachineName
                    };;
        }

        public async Task<MessageResponse> InvokeMessageAsync(DeviceMessage message)
        {
            var client = _httpClientFactory.CreateClient("ReceiverHttpClient"); 
            client.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
            MessageResponse receivedResponse = null;
            var response = await client.PostAsJsonAsync("/invoke", 
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