# Simple Dapr messaging using Azure Container Apps



High Level Architecture:
![](/architecture.png)


## Deploy Azure resources

```
PROJECT_NAME="reliaar2"
LOCATION="westeurope"

bash ./deploy-infra.sh $PROJECT_NAME $LOCATION

```

## Create config file
```
PROJECT_NAME="reliaar2"
bash ./create-config.sh $PROJECT_NAME
```

## Launch locally
- create azure resources by running infra script 
- create local config by running create config script or adjust environment variables in local.env accordingly
- launch debug and open http://localhost:5025

```
dapr run --app-id message-creator --components-path ../../components/ --app-port 5023 --dapr-http-port 3500  -- dotnet run --project .

dapr run --app-id message-receiver --components-path ../../components/ --app-port 5025 --dapr-http-port 3500  -- dotnet run --project .


{
    "specversion": "1.0",
    "type": "com.dapr.event.sent",
    "traceid": "00-56add4dd6bb08be96c23b2dc17465ab8-7ec5cbe8920fe992-01",
    "traceparent": "00-56add4dd6bb08be96c23b2dc17465ab8-7ec5cbe8920fe992-01",
    "data": {
        "headers": [
            {
                "key": "Content-Type",
                "value": [
                    "application/json; charset=utf-8"
                ]
            }
        ],
        "id": "17d9af8d-1cdf-40ca-9ab6-46ba6af45a3c"
    },
    "id": "17d9af8d-1cdf-40ca-9ab6-12",
    "datacontenttype": "application/json; charset=utf-8",
    "source": "message-creator",
    "topic": "messages",
    "pubsubname": "pubsub",
    "tracestate": ""
}

```


## Deploy Apps into Container Apps

```
PROJECT_NAME="reliabr2"
GITHUB_REPO_OWNER="denniszielke"
IMAGE_TAG="latest"

bash ./deploy-apps.sh $PROJECT_NAME $GITHUB_REPO_OWNER $IMAGE_TAG

```
