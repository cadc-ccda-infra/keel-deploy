{{/*
Expand the name of the chart.
*/}}
{{- define "argus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "argus.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "argus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "argus.labels" -}}
helm.sh/chart: {{ include "argus.chart" . }}
{{ include "argus.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "argus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "argus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "argus.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "argus.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Platform settings shared across the sc2 stack (global.* from parent chart or values).
Per-service application.* may override for standalone installs or exceptions.
*/}}
{{- define "argus.publicHostname" -}}
{{- if .Values.ingress.enabled -}}
{{- with (first .Values.ingress.hosts) -}}
{{- .host -}}
{{- end -}}
{{- else if .Values.httpRoute.enabled -}}
{{- with (first .Values.httpRoute.hostnames) -}}
{{- . -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "argus.platform.proxyPort" -}}
{{- coalesce .Values.application.proxyPort .Values.global.proxyPort 443 -}}
{{- end }}

{{- define "argus.platform.gmsId" -}}
{{- coalesce .Values.application.gmsId .Values.global.gmsId -}}
{{- end }}

{{- define "argus.platform.cdpId" -}}
{{- coalesce .Values.application.cdpId .Values.global.cdpId -}}
{{- end }}

{{- define "argus.platform.identityManager" -}}
{{- $a := .Values.application.auth | default dict -}}
{{- $g := .Values.global.auth | default dict -}}
{{- coalesce $a.identityManager $g.identityManager "ca.nrc.cadc.ac.ACIdentityManager" -}}
{{- end }}

{{- define "argus.platform.enableClientCertHeader" -}}
{{- $a := .Values.application.auth | default dict -}}
{{- $g := .Values.global.auth | default dict -}}
{{- coalesce $a.enableClientCertHeader $g.enableClientCertHeader true -}}
{{- end }}

{{- define "argus.platform.cookieSecretName" -}}
{{- $g := (.Values.global.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- $a := (.Values.application.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- coalesce $a.name $g.name -}}
{{- end }}

{{- define "argus.platform.cookieSecretKey" -}}
{{- $g := (.Values.global.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- $a := (.Values.application.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- coalesce $a.key $g.key "RsaSignaturePub.key" -}}
{{- end }}

{{- define "argus.platform.cookieSecretPath" -}}
{{- $g := (.Values.global.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- $a := (.Values.application.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- coalesce $a.path $g.path "RsaSignaturePub.key" -}}
{{- end }}
