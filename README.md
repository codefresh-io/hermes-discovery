# Hermes Discovery Service

Codefresh discovery for event providers.

## Description

Each event provider must have a configuration file that describes it.
This configuration file defines event, type and kind, `URI` template, service URL (populated during deployment), configuration fields, actions and filters (filter can be relevant to multiple/all actions).

### Example: Nomios

DockerHub event provider configuration (`JSON` with `Helm` template instructions)

```json
{
    "type": "registry",
    "kind": "dockerhub",
    "service-url": "http://{{ printf "%s-nomios" .Release.Name }}",
    "uri-template": "registry:dockerhub:{{"{{"}}namespace{{"}}"}}:{{"{{"}}name{{"}}"}}:{{"{{"}}action{{"}}"}}",
    "uri-regex": "^registry:dockerhub:[a-z0-9_-]+:[a-z0-9_-]+:push$",
    "help-url": "https://codefresh.io/docs/docs/pipeline-triggers/configure-dockerhub-trigger/",
    "config": [
        {
        "name": "namespace",
        "type": "string",
        "help": "Docker Hub user or organization name",
        "validator": "^[a-z0-9_-]+$",
        "required": true
        },
        {
        "name": "name",
        "type": "string",
        "help": "docker image name",
        "validator": "^[a-z0-9_-]+$",
        "required": true
        },
        {
        "name": "action",
        "type": "list",
        "help": "docker push command",
        "options": {
            "Push Image": "push"
        },
        "validator": "^(push)$",
        "required": true
        }
    ],
    "actions": [
        {
        "name": "push",
        "label": "Push Image",
        "help": "docker push command"
        }
    ],
    "filters": [
        {
        "name": "tag",
        "type": "string",
        "help": "RE2 regular expression",
        "validator": "^.+$",
        "actions": ["push"]
        }
    ]
}
```

## Flow

Event provider deployment (`helm` package) may include multiple Kubernetes resources (Deployment, Service, Ingress and others), but it must include one ConfigMap per event `type/kind`. 

### Convention

This ConfigMap should include event provider configuration `JSON` as `config.json` file and must be labeled with `discovery=event-provider` _Label_, additional (not yet used) labels are `type` and `kind`.

### Helm Template

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "nomios.fullname" . }}
  labels:
    app: {{ template "nomios.name" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
    type: {{ .Values.event.type }}
    kind: {{ .Values.event.kind }}
    discovery: "event-provider"
data:
  # DockerHub trigger type configuration
  config.json: |
  {{ (.Files.Glob "files/config.json").AsConfig | indent 4 }}
```

### Hermes Discovery

Hermes (trigger-manager) uses auto-generated `types_config.yaml` file that contains all deployed event providers.

There is a `post-install/post-upgrade` **helm hook**, that recreates `{{.Release.Name}}-hermes-types` ConfigMap with single `JSON` file in the following format:

```json
{
    "types": [
        {event provider #1 JSON},
        {event provider #2 JSON},
        ...
        {event provider #N JSON}
    ]
}
```

**Helm hook** is defined in [cf-helm](https://github.com/codefresh-io/cf-helm) project and uses [codefresh/hermes-discovery](https://hub.docker.com/r/codefresh/hermes-discovery/) image with `discovery.sh` script to recreate `{{.Release.Name}}-hermes-types` ConfigMap with `types_config.json` file, when Codefresh installed and upgraded.
