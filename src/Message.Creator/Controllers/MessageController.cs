using Message.Creator.Clients;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using System.Text;
using System.Text.Json;
using System.Diagnostics;
using System.Diagnostics.Metrics;

namespace Message.Creator.Controllers
{

    [ApiController]
    [Route("api")]
    public class MessageController : ControllerBase
    {
        // private readonly ReceiverClient _receiverClient;
        // private readonly DaprReceiverClient _daprReceiverClient;
        private readonly IReceiverClient _receiverClient;
        private readonly ILogger<MessageController> _logger;

        private readonly Meter _meter = new Meter("Message.Creator");

        private readonly Counter<long> publishCounter;

        private readonly Counter<long> sendCounter;

        public MessageController(IReceiverClient receiverClient,
                                 ILogger<MessageController> logger)
        {
            _receiverClient = receiverClient;
            _logger = logger;
            publishCounter = _meter.CreateCounter<long>("publish.count", description: "Number of successful publishes");
            sendCounter = _meter.CreateCounter<long>("send.count", description: "Number of successful sends");
        }

        [HttpPost("/receive")]
        public async Task<IActionResult> Receive([FromBody] DeviceMessage message)
        {
            MessageResponse response = null;
            try
            {
                _logger.LogTrace($"received message {message.Id}");

                if (string.IsNullOrWhiteSpace(message.Id))
                {
                    return new BadRequestResult();
                }

                response = await _receiverClient.InvokeMessageAsync(message);   
                sendCounter.Add(1);
                _logger.LogTrace($"written move {message}");
            }
            catch (System.Exception ex)
            {
                _logger.LogError(ex, ex.Message);
                response = new MessageResponse(){
                        Id = message.Id, Status = MessageStatus.Failed, Sender = "message-creator", Host = Environment.MachineName
                    };
            }

            return new JsonResult(response);
        }

        [HttpPost("/publish")]
        public async Task<IActionResult> Publish([FromBody] DeviceMessage message)
        {
            MessageResponse response = null;
            try
            {
                _logger.LogTrace($"received message {message.Id}");

                if (string.IsNullOrWhiteSpace(message.Id))
                {
                    return new BadRequestResult();
                }

                response = await _receiverClient.PublishMessageAsync(message);   
                publishCounter.Add(1);
                _logger.LogTrace($"written move {message}");
            }
            catch (System.Exception ex)
            {
                _logger.LogError(ex, ex.Message);
                response = new MessageResponse(){
                        Id = message.Id, Status = MessageStatus.Failed, Sender = "message-creator", Host = Environment.MachineName
                    };
            }

            return new JsonResult(response);
        }
        //     MessageResponse response = null;
        //     try
        //     {
        //         _logger.LogTrace($"received message {message.Id}");

        //         if (string.IsNullOrWhiteSpace(message.Id))
        //         {
        //             return new BadRequestResult();
        //         }
                
        //         string jsonString = JsonSerializer.Serialize(message);

              

        //         response = new MessageResponse(){
        //                 Id = message.Id, Status = MessageStatus.Ok, Sender = "message-creator", Host = Environment.MachineName
        //             };

        //         _logger.LogTrace($"written move {message}");
        //     }
        //     catch (System.Exception ex)
        //     {
        //         _logger.LogError(ex, ex.Message);
        //         response = new MessageResponse(){
        //                 Id = message.Id, Status = MessageStatus.Failed, Sender = "message-creator", Host = Environment.MachineName
        //             };
        //     }

        //     return new JsonResult(response);
        // }

    }

}
