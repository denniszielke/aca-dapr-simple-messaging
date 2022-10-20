using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http.Json;
using Message.Creator.Clients;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Extensions.FileProviders;

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

builder.Services.AddSingleton<ReceiverClient, ReceiverClient>();
builder.Services.AddSingleton<DaprReceiverClient, DaprReceiverClient>();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddHttpClient("Receiver", client =>
{
    client.BaseAddress = new Uri(builder.Configuration.GetValue<string>("RECEIVER_URL"));
});

builder.Services.AddHttpClient("DaprReceiver", client =>
{
    client.BaseAddress = new Uri("http://localhost:" + (Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500"));
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllers();

app.UseStaticFiles();
var options = new DefaultFilesOptions();
options.DefaultFileNames.Clear();
options.DefaultFileNames.Add("index.html");
app.UseDefaultFiles(options);

app.Run();
