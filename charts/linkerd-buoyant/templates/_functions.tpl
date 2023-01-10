{{- define "installed-linkerd-namespace" -}}
{{ $metadata := (lookup "admissionregistration.k8s.io/v1" "MutatingWebhookConfiguration" "" "linkerd-proxy-injector-webhook-config").metadata -}}
{{ if not (empty $metadata) -}}
  {{ range $k, $v := $metadata.labels -}}
    {{ if eq $k "linkerd.io/control-plane-ns" -}}
      {{ $v -}}
    {{ end -}}
  {{ end -}}
{{ end -}}
{{ end -}}

{{- define "installed-linkerd-cli" -}}
{{ $metadata := (lookup "admissionregistration.k8s.io/v1" "MutatingWebhookConfiguration" "" "linkerd-proxy-injector-webhook-config").metadata -}}
{{ if not (empty $metadata) -}}
  {{ $helm := false -}}
  {{ range $k, $v := $metadata.labels -}}
    {{ if and (eq $k "app.kubernetes.io/managed-by") (eq $v "Helm") -}}
      {{ $helm = true -}}
    {{ end -}}
  {{ end -}}
  {{ if not $helm -}}
    true
  {{ end -}}
{{ end -}}
{{ end -}}

{{- define "install-operator" -}}
{{ $installedLinkerdCLI := include "installed-linkerd-cli" . -}}
{{ $installedLinkerd29 := include "linkerd-2-9" . -}}
{{ if and .Values.managed (empty $installedLinkerdCLI) (empty $installedLinkerd29) -}}
  true
{{ end -}}
{{ end -}}

{{- define "linkerd-release-name" -}}
{{ $metadata := (lookup "admissionregistration.k8s.io/v1" "MutatingWebhookConfiguration" "" "linkerd-proxy-injector-webhook-config").metadata -}}
{{ if empty $metadata -}}
  linkerd-control-plane
{{- else -}}
  {{ range $k, $v := $metadata.annotations -}}
    {{ if eq $k "meta.helm.sh/release-name" -}}
      {{ $v -}}
    {{ end -}}
  {{ end -}}
{{ end -}}
{{ end -}}

{{- define "exists-linkerd-namespace" -}}
{{ if not (empty (lookup "v1" "Namespace" "" .Values.linkerd.namespace)) -}}
  true
{{ end -}}
{{ end -}}

{{- define "exists-linkerd-jaeger-namespace" -}}
{{ if not (empty (lookup "v1" "Namespace" "" .Values.linkerdJaeger.namespace)) -}}
  true
{{ end -}}
{{ end -}}

{{- define "check-linkerd" -}}
{{ $ns := include "installed-linkerd-namespace" . -}}
{{ if and (not (empty $ns)) (not (eq $ns .Values.linkerd.namespace)) -}}
  {{- fail (printf "*** Linkerd was found to be installed in the '%s' namespace; please set linkerd.namespace to that value ***" $ns) }}
{{ end -}}
{{ end -}}

{{- define "check-linkerd-jaeger" -}}
{{ if and .Values.linkerdJaeger.enabled (empty (include "exists-linkerd-jaeger-namespace" .)) -}}
  {{- fail (printf "*** Linkerd-jaeger wasn't found under the '%s' namespace; please install the extension under that namespace, modify linkerdJaeger.namespace, or set linkerdJaeger.enabled to false ***" .Values.linkerdJaeger.namespace) }}
{{ end -}}
{{ end -}}

{{- define "linkerd-version" -}}
{{ with (lookup "v1" "ConfigMap" .Values.linkerd.namespace "linkerd-config").data -}}
  {{ with (.values | fromYaml) -}}
    {{ if not (empty .linkerdVersion) -}}
      {{ .linkerdVersion -}}
    {{ else if and (not (empty .global)) (not (empty .global.linkerdVersion)) -}}
      {{ .global.linkerdVersion -}}
    {{ end -}}
  {{ end -}}
{{ end -}}
{{ end -}}

{{- define "requires-extendedRBAC" -}}
  {{ $version := include "linkerd-version" . -}}
  {{ if or (hasPrefix "stable-2.10" $version) (hasPrefix "stable-2.11" $version) -}}
    true
  {{ end -}}
{{ end -}}

{{- define "linkerd-2-9" -}}
  {{ $version := include "linkerd-version" . -}}
  {{ if hasPrefix "stable-2.9" $version -}}
    true
  {{ end -}}
{{ end -}}

{{- define "exists-org-credentials" -}}
  {{ if and (not (empty .Values.api.clientID)) (not (empty .Values.api.clientSecret)) -}}
    true
  {{ end -}}
{{ end -}}

{{- define "exists-org-credentials-secret" -}}
  {{ with (lookup "v1" "Secret" .Release.Namespace "buoyant-cloud-org-credentials").data -}}
    {{ if and (not (empty .client_id)) (not (empty .client_secret)) -}}
      true
    {{ end -}}
  {{ end -}}
{{ end -}}
