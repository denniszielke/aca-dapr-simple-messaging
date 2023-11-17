FROM mcr.microsoft.com/dotnet/sdk:7.0-alpine AS build
ARG BUILD_TAG=default
WORKDIR /source

# copy csproj and restore as distinct layers
COPY . .
RUN dotnet restore

RUN dotnet publish -c release -o /app --self-contained false --no-restore

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:7.0-alpine
WORKDIR /app
COPY --from=build /app ./
ENV VERSION=$BUILD_TAG
ENV OTEL_DOTNET_AUTO_METRICS_ADDITIONAL_SOURCES="Message.Receiver"
ENTRYPOINT ["dotnet", "Message.Receiver.dll"]