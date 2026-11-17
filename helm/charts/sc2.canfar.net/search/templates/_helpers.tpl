{{/*
Expand the name of the chart.
*/}}
{{- define "search.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "search.fullname" -}}
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
{{- define "search.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "search.labels" -}}
helm.sh/chart: {{ include "search.chart" . }}
{{ include "search.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "search.selectorLabels" -}}
app.kubernetes.io/name: {{ include "search.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "search.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "search.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "search.publicHostname" -}}
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

{{- define "search.platform.proxyPort" -}}
{{- coalesce .Values.application.proxyPort .Values.global.proxyPort 443 -}}
{{- end }}

{{- define "search.platform.gmsId" -}}
{{- coalesce .Values.application.gmsId .Values.global.gmsId -}}
{{- end }}

{{- define "search.platform.cdpId" -}}
{{- coalesce .Values.application.cdpId .Values.global.cdpId -}}
{{- end }}

{{- define "search.platform.identityManager" -}}
{{- $a := .Values.application.auth | default dict -}}
{{- $g := .Values.global.auth | default dict -}}
{{- coalesce $a.identityManager $g.identityManager "ca.nrc.cadc.ac.ACIdentityManager" -}}
{{- end }}

{{- define "search.platform.enableClientCertHeader" -}}
{{- $a := .Values.application.auth | default dict -}}
{{- $g := .Values.global.auth | default dict -}}
{{- coalesce $a.enableClientCertHeader $g.enableClientCertHeader true -}}
{{- end }}

{{- define "search.platform.cookieSecretName" -}}
{{- $g := (.Values.global.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- $a := (.Values.application.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- coalesce $a.name $g.name -}}
{{- end }}

{{- define "search.platform.cookieSecretKey" -}}
{{- $g := (.Values.global.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- $a := (.Values.application.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- coalesce $a.key $g.key "RsaSignaturePub.key" -}}
{{- end }}

{{- define "search.platform.cookieSecretPath" -}}
{{- $g := (.Values.global.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- $a := (.Values.application.cookieSignaturePublicKey | default dict).existingSecret | default dict -}}
{{- coalesce $a.path $g.path "RsaSignaturePub.key" -}}
{{- end }}

{{- define "search.platform.clientCertSecretName" -}}
{{- $ref := (.Values.application.clientCertificates | default dict).existingSecret | default dict -}}
{{- $ref.name | default "" -}}
{{- end }}
