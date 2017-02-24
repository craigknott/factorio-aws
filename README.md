# Headless Factorio Server Running in AWS

This repo will deploy a headless server running in AWS for [Factorio][factorio].

After setup, running the deploy will create:

* A VPC
* Public subnets
* An internet gateway with a simple default route
* Security groups
* EFS volumes and mount targets
* SSH Keypairs
* AMIs from base Ubuntu Trusty
* EC2 instance
* Route53 records (if `route53_zone` is provided)

I couldn't get autoscaling groups to work with route53, so I decided to create
the instance directly.

## Setup

Before changes can be deployed to your infrastructure, you'll need to setup a few variables. Edit `terraform.tfvars.sample` and populate or change necessary variables:

### Variables

| Variable | Type | Explanation | Default | Required |
|----------|------|-------------|:-------:|:--------:|
| `name` | `string` | Base name for all components created. Some components well append aditional strings, such as "factorio-public" for a public subnet. | "factorio" | yes | 
| `region` | `string` | AWS region in which to create components. |  | yes |
| `tags` | `map[string]string` | Map of strings to strings. Tags to apply to components as key-value pairs. Note that the "Name" tag will be based on the `name` variable and will be overridden. | `{"source": "terraform"}` | yes |
| `aws_access_key` | `string` | AWS access key. More on this [below](#iam-setup). |  | No |
| `aws_secret_key` | `string` | AWS secret access key. More on this [below](#iam-setup). |  | No |
| `vpc_cidr` | `string` | The address space that the VPC will contain. If you're not sure, leave the default. | "10.0.0.0/16" | Yes |
| `domain_name` | `string` | Domain name suffix to provide for DHCP. |  | No |
| `domain_name_servers` | `[]string` | A list of DNS server IPs to provide for DHCP. |  | No |
| `ntp_servers` | `[]string` | A list of NTP servers to provide for DHCP. |  | No |
| `ssh_key` | `string` | Public key that will be granted SSH access to EC2 instance |  | Yes |
| `route53_zone` | `string` | A Route53 zone in which to create an A record for `name` pointing to the instance. | | No |

Once all variables have been configured, save the file as `terraform.tfvars`.

## Deployment

To see the object to be created, run:

```
terraform plan
```

To deploy:

```
terraform apply
```

For more information on Terraform, read its [documentation][terraform].

## IAM Setup

Credentials are not necessarily required. If not provided as a static variable, the values will be empty strings, so the AWS provider will look for credentials elsewhere. See the [provider documentation][aws provider] about how credentials are resolved.

If you're able to run the [AWS CLI][aws cli], you should be able to run Terraform without providing static credentials.

### Policy (TODO)

## Contributing

I'm happy to accept contributions. Feel free to send me a pull request or just file an issue. Please be mindful to not include your credentials. I don't want them.

**Disclaimer:** *I am in no way affiliated with [Factorio][factorio] and this work is only meant for educational purposes. This project does not purport to have any guarantees whatsoever. It should be considered "as-is" with no implications of responsibility. See included [LICENSE][license] for more details.*

[factorio]: https://www.factorio.com/
[terraform]: https://www.terraform.io/
[license]: ../master/LICENSE
[aws provider]: https://www.terraform.io/docs/providers/aws/
[aws cli]: https://aws.amazon.com/cli/
