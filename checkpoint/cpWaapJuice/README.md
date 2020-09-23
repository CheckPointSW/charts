# Helm Chart for Check Point WAAP

Helm charts provide the ability to deploy a collection of kubernetes services and containers with a single command. This wiki explains how to _**use a pre-configured helm chart**_ (for demo purposes) **OR** _**create your own helm chart**_, using the Check Point container images that are already integrated with the Check Point WAAP nano agent. If you want to integrate the Check Point WAAP nano agent with an ingress controller other than nginx, follow the instructions in the WAAP installation guide. The following describes the elements of the helm chart, how to create it using the Check Point WAAP nginx and cp-alpine containers.

## Choosing the deployment model

1.  Deploy the full container application stack that provides an ingress controller, ingress configuration and a predefined application (the juice-shop application) to demonstrate the WAAP capabilities into a _**CLEAN**_ K8s cluster.
2.  Deploy an nginx ingress controller with WAAP in front of an existing kubernetes application, additional configuration will be required to map ingress ports to the appropriate application ports.

Key Files (items in bold are customized.  All others may be provided in your existing kubernetes definitions)

*   _Chart.yaml_ - the basic definition of the helm chart being created. Includes helm chart type, version number, and application version number **_(may be modified if you customize the files below to reflect a different version)_**
*   _**values.yaml**_ \- the application values (variables) to be applied when installing the helm chart. In this case, the CP WAAP nano agent token ID, the image repository locations, the type of ingress service being used and the ports, and specific application specifications can be defined in this file. These values can be manually overridden when launching the helm chart from the command line as shown in the example below.
*   _templates/ingress-configmap.yaml_ \- configuration information for nginx.
*   _templates/ingress-crd.yaml_ - CustomResourceDefinitions for the ingress controller.
*   _templates/ingress-cr.yaml_ - specifications of the ClusterRole and ClusterRoleBinding role-based access control (rbac) components for the ingress controller.
*   _**ingress-deploy-nano.yaml**_ \- container specifications that pull the nginx image that contains the references to the CP Nano Agent and the CP Alpine image that includes the Nano Agent itself.
*   _templates/ingress.yaml_ - specification for the ingress settings for the application.
*   _templates/ingress-service.yaml_ - specifications for the ingress controller, e.g. LoadBalancer listening on port 80, forwarding to nodePort 30080 of the application _**(****may need to modified depending on your application)**_

## Clean Install, no existing ingress definitions or applications

### Requirements

*   Properly configured access to a K8s cluster (helm and kubectl working)
*   Helm 3.x installed
*   Access to a repository that contains the Check Point nginx controller and cp-alpine images
*   An account in portal.checkpoint.com with access to Infinity Next

If you need a kubernetes test environment, you can quickly create a kubernetes environment on GCP, Azure, or AWS. For GCP:
```
gcloud container clusters create juice-shop
```
For a quick install of Helm 3 on ubuntu:
```
curl https://helm.baltorepo.com/organization/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get install helm
```

### Steps to deploy

#### Define your application in the “Infinity Next” application of the Check Point Infinity Portal according the the CP WaaP instructions

The CloudGuard WAAP Deployment Guide section on WAAP Management provides instructions for this step.

#### Run Helm Commands

1.  Clone the git repo with the helm chart 
2.  Change branch to the gh-pages branch
3.  Install the helm chart
```
curl https://helm.baltorepo.com/organization/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get install helm
```

### Generating WaaP results and Testing the Application

Use kubectl to get the IP address of the ClusterIP
```
kubectl get all
```

Modify your host file to include the IP address of the last step pointing to juice-shop.checkpoint.com

Open a Firefox browser tab (Chrome redirects to https, which will not work in this case) and go to [http://juice-shop.checkpoint.com.](http://juice-shop.checkpoint.com.)

For the Juice-Shop application, Click on “Account” and select “Login”. In the username field, enter

Enter a password and click “Log In”. The error message displayed indicates the application was compromised.

Review the log files in the Infinity Portal to see the WaaP Results

## Adding CP WAAP on top of an existing k8s application (replacing the existing ingress controller)

Download the juice-chart helm file from the repository (an example is )

```
tar zxvf juice-chart-0.1.2.tgz
mv juice-chart {your-chart-name}
```

1.  Copy the files from the sample application into your directory structure
2.  Edit the Chart.yaml file to update the version number
3.  (Optional) Edit the values.yaml file to update your nanotoken value and the repository paths
4.  Remove the juice-shop.yaml file.
5.  Depending on your environment, you will need to edit the yaml files in the template directory to adjust the port numbers, application name, etc.

For example, if you already have an nginx ingress deployment defined,

*   *   in _**template/ingress-deploy-nano.yaml**_ file, modify the **metadata name**, and **selector:matchLabels** to match your application
    *   in _**template/ingress-service.yaml**_ file, modify the nodePort specification to match your environment (and possibly the selector:app)
    *   you may possibly reuse your _**template/ingress.yaml**_ file, but confirm the **host, serviceName**, and **servicePort** to match your existing application (replace referenced to "juice")

Once you have confirmed the configuration of  your yaml files, rebuild the helm chart. In the parent directory of the juice-chart directory:
```
helm package {your-chart-name}
```
To run the helm chart:
```
helm install {your-app-name} {your-chart-name.tgz} --set nanoToken="{your very long token string here}"
```
## Clean-up

```
helm delete {your-app-name}
```

* * *

[\[1\]](file:///C:/Users/mnichols/Dropbox/CheckPoint/WAAP/WAAP-Lab-Instructions-v1.htm#_ftnref2) Ingress Controllers and Ingress Resources

Kubernetes supports a high-level abstraction called [_Ingress_](https://kubernetes.io/docs/concepts/services-networking/ingress/), which allows simple host or URL based HTTP routing. An ingress is a core concept (in beta) of Kubernetes, but is always implemented by a third party proxy. These implementations are known as ingress controllers. An ingress controller is responsible for reading the Ingress Resource information and processing that data accordingly. Different ingress controllers have extended the specification in different ways to support additional use cases.

Ingress is tightly integrated into Kubernetes, meaning that your existing workflows around kubectl will likely extend nicely to managing ingress. Note that an ingress controller typically does not eliminate the need for an external load balancer — the ingress controller simply adds an additional layer of routing and control behind the load balancer.
Check Point Demo of Juice Shop with CP WAAP enabled
