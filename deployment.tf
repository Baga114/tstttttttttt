resource "kubectl_manifest" "nginx" {
  yaml_body  = <<-EOT
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx
            ports:
            - containerPort: 80
  EOT
  depends_on = [aws_eks_node_group.demo]
}

resource "kubectl_manifest" "nginx_service" {
  yaml_body  = <<-EOT
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-service
      labels:
        app: nginx
    spec:
      type: ClusterIP
      selector:
        app: nginx
      ports:
        - protocol: TCP
          port: 80
          targetPort: 80
  EOT
  depends_on = [kubectl_manifest.nginx]
}

resource "kubectl_manifest" "nginx_ingress" {
  yaml_body  = <<-EOT
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: nginx-ingress
      annotations:
        nginx.ingress.kubernetes.io/rewrite-target: /
    spec:
      ingressClassName: alb
      rules:
      - host: nginx.example.com
        http:
          paths:
          - path: /nginx
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  name: http
  EOT
  depends_on = [kubectl_manifest.nginx_service]
}
