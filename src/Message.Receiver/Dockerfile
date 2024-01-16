FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
ARG BUILD_TAG=default
WORKDIR /App

# copy csproj and restore as distinct layers
COPY . ./
RUN dotnet restore

RUN dotnet publish -c release -o out --self-contained false --no-restore

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine
WORKDIR /App
COPY --from=build-env /App/out .
ENV VERSION=$BUILD_TAG
ENV OTEL_DOTNET_AUTO_METRICS_ADDITIONAL_SOURCES="Message.Receiver"
ENTRYPOINT ["dotnet", "Message.Receiver.dll"]