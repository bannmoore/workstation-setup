#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Manual Steps
# Install Docker: https://docs.docker.com/docker-for-mac/install/

# Settings
GITHUB_USERNAME=bannmoore
GITHUB_EMAIL=moore.brittanyann@gmail.com
NPM_AUTHOR="Brittany Moore<$GITHUB_USERNAME>"
COMPUTER_NAME=Ada
NODE_VERSION=12.4.0
ELIXIR_VERSION=1.9.0
RUBY_VERSION=2.6.3

# Helpers
brew_install() {
  echo "$1"
  if [[ $(brew list | grep $1) ]]; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade $1
  else
    HOMEBREW_NO_AUTO_UPDATE=1 brew install $1
  fi
}

# Setup
echo "# Setting up $COMPUTER_NAME for $(id -un)."

echo "## Checking shell..."
if [[ ! "$SHELL" == "/bin/zsh" ]]; then
  echo "### Setting shell to zsh."
  chsh -s /bin/zsh
else 
  echo "### Shell is already zsh."
fi

echo "## Setting computer name."
if [[ ! $(scutil --get ComputerName) == "$COMPUTER_NAME" ]]; then  
  scutil --set ComputerName $COMPUTER_NAME
fi

echo "## Changing mac settings"
echo "### cursor speed"
defaults write NSGlobalDomain KeyRepat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
echo "### accessibility UI mode"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo "## check .zshrc"
if [ ! -f ~/.zshrc ]; then
  cat > ~/.zshrc <<'EOF'
export PS1="$ "
export PATH=/usr/local/bin:$PATH

eval "$(rbenv init -)"

export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init -)"

export PATH="$HOME/.exenv/bin:$PATH"
eval "$(exenv init -)"

export ERL_AFLAGS="-kernel shell_history enabled"

export PATH=$HOME/.dotnet/tools:$PATH
EOF
else
  echo "### .zshrc already exists"
fi

echo "## install homebrew"
if [[ $(which brew) ]]; then
  brew update
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "## install *env utilities"
brew_install nodenv
brew_install rbenv
brew_install exenv

echo "## reloading .zshrc"
source ~/.zshrc

echo "## install node"
if [[ $(nodenv versions | grep $NODE_VERSION) ]]; then
  echo "node $NODE_VERSION is already installed"
else
  nodenv install $NODE_VERSION
  nodenv global $NODE_VERSION
fi

echo "## install ruby"
if [[ $(rbenv versions | grep $RUBY_VERSION) ]]; then
  echo "ruby $RUBY_VERSION is already installed"
else
  rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
fi

echo "## install elixir"
if [[ $(exenv versions | grep $ELIXIR_VERSION) ]]; then
  echo "elixir $ELIXIR_VERSION is already installed"
else
  exenv install $ELIXIR_VERSION
  exenv global $ELIXIR_VERSION
fi

echo "## install .NET core"
brew_install dotnet-sdk

echo "## install other tools"
xcode-select --install || true

echo "## install applications"
brew tap homebrew/cask-fonts

brew_install 1password
brew_install firefox
brew_install google-chrome
brew_install font-fira-code
brew_install visual-studio-code
brew_install slack
brew_install zoom

echo "## configure npm"
npm config set init.author.name $NPM_AUTHOR
npm config set init.license MIT
npm config set update-notifier false
npm set progress=false

echo "## configure git"
git config --global user.name $GITHUB_USERNAME
git config --global user.email $GITHUB_EMAIL
git config --global core.editor 'code --wait'
git config --global init.defaultBranch main
git config --global merge.ff only
git config --global pull.rebase true
git config --global fetch.prune true
git config --global rebase.autoSquash true
git config --global rebase.autoStash true
git config --global rerere.enabled true
git config --global rerere.autoUpdate true

echo "### aliases"
git config --global alias.s 'status -sb'
git config --global alias.last 'log -1 HEAD'
git config --global alias.gists '!curl --user "'$GITHUB_USERNAME'" https://api.github.com/gists'
git config --global alias.clonemy '!f() { git clone git@github.com:'"$GITHUB_USERNAME"'/$1.git; }; f'
git config --global alias.amend 'commit --amend -C HEAD'
git config --global alias.publish 'push origin HEAD'
git config --global alias.pushforreal '!git push --force-with-lease --no-verify'
git config --global alias.quickrebase '!git fetch && git rebase origin/main'
git config --global alias.cleanbranches '!git branch | grep -v "main" | xargs git branch -D '
git config --global alias.alias "! git config --get-regexp ^alias\. | sed -e s/^alias\.// -e s/\ /\ =\ /"

echo "## generate ssh key"
if [ ! -d ~/.ssh ]; then
  ssh-keygen -t rsa -b 4096 -C $GITHUB_EMAIL
  eval "$(ssh-agent -s)"
  cat > ~/.ssh/config <<'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa
EOF
  ssh-add -K ~/.ssh/id_rsa
  pbcopy < ~/.ssh/id_rsa.pub
  printf "\e[36mSSH key has been copied to clipboard.\e[39m\n"
  echo "Add it to GitHub"
else
  echo "ssh key already exists"
fi

echo "# Setup is complete."