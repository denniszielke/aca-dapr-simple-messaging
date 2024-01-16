using System.Diagnostics.Metrics;

namespace Message.Creator {

    public class MessageMetrics
    {
        private readonly Counter<int> _messagesSent;
        private readonly Counter<int> _messagesPublished;
        private readonly Counter<int> _messagesFailed;
        private readonly Counter<int> _messagesThrottled;

        public MessageMetrics(IMeterFactory meterFactory){
            var meter = meterFactory.Create("Messaging.");
            _messagesSent = meter.CreateCounter<int>("messages.sent");
            _messagesPublished = meter.CreateCounter<int>("messages.published");
            _messagesFailed = meter.CreateCounter<int>("messages.failed");
            _messagesThrottled = meter.CreateCounter<int>("messages.throttled");
        }

        public void MessagesPublished(string sender, int count){
            _messagesPublished.Add(count, new KeyValuePair<string, object?>("messages.sender", sender));
        }

        public void MessagesSent(string sender, int count){
            _messagesSent.Add(count, new KeyValuePair<string, object?>("messages.sender", sender));
        }

        public void MessagesFailed(string sender, int count){
            _messagesFailed.Add(count, new KeyValuePair<string, object?>("messages.sender", sender));
        }

        public void MessagesThrottled(string sender, int count){
            _messagesThrottled.Add(count, new KeyValuePair<string, object?>("messages.sender", sender));
        }
    }

}