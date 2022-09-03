# Deployment Frequency
A GitHub Action to roughly calculate DORA deployment frequency. This is not meant to be an exhaustive calculation, but we are able to fairly close for [insert analyzed percentage of scans]% of workflows. 

## Current alculation: 
- Get the last 100 workflows
- For each workflow, if it started in the last 30 days, and add it to a secondary filtered list - this is the number of deployments in the last 30 days
- With this filtered list, divide the count by the 30 days for a number of deployments per day
- Then translate this result to friendly n days/weeks/months. 

## Open questions
- what do to there are multiple workflows?
- need to inject PAT tokens to call private repos 

## Inputs:
- `workflows`: required, string, The name of the workflows to process. Multiple workflows can be separated by `,` (note that currently only the first workflow in the string is processed)
- `owner-repo`: optional, string, defaults to the repo where the action runs. Can target another owner or org and repo. e.g. `'samsmithnz/DevOpsMetrics'`
- `default-branch`: optional, string, defaults to `main` 
- `number-of-days`: optional, integer, defaults to `30` (days)

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
