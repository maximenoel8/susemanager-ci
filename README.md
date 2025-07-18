# susemanager-ci

CI automation for [SUSE Multi-Linux Manager](https://www.suse.com/products/multi-linux-manager/) and [Uyuni](https://www.uyuni-project.org/).

## Contents

- [jenkins_pipelines](jenkins_pipelines): Jenkins pipeline definitions
- [terracumber_config](terracumber_config): Configuration files for terracumber, used by some of the Jenkins pipelines

### Jenkins pipeline definitions

This directory contains the Jenkins pipelines we use in Jenkins.

For details have look at [jenkins_pipelines/README.md](jenkins_pipelines/README.md).

### Configuration files for terracumber

This directory contains the configuration files for terracumber that are used by the test suite and the reference
environment pipelines.

For details have a look at [terracumber_config/README.md](terracumber_config/README.md).

### Mirroring hell at Pull Request testing

Downloading images and packages from download.opensuse.org is not reliable because when you try to do so, you get
redirected to the openSUSE mirror infrastructure. This means:

- You do not always get the same mirror. If you download from Provo, you use the mirror in Provo. If you download from
your workstation, you download from the mirror that is closest to you.
- It takes an uncertain amount of time for an image or package to be available in all the mirrors. Thus, if you try to
download an image or package that was just built in the build service, you won't find that in the mirrors, yet.
- If the image or package has not changed its name, mirrors do not update that file. For example, if you have images
without the build number, which is very convenient to have (aka static links), new builds of the image are not
propagated to the mirrors. The same happens for RPMs, for example, if you remove a project and create it again,
the build number is going to reset and then you can easily have an RPM that has the same build number as before,
meaning the filename is the same and so the mirror will not get updated.
- Sometimes metadata and RPMs do not match. If you hit an "update window time", it could be that the metadata has been
updated on that mirror but it has not finished downloading the RPM.
- Even zypper has some code to manage metalinks, terraform libvirt does not, so if an image is not found close to your
location, it is not found at all.

For all that, we had to skip all the openSUSE mirror infrastructure and provide alternative links.

For Pull Requests we have these alternative URLs:

- http://jenkins-worker-prs.mgr.prv.suse.net/workspace/suma-prX/repos/: For every environment, there is a list of repos
that are needed for testing a particular Pull Request. This includes the master repo, the pull request repo, the client
repos and some other repos that are also needed. All those repos are synced using the Build Service API, instead of from
download.opensuse.org.
- http://minima-mirror-ci-bv.mgr.prv.suse.net/pull-request-repositories/dummy/ : This is an empty repo used instead of the update repos. This way,
the build is reproducible.
- http://minima-mirror-ci-bv.mgr.prv.suse.net/repositories/systemsmanagement:/sumaform:/images:/libvirt/images/. openSUSE
image for testing Pull Requests built with the open build service. This needs to be copied manually.
- http://minima-mirror-ci-bv.mgr.prv.suse.net/distribution/leap/: oss and non-oss repositories.

## Used image versions in the CI test suite

|             | PR test       | Uyuni         | HEAD         | 5.1          | 5.0           | 4.3          |
|-------------|---------------|---------------|--------------|--------------|---------------|--------------|
| Minion      | Leap 15.6     | Leap 15.6     | SLES 15 SP4  | SLES 15 SP4  | SLES 15 SP4   | SLES 15 SP4  |
| SSH minion  | Leap 15.6     | Leap 15.6     | SLES 15 SP4  | SLES 15 SP4  | SLES 15 SP4   | SLES 15 SP4  |
| Client      | -             | -             | -            | -            | -             | SLES 15 SP4  |
| RH-like     | Rocky 8       | Rocky 8       | Rocky 8      | Rocky 8      | Rocky 8       | Rocky 8      |
| Deb-like    | Ubuntu 24.04  | Ubuntu 24.04  | Ubuntu 24.04 | Ubuntu 24.04 | Ubuntu 24.04  | Ubuntu 22.04 |
| Virthost    | -             | -             | -            | -            | SLES 15 SP4   | SLES 15 SP4  |
| Buildhost   | SLES 15 SP4   | SLES 15 SP4   | SLES 15 SP4  | SLES 15 SP4  | SLES 15 SP4   | SLES 15 SP4  |
| Terminal    | SLES 15 SP4   | SLES 15 SP4   | SLES 15 SP4  | SLES 15 SP4  | SLES 15 SP4   | SLES 15 SP4  |
| DHCP-DNS    | Leap 15.5     | Leap 15.5     | Leap 15.5    | Leap 15.5    | Leap 15.5     | -            |
| Controller  | Leap 15.6     | Leap 15.5     | Leap 15.5    | Leap 15.5    | Leap 15.5     | Leap 15.5    |
| Server      | Leap 15.6     | Leap Micro 5.5| SL Micro 6.1 | SL Micro 6.1 | SLE Micro 5.5 | SLES 15 SP4  |
| Proxy       | Leap 15.6     | Leap Micro 5.5| SL Micro 6.1 | SL Micro 6.1 | SLE Micro 5.5 | SLES 15 SP4  |
