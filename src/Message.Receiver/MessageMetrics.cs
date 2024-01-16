using System.Diagnostics.Metrics;

namespace Message.Receiver {

    public class MessageMetrics
    {
        private readonly Counter<int> _messagesReceived;
        private readonly Counter<int> _messagesFailed;
        private readonly Counter<int> _messagesInvoked;

        public MessageMetrics(IMeterFactory meterFactory){
            var meter = meterFactory.Create("Messaging.");
            _messagesReceived = meter.CreateCounter<int>("messages.sent");
            _messagesFailed = meter.CreateCounter<int>("messages.failed");
            _messagesInvoked = meter.CreateCounter<int>("messages.throttled");
        }

        public void MessagesReceived(string sender, int count){
            _messagesReceived.Add(count, new KeyValuePair<string, object?>("messages.sender", sender));
        }

        public void MessagesFailed(string sender, int count){
            _messagesFailed.Add(count, new KeyValuePair<string, object?>("messages.sender", sender));
        }

        public void MessagesInvoked(string sender, int count){
            _messagesInvoked.Add(count, new KeyValuePair<string, object?>("messages.sender", sender));
        }
    }

}