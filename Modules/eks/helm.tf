#====================================================================
# HELM RELEASES FOR ISTIO & SUPPORTING COMPONENTS
# Note: Requires kubernetes and helm providers configured
#====================================================================

#====================================================================
# KUBERNETES NAMESPACES
#====================================================================

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"

    labels = {
      "istio-injection" = "disabled"
    }
  }

  depends_on = [aws_eks_node_group.system]
}

resource "kubernetes_namespace" "istio_ingress" {
  metadata {
    name = "istio-ingress"

    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [aws_eks_node_group.system]
}

resource "kubernetes_namespace" "istio_egress" {
  metadata {
    name = "istio-egress"

    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [aws_eks_node_group.system]
}

resource "kubernetes_namespace" "strapi" {
  metadata {
    name = "strapi"

    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [aws_eks_node_group.system]
}

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }

  depends_on = [aws_eks_node_group.system]
}

#====================================================================
# ISTIO BASE
#====================================================================

resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = var.istio_version
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  set {
    name  = "defaultRevision"
    value = "default"
  }

  depends_on = [
    kubernetes_namespace.istio_system,
    aws_eks_node_group.system
  ]
}

#====================================================================
# ISTIOD (Control Plane)
#====================================================================

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.istio_version
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  set {
    name  = "meshConfig.accessLogFile"
    value = "/dev/stdout"
  }

  set {
    name  = "meshConfig.enableTracing"
    value = "true"
  }

  set {
    name  = "meshConfig.defaultConfig.tracing.zipkin.address"
    value = "jaeger-collector.observability.svc.cluster.local:9411"
  }

  set {
    name  = "pilot.autoscaleEnabled"
    value = "true"
  }

  set {
    name  = "pilot.autoscaleMin"
    value = "2"
  }

  set {
    name  = "pilot.autoscaleMax"
    value = "5"
  }

  set {
    name  = "pilot.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "pilot.resources.requests.memory"
    value = "2Gi"
  }

  set {
    name  = "global.proxy.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "global.proxy.resources.requests.memory"
    value = "128Mi"
  }

  depends_on = [helm_release.istio_base]
}

#====================================================================
# ISTIO INGRESS GATEWAY
#====================================================================

resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.istio_version
  namespace  = kubernetes_namespace.istio_ingress.metadata[0].name

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "autoscaling.enabled"
    value = "true"
  }

  set {
    name  = "autoscaling.minReplicas"
    value = "2"
  }

  set {
    name  = "autoscaling.maxReplicas"
    value = "10"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.istio_ingress.arn
  }

  set {
    name  = "resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "labels.app"
    value = "istio-ingressgateway"
  }

  set {
    name  = "labels.istio"
    value = "ingressgateway"
  }

  depends_on = [helm_release.istiod]
}

#====================================================================
# ISTIO EGRESS GATEWAY
#====================================================================

resource "helm_release" "istio_egress" {
  name       = "istio-egressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.istio_version
  namespace  = kubernetes_namespace.istio_egress.metadata[0].name

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "autoscaling.enabled"
    value = "true"
  }

  set {
    name  = "autoscaling.minReplicas"
    value = "2"
  }

  set {
    name  = "autoscaling.maxReplicas"
    value = "5"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.istio_egress.arn
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "labels.app"
    value = "istio-egressgateway"
  }

  set {
    name  = "labels.istio"
    value = "egressgateway"
  }

  depends_on = [helm_release.istiod]
}

#====================================================================
# AWS LOAD BALANCER CONTROLLER
#====================================================================

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_eks_node_group.system
  ]
}

#====================================================================
# CLUSTER AUTOSCALER
#====================================================================

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.35.0"
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "awsRegion"
    value = data.aws_region.current.name
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler.arn
  }

  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }

  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_eks_node_group.system
  ]
}

#====================================================================
# EXTERNAL SECRETS OPERATOR
#====================================================================

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.11"
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_secrets.arn
  }

  depends_on = [
    kubernetes_namespace.external_secrets,
    aws_eks_node_group.system
  ]
}

#====================================================================
# METRICS SERVER
#====================================================================

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.0"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  depends_on = [aws_eks_node_group.system]
}