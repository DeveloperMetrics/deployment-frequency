# Deployment Frequency
What: A GitHub Action to roughly calculate DORA deployment frequency. This is not meant to be an exhaustive calculation, but we are able to fairly close for [insert analyzed percentage of scans]% of workflows.
Why: our [insights](https://samlearnsazure.blog/2022/08/23/my-insights-about-measuring-dora-devops-metrics-and-how-you-can-learn-from-my-mistakes/) showed that most applications don't need exhaustive DORA analysis - a high level, order of magnitude result is accurate for most workloads. 

## Current Calculation: 
- Get the last 100 workflows
- For each workflow, if it started in the last 30 days, and add it to a secondary filtered list - this is the number of deployments in the last 30 days
- With this filtered list, divide the count by the 30 days for a number of deployments per day
- Then translate this result to friendly n days/weeks/months. 
- As the cost is relatively low (1 Rest API call to GitHub), a result is typically returned in 5-10s.

## Current Limitations
- Only looks at the last 100 workflows. If deployments to the target branch is low, this will skew the result
- The elite rating can be manipulated, as it looks for 30 deployments within a month to be hit. A true elite rating would be spread throughout the month.

## Open questions
- what do to there are multiple workflows?

## Inputs:
- `workflows`: required, string, The name of the workflows to process. Multiple workflows can be separated by `,` (note that currently only the first workflow in the string is processed)
- `owner-repo`: optional, string, defaults to the repo where the action runs. Can target another owner or org and repo. e.g. `'samsmithnz/DevOpsMetrics'`, but will require authenication (see below)
- `default-branch`: optional, string, defaults to `main` 
- `number-of-days`: optional, integer, defaults to `30` (days)
- `patToken`: optional, string, defaults to ''. Can be set with GitHub PAT token. Ensure that `Read access to actions and metadata` permission is set. This is a secret, never directly add this into the actions workflow, use a secret.
- `actionsToken`: optional, string, defaults to ''. CAn be set with `${{ secrets.GITHUB_TOKEN }}` in the action

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
    patToken: "${{ secrets.PATTOKEN }}"
```

```
- name: Test this repo with GitHub Token
  uses: samsmithnz/deployment-frequency@main
  with:
    workflows: 'CI'
    actionsToken: "${{ secrets.GITHUB_TOKEN }}"
```
