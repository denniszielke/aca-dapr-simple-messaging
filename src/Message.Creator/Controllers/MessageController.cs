using Message.Creator.Clients;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using System.Text;
using System.Text.Json;

namespace Message.Creator.Controllers
{

    [ApiController]
    [Route("api")]
    public class MessageController : ControllerBase
    {
        private readonly ReceiverClient _receiverClient;
        private readonly DaprReceiverClient _daprReceiverClient;
        private readonly ILogger<MessageController> _logger;

        public MessageController(ReceiverClient receiverClient,
                                DaprReceiverClient daprReceiverClient,
                                 ILogger<MessageController> logger)
        {
            _receiverClient = receiverClient;
            _daprReceiverClient = daprReceiverClient;
            _logger = logger;
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

                response = await _receiverClient.SendMessageAsync(message);   

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

                response = await _daprReceiverClient.SendMessageAsync(message);   

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
