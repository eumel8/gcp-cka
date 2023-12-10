# gcp-cka

## abstract

This repo contains a lab to setup Kubernetes environment to learn for the [CKA](https://www.cncf.io/training/certification/cka/) with Terraform on Google Cloud. Basically two Virtual Machines are deployed within a private network.


## preparation

Register for the Google Cloud Platform (GCP) on https://cloud.google.com

Setup a project and connect to a billing account. Don't worry, we use Spot instances which are available for 1 ct per hour. You can flexible bootstrap this stack, learn 1-2 hours and have to pay less then 5 ct.

# deployment

We will use [Google Cloud Shell](https://shell.cloud.google.com), reachable from the [Console](https://console.cloud.google.com). This is a Virtual Machine, running in the background on GCP, accessable within your web browser with the complete installed environment like [GCP Terraform](https://cloud.google.com/docs/terraform/basic-commands?hl=de).

When you enter the Cloud Shell you need to set the ProjectId as environment (pick up from the Cloud Console), clone this repo and run terraform with the default settings:

```bash
export GOOGLE_CLOUD_PROJECT=k8s-test-246009
git clone https://github.com/eumel8/gcp-cka.git
cd gcp-cka
terraform plan
terraform apply
```

Some authorization window will appear and needs to accept and after this one VM will deployed as `master` node. Public ip-address will shown at the end and you can enter:

```bash
ssh -i cka_key cka@35.232.110.87
```

NOTE: this repository contains an ssh *example* key pair `cka_key`. you should create and use your own:

```
ssh-keygen -C cka -f cka_key
```

If you familar with the `master` node you can continue to deploy `node1` as worker or additional master:

```
terraform apply --var create_nodes=true
```

see [KUBEADM](KUBEADM.md) for usage this lab

