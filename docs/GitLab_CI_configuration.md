# GitLab setup (obsolete - not used)

Few notes how to configure GitLab for `packer-templates` to build boxes for
Vagrant automatically every month.

* New Project -> CI/CD fir external repository -> GitHub
  * `ruzickap/packer-templates` -> Connect

* Settings
  * General -> Topics -> packer, virtualbox, vagrant, box, windows, ubuntu,
     centos, images
  * Repository -> Protected Branches -> `master` -> not protect
  * CI/CD
    * General pipelines
      * Timeout: 2d
      * Auto-cancel redundant, pending pipelines: uncheck
    * Variables
      * VAGRANTUP_ACCESS_TOKEN="y...g"

* CI/CD -> Schedules -> New schedule
  * Description: Monthly build
  * Interval Pattern: `0 1 1 * *`
  * Variables
    * VAGRANTUP_ACCESS_TOKEN="y...g"

## GitLab Runner registration

To register GitLab Runner - Ubuntu server where the build will be executed -
follow the guide.

Get the GitLab Runner registration token:

Settings -> CI/CD -> Runners -> Set up a specific Runner manually -> Copy the
code: `DxxxxxxxxxxxxxxxxxxU`

Use the [tools/build_remote_ssh_ubuntu.sh] script to automatically provision the
Ubuntu server.

You can also use the command directly when using already pre-configured server:

```bash
gitlab-runner register \
  --non-interactive \
  --tag-list packer-templates \
  --registration-token {{ GITLAB_REGISTRATION_TOKEN }} \
  --url https://gitlab.com/ \
  --executor shell
```
