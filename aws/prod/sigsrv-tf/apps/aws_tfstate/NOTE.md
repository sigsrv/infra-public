## AWSPowerUserAccess 인라인 정책

[AWSPowerUserAccess](https://607292096646-7nq6udmr.ap-northeast-2.console.aws.amazon.com/singlesignon/organization/home?region=ap-northeast-2#/instances/7230fb4da3e74a19/permission-sets/details/ps-e51198d5062d5ed0?section=permissions) 권한 세트의 인라인 정책에 `TerraformStateRoleAccess` 권한이 부여되어 있다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateRoleAccess",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "arn:aws:iam::820242943905:role/sigsrv-infra-tfstate-*",
        "arn:aws:iam::820242943905:role/sigsrv-tfstate-*"
      ]
    }
  ]
}
```
