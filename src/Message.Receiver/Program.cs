using System.Reflection;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http.Json;
using OpenTelemetry.Exporter;
using OpenTelemetry.Instrumentation.AspNetCore;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);

var assemblyVersion = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "unknown";

builder.Configuration.AddJsonFile("appsettings.json").AddEnvironmentVariables();

const string serviceName = "message-receiver";

builder.Logging.ClearProviders();

builder.Logging.AddOpenTelemetry(options =>
{
    options.AddOtlpExporter();
    options.AddConsoleExporter();        
});

// builder.Logging.AddOpenTelemetry(options =>
// {
//     options
//         .SetResourceBuilder(
//             ResourceBuilder.CreateDefault()
//                 .AddService(serviceName))
//         .AddConsoleExporter();
// });
builder.Services.AddOpenTelemetry()
      .ConfigureResource(resource => resource.AddService(serviceName))
      .WithTracing(tracing => tracing
          .AddHttpClientInstrumentation()
          .AddAspNetCoreInstrumentation()
          .AddConsoleExporter()
          .AddOtlpExporter())
      .WithMetrics(metrics => metrics
          .AddAspNetCoreInstrumentation()
          .AddConsoleExporter()
          .AddOtlpExporter());

builder.Services.AddHealthChecks();

builder.Services.AddControllers(options =>
{
    options.RespectBrowserAcceptHeader = true;
});

builder.Services.AddLogging(config =>
{
    config.AddDebug();
    config.AddConsole();
    config.AddOpenTelemetry(options =>
    {
        options.IncludeScopes = true;
        options.ParseStateValues = true;
        options.IncludeFormattedMessage = true;
    });
});

builder.Services.Configure<JsonOptions>(options =>
{
    options.SerializerOptions.PropertyNameCaseInsensitive = true;
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    options.SerializerOptions.WriteIndented = true;
});

var app = builder.Build();

app.MapGet("/", () => {
    return Results.Ok("Hi!");
});

app.MapHealthChecks("/healthz");

app.MapGet("/", () => {
    return Results.Ok("Hi!");
});

app.MapGet("/ping", () => {
    Console.WriteLine("Received ping.");
    return Results.Ok("Pong!");
});

app.MapGet("/dapr/subscribe", () => {
    var sub = new DaprSubscription(PubsubName: "receiver", Topic: "messages", Route: "receive");
    Console.WriteLine("Dapr pub/sub is subscribed to: " + sub);
    return Results.Json(new DaprSubscription[]{sub});
});

app.MapPost("/receive", (DaprData<DeviceMessage> requestData) => {
    Console.WriteLine("Subscriber received : " + requestData.Id);
    return Results.Ok(requestData.Data);
});

app.MapPost("/invoke", (DeviceMessage requestData) => {
    Console.WriteLine("Invoke received : " + requestData.Id);
    return Results.Ok(requestData);
});

app.Run();

public record DaprData<T> ([property: JsonPropertyName("data")] T Data, [property: JsonPropertyName("id")] string Id); 
public record DaprSubscription(
  [property: JsonPropertyName("pubsubname")] string PubsubName, 
  [property: JsonPropertyName("topic")] string Topic, 
  [property: JsonPropertyName("route")] string Route);
