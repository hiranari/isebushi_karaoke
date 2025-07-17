# GitHub Branch Protection Setup Guide

This document explains how to set up branch protection rules to ensure that the CI workflow must pass before merging to the main branch.

## Setting up Branch Protection Rules

To configure branch protection for the main branch:

1. **Navigate to Repository Settings**
   - Go to your GitHub repository
   - Click on the "Settings" tab
   - Select "Branches" from the left sidebar

2. **Add Branch Protection Rule**
   - Click "Add rule" next to "Branch protection rules"
   - In "Branch name pattern", enter: `main`

3. **Configure Protection Settings**
   Enable the following options:
   
   - ✅ **Require a pull request before merging**
     - ✅ Require approvals (set to 1 or more as needed)
     - ✅ Dismiss stale PR approvals when new commits are pushed
     - ✅ Require review from code owners (if you have CODEOWNERS file)
   
   - ✅ **Require status checks to pass before merging**
     - ✅ Require branches to be up to date before merging
     - Add required status checks:
       - `build-and-test (3.8)` - Python 3.8 CI job
       - `build-and-test (3.9)` - Python 3.9 CI job
       - `build-and-test (3.10)` - Python 3.10 CI job
       - `build-and-test (3.11)` - Python 3.11 CI job
   
   - ✅ **Require conversation resolution before merging**
   
   - ✅ **Restrict pushes that create files**
   
   - ✅ **Do not allow bypassing the above settings**

4. **Save Changes**
   - Click "Create" to save the branch protection rule

## What This Achieves

With these settings:
- Direct pushes to main branch are blocked
- All changes must go through pull requests
- The CI workflow must pass on all Python versions before merging
- Pull requests must be reviewed and approved
- All conversations must be resolved

## CI Workflow Status Checks

The CI workflow (`ci.yml`) will create the following status checks:
- `build-and-test (3.8)` - Tests Python 3.8 compatibility
- `build-and-test (3.9)` - Tests Python 3.9 compatibility
- `build-and-test (3.10)` - Tests Python 3.10 compatibility
- `build-and-test (3.11)` - Tests Python 3.11 compatibility

All of these must pass before merging is allowed.

## Testing the Setup

1. Create a new branch
2. Make changes to Python files
3. Create a pull request to main
4. Verify that the CI workflow runs automatically
5. Confirm that merge is blocked until all checks pass