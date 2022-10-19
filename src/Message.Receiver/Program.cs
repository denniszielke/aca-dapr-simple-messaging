using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http.Json;
using Microsoft.ApplicationInsights.Extensibility;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.json").AddEnvironmentVariables();

builder.Services.AddControllers(options =>
{
    options.RespectBrowserAcceptHeader = true;
});

builder.Services.AddLogging(config =>
{
    config.AddDebug();
    config.AddConsole();
});

builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddSingleton<ITelemetryInitializer, CloudRoleNameTelemetryInitializer>();

builder.Services.Configure<JsonOptions>(options =>
{
    options.SerializerOptions.PropertyNameCaseInsensitive = true;
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    options.SerializerOptions.WriteIndented = true;
});

var app = builder.Build();

app.MapGet("/dapr/subscribe", () => {
    var sub = new DaprSubscription(PubsubName: "pubsub", Topic: "messages", Route: "receive");
    Console.WriteLine("Dapr pub/sub is subscribed to: " + sub);
    return Results.Json(new DaprSubscription[]{sub});
});

app.MapPost("/receive", (DaprData<DeviceMessage> requestData) => {
    Console.WriteLine("Subscriber received : " + requestData.Id);
    return Results.Ok(requestData.Data);
});

app.Run();

public record DaprData<T> ([property: JsonPropertyName("data")] T Data, [property: JsonPropertyName("id")] string Id); 
public record DaprSubscription(
  [property: JsonPropertyName("pubsubname")] string PubsubName, 
  [property: JsonPropertyName("topic")] string Topic, 
  [property: JsonPropertyName("route")] string Route);
