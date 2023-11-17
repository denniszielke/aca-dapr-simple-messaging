# Simple Dapr messaging using Azure Container Apps



High Level Architecture:
![](/architecture.png)


## Deploy Azure resources

```
PROJECT_NAME="dzotelac1"
LOCATION="eastus"

bash ./deploy-infra.sh $PROJECT_NAME $LOCATION

az containerapp job create \
    --name "my-job" --resource-group $PROJECT_NAME  --environment $PROJECT_NAME \
    --trigger-type "Schedule" \
    --replica-timeout 1800 --replica-retry-limit 0 --replica-completion-count 1 --parallelism 1 \
    --image "mcr.microsoft.com/k8se/quickstart-jobs:latest" \
    --cpu "0.25" --memory "0.5Gi" \
    --cron-expression "*/1 * * * *" --workload-profile-name d8

```

## Build containers using buildpacks

```
REGISTRY_NAME="dimages"
az acr login --name $REGISTRY_NAME

az containerapp up --name message-receiver \
  --location $LOCATION \
  --environment $PROJECT_NAME \
  -g $PROJECT_NAME \
  --registry-server $REGISTRY_NAME.azurecr.io \
  --ingress external \
  --target-port 8080 \
  --source ./src/Message.Receiver

```

## Create config file
```
PROJECT_NAME="dzaca27"
bash ./create-config.sh $PROJECT_NAME
```

## Launch locally without Dapr
- create azure resources by running infra script 
- create local config by running create config script or adjust environment variables in local.env accordingly
- launch debug and open http://localhost:5025


## Launch locally with Dapr

```
cd src/Message.Creator
dapr run --app-id message-creator --components-path ../../components/ --app-port 5023 --dapr-http-port 3500  -- dotnet run --project .
```

```
cd src/Message.Receiver
dapr run --app-id message-receiver --resources-path ../../components/ --app-port 5025 --dapr-http-port 3501  -- dotnet run --project .
```

```
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
    "pubsubname": "publisher",
    "tracestate": ""
}
```

## Submit new request via curl

DNS='message-creator.jollycliff-cb0f66cb.westeurope.azurecontainerapps.io'
HOST='10.0.16.27'

### Ping

```
-svk -ls --verbose -H 'Host: demo.greendune-d682b90f.westeurope.azurecontainerapps.io' http://10.0.5.11 --verbose
curl -svk -ls --verbose -X GET -H "Host: $DNS" -H 'Accept: application/json' -H 'Content-Type: application/json'  http://$HOST/getname
```

### Invoke/Publish Message
```

curl -svk -ls --verbose  -X POST -H "Host: $DNS" -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{ "id": "55", "temperature": "23", "humidity": "43", "name": "dennis", "message": "post invoke from dennis", "timestamp": "now"}' http://$HOST/publish

curl -svk -ls --verbose  -X POST -H "Host: $DNS" -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{ "id": "454", "temperature": "23", "humidity": "43", "name": "dennis", "message": "post publish from dennis", "timestamp": "now"}' http://$HOST/receive

```

## Deploy Apps into Container Apps

```
PROJECT_NAME="dzaca37"
GITHUB_REPO_OWNER="denniszielke"
IMAGE_TAG="latest"

bash ./deploy-apps.sh $PROJECT_NAME $GITHUB_REPO_OWNER $IMAGE_TAG

```


| Name | Display Name | Category | Cores | memoryGiB | Comments |
|:--|:--|:--|--:|--:|:--|
| `D4` | Dedicated-D4 | General Purpose | 4 | 16 | |
| `D8` | Dedicated-D8 | General Purpose | 8 | 32 | |
| `D16` | Dedicated-D16 | General Purpose | 16 | 64 | |
| `E4` | Dedicated-E4 | Memory Optimized | 4 | 32 | |
| `E8` | Dedicated-E8 | Memory Optimized | 8 | 64 | |
| `E16` | Dedicated-E16 | Memory Optimized | 16 | 128 | |
| `F4` |  Dedicated-F4 | Compute Optimized | 4 | 8 | |
| `F8` |  Dedicated-F8 | Compute Optimized | 8 | 16 | |
| `F16` |  Dedicated-F16 | Compute Optimized | 16 | 32 | |
| `Consumption` | Consumption | Consumption | 4 | 8 | |
