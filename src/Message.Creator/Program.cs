using System.Reflection;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http.Json;
using Message.Creator.Clients;
using Microsoft.Extensions.FileProviders;
using OpenTelemetry.Exporter;
using OpenTelemetry.Instrumentation.AspNetCore;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Message.Creator;

var builder = WebApplication.CreateBuilder(args);

var assemblyVersion = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "unknown";

builder.Configuration.AddJsonFile("appsettings.json").AddEnvironmentVariables();
const string serviceName = "message-creator";

builder.Services.AddSingleton<MessageMetrics>();

var otel = builder.Services.AddOpenTelemetry();

// Configure OpenTelemetry Resources with the application name
otel.ConfigureResource(resource => resource
    .AddService(serviceName: builder.Environment.ApplicationName));

builder.Logging.ClearProviders();
builder.Logging.AddOpenTelemetry(options =>
{
    options.AddOtlpExporter();
    options.AddConsoleExporter();        
});

otel.WithMetrics(metrics => metrics
    // Metrics provider from OpenTelemetry
    .AddAspNetCoreInstrumentation()
    // Metrics provides by ASP.NET Core in .NET 8
    .AddMeter("Microsoft.AspNetCore.Hosting")
    .AddMeter("Microsoft.AspNetCore.Server.Kestrel")
    .AddMeter("System.Net.Http")
    .AddOtlpExporter()
    .AddPrometheusExporter());

// Add Tracing for ASP.NET Core and our custom ActivitySource and export to Jaeger
otel.WithTracing(tracing =>
{
    tracing.AddAspNetCoreInstrumentation();
    tracing.AddHttpClientInstrumentation();
    tracing.AddOtlpExporter();
    // tracing.AddConsoleExporter();
});

Action<ResourceBuilder> configureResource = r => r.AddService(
    serviceName, serviceVersion: assemblyVersion, serviceInstanceId: Environment.MachineName);

builder.Services.AddHealthChecks();

builder.Services.AddControllers(options =>
{
    options.RespectBrowserAcceptHeader = true;
});

builder.Services.Configure<JsonOptions>(options =>
{
    options.SerializerOptions.PropertyNameCaseInsensitive = true;
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    options.SerializerOptions.WriteIndented = true;
});

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("DAPR_HTTP_PORT")))
{
    Console.WriteLine("No Dapr.");
    builder.Services.AddSingleton<IReceiverClient, ReceiverHttpClient>();
    builder.Services.AddHttpClient("ReceiverHttpClient", client =>
    {
        client.BaseAddress = new Uri("http://localhost:5025");
    });
}else
{
    Console.WriteLine("Found Dapr.");
    builder.Services.AddSingleton<IReceiverClient, ReceiverDaprClient>();
    builder.Services.AddHttpClient("ReceiverDaprClient", client =>
    {
        client.BaseAddress = new Uri("http://localhost:" + (Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500"));
    });
}

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapHealthChecks("/healthz");
app.MapControllers();
app.MapPrometheusScrapingEndpoint();

app.UseStaticFiles();
var options = new DefaultFilesOptions();
options.DefaultFileNames.Clear();
options.DefaultFileNames.Add("index.html");
app.UseDefaultFiles(options);

app.Run();
