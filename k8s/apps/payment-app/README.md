eksctl create cluster --name effulgencetech-dev --region us-east-1 --nodegroup-name et-nodegroup --node-type t2.medium --nodes 2 --nodes-min 1 --nodes-max 3 --managed

eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster effulgencetech-dev --approve

curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.1/docs/install/iam_policy.json

aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

eksctl create iamserviceaccount --cluster effulgencetech-dev --namespace kube-system --name aws-load-balancer-controller --attach-policy-arn arn:aws:iam::651706774390:policy/AWSLoadBalancerControllerIAMPolicy --approve

helm repo add eks https://aws.github.io/eks-charts

helm repo update

aws eks update-kubeconfig --region us-east-1 --name effulgencetech-dev


helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system --set clusterName=effulgencetech-dev --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=us-east-1 --set vpcId=vpc-09cdcb2a6fe528c8e         # the vpc id shd be that created by the cluster

kubectl get deployment -n kube-system aws-load-balancer-controller

kubectl create namespace phone-store
kubectl apply -f web-deployment.yml
kubectl apply -f web-service.yml
kubectl apply -f ingress.yml

kubectl get pods -n phone-store

kubectl get ingress -n phone-store









