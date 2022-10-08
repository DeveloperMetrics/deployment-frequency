# Deployment Frequency
A GitHub Action to roughly calculate DORA deployment frequency. This is not meant to be an exhaustive calculation, but we are able to approximate fairly close for most  of workflows. Why? Our [insights](https://samlearnsazure.blog/2022/08/23/my-insights-about-measuring-dora-devops-metrics-and-how-you-can-learn-from-my-mistakes/) indicated that many applications don't need exhaustive DORA analysis - a high level, order of magnitude result is accurate for most workloads. 

[![CI](https://github.com/samsmithnz/deployment-frequency/actions/workflows/workflow.yml/badge.svg)](https://github.com/samsmithnz/deployment-frequency/actions/workflows/workflow.yml)
[![Current Release](https://img.shields.io/github/release/samsmithnz/deployment-frequency/all.svg)](https://github.com/samsmithnz/deployment-frequency/releases)

## Current Calculation
- Get the last 100 completed workflows
- For each workflow, if it started in the last 30 days, and add it to a secondary filtered list - this is the number of deployments in the last 30 days
- With this filtered list, divide the count by the 30 days for a number of deployments per day
- Then translate this result to friendly n days/weeks/months. 
- As the cost is relatively low (1 Rest API call to GitHub), a result is typically returned in 5-10s.

## Current Limitations
- Only looks at the last 100 completed workflows. If number of deployments to the target branch is low, this will skew the result. 

## Inputs
- `workflows`: required, string, The name of the workflows to process. Multiple workflows can be separated by `,` 
- `owner-repo`: optional, string, defaults to the repo where the action runs. Can target another owner or org and repo. e.g. `'samsmithnz/DevOpsMetrics'`, but will require authenication (see below)
- `default-branch`: optional, string, defaults to `main` 
- `number-of-days`: optional, integer, defaults to `30` (days)
- `pat-token`: optional, string, defaults to ''. Can be set with GitHub PAT token. Ensure that `Read access to actions and metadata` permission is set. This is a secret, never directly add this into the actions workflow, use a secret.
- `actions-token`: optional, string, defaults to ''. Can be set with `${{ secrets.GITHUB_TOKEN }}` in the action
- `app-id`: optional, string, defaults to '', application id of the registered GitHub app
- `app-install-id`: optional, string, defaults to '', id of the installed instance of the GitHub app
- `app-private-key`: optional, string, defaults to '', private key which has been generated for the installed instance of the GitHub app. Must be provided without leading `'-----BEGIN RSA PRIVATE KEY----- '` and trailing `' -----END RSA PRIVATE KEY-----'`.

To test the current repo (same as where the action runs)
```
- uses: samsmithnz/deployment-frequency@main
  with:
    workflows: 'CI'
```

To test another repo, with all arguments
```
- name: Test another repo
  uses: samsmithnz/deployment-frequency@main
  with:
    workflows: 'CI/CD'
    owner-repo: 'samsmithnz/DevOpsMetrics'
    default-branch: 'main'
    number-of-days: 30
```

To use a PAT token to access another (potentially private) repo:
```
- name: Test elite repo with PAT Token
  uses: samsmithnz/deployment-frequency@main
  with:
    workflows: 'CI/CD'
    owner-repo: 'samsmithnz/SamsFeatureFlags'
    pat-token: "${{ secrets.PATTOKEN }}"
```

Use the built in Actions GitHub Token to retrieve the metrix 
```
- name: Test this repo with GitHub Token
  uses: samsmithnz/deployment-frequency@main
  with:
    workflows: 'CI'
    actions-token: "${{ secrets.GITHUB_TOKEN }}"
```

Gather the metric from another repository using GitHub App authentication method:
```
- name: Test another repo with GitHub App
  uses: samsmithnz/deployment-frequency@main
  with:
    workflows: 'CI'
    owner-repo: 'samsmithnz/some-other-repo'
    app-id: "${{ secrets.APPID }}"
    app-install-id: "${{ secrets.APPINSTALLID }}"
    app-private-key: "${{ secrets.APPPRIVATEKEY }}"
```

# Output

Current output to the log shows the inputs, authenication method, rate limit consumption, and then the actual deployment frequency
```
Owner/Repo: samsmithnz/SamsFeatureFlags
Workflows: Feature Flags CI/CD
Branch: main
Number of days: 30
Authentication detected: GITHUB APP TOKEN
Rate limit consumption: 10 / 5000
Deployment frequency over last 30 days, is 1.2 per day, with a DORA rating of 'Elite'
```

In the job summary, we show a badge with details:
![image](https://user-images.githubusercontent.com/8389039/194720101-8fe50812-a721-46e7-b4ab-69f391aa496c.png)
