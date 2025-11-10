# devops-task
DevOps Engineer Task

### Git-crypt Howto

This repository is using [git-crypt](https://www.agwa.name/projects/git-crypt/) to encrypt secrets within the repository itself.  Files described in the .gitattributes to use git-crypt filters are encrypted right before each commit and decrypted each time the repository is checked out.  To decrypt the repository one will need to obtain the **git-crypt-key** (at the moment of writing this documentation, the key is kept in 1Password DevOps shared vault).

Simply clone the repository and execute:
```Shell
# git-crypt unlock /path/to/git-crypt-key
```

### Dependencies

1. SSH key in github

2. Install `git` and `ansible`
```
apt update && apt upgrade -y
apt install -y git ansible
```

3. Clone this repo:
```
git clone git@github.com:Amirbekyan/devops-task.git
cd devops-task
```

4. Install prerequisites:
```
ansible-playbook -i localhost src/ansible-requirements.yml
```

5. Run Terraform code:
```
tofu init
tofu apply
```

6. 
```
ansible-playbook -i localhost src/ansible-docker-build.yml
```

7. add to `/etc/hosts`