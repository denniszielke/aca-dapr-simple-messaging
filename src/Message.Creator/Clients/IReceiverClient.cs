namespace Message.Creator.Clients
{
    public interface IReceiverClient
    {
        
        Task<MessageResponse> PublishMessageAsync(DeviceMessage message);

        Task<MessageResponse> InvokeMessageAsync(DeviceMessage message);
    }
}