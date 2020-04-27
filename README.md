# GitSecrets

This repository describes an easy way to store your secrets encrypted in git. I believe that it is preferrable to store your secrets encrypted in git along with your application code for greater repeatability of builds. 

## Philosophy

We believe that secrets and config are code. This idea is based on foundations laid out by
[GitOps](https://www.weave.works/blog/gitops-operations-by-pull-request) and [Infrastructure As Code](https://martinfowler.com/bliki/InfrastructureAsCode.html).

The most important thing about including cofig/secrets as code is that every single
git commit is repeatable. This allows you to rollback to a previous version of your application with ease. It reduces the cognitive load on developers, since we no longer have to think about outside configuration when deploying applications.

## How it Works

1. Secrets are added encrypted to the GitHub repo using ejson-kms (a tool to store encrypted secrets using AWS KMS)
2. Secret decryption scripts are COPY'd into your Dockerfile. 
3. Your containers/nodes/ECS tasks are given the necessary permissions to decrypt secrets using AWS IAM Roles.
3. A Docker ENTRYPOINT is added to run the secret decryption script on container boot. 


## Quick Start

### 0. Install ejson-kms

See [installation](https://github.com/adrienkohlbecker/ejson-kms#installation)

### 1. Add new secrets file

```
ejson-kms init --kms-key-id="your-kms-key-id"
```

### 2. Add encrypted secrets to Dockerfile

```
COPY _infra/secrets/ /opt/_infra/secrets/
```

NOTE: the decrypt.sh file expects secrets to be at _infra/secrets or /opt/_infra/secrets in the Docker image.

### 3. Add secret install and secret decrypt script to Dockerfile

```
# EJSON-KMS Install
ADD scripts/install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh && /tmp/install.sh && rm /tmp/install.sh

# Secret Decryption
ADD scripts/decrypt.sh /usr/local/bin/decrypt
RUN chmod +x /usr/local/bin/decrypt
```

### 4. Add Docker entrypoint

```
ENTRYPOINT  ["./entrypoint.sh"]
```

The `entrypoint.sh` file should look like this. 

```
#!/usr/bin/env bash

# add secrets to current env
. decrypt

$CMD "$@"
```

And then use CMD directive in your Dockerfile to run your application.

```
CMD ["gunicorn", "app" ...]
```

### 5. Add IAM Role to your nodes/ECS tasks

Create an IAM role and attach it to your EC2 instance.

The IAM role should have a policy that includes the following

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:kms:us-east-1:AWSACCOUNTID:key/your-kms-key-id"
    }
  ]
}
```

This will allow the EC2 instance to decrypt secrets created by this KMS ID.

### 6. Success!

You should now have everything setup. You can store secrets encrypted in git and decrypt them at runtime in your application.

