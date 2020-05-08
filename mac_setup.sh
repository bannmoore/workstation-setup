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
  if [[ $(brew list | grep $1) ]]; then
    brew upgrade $1
  else
    brew install $1
  fi
}

brew_cask_install() {
  printf $1
  if [[ $(brew cask list | grep $1) ]]; then
    brew cask upgrade $1
  else
    brew cask install $1
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

echo "## Seting computer name."
if [[ ! $(scutil --get ComputerName) == "$COMPUTER_NAME" ]]; then  
  scutil --set ComputerName $COMPUTER_NAME
fi

echo "## Changing mac settings"
echo "### cursor speed"
defaults write NSGlobalDomain KeyRepat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
echo "### accessibility UI mode"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo "## create .zshrc"
if [ ! -f ~/.zshrc ]; then
  cat > ~/.zshrc <<'EOF'
export PS1="$ "
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/opt/python/libexec/bin:$PATH

eval "$(rbenv init -)"

export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init -)"

export PATH="$HOME/.exenv/bin:$PATH"
eval "$(exenv init -)"

export ERL_AFLAGS="-kernel shell_history enabled"
EOF
fi

echo "## install homebrew"
if [[ $(which brew) ]]; then
  brew update
else
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "## install nodenv"
if [[ $(which nodenv) ]]; then
  brew upgrade nodenv
else
  brew install nodenv
  nodenv init
fi

echo "## install node"
if [[ $(nodenv versions | grep $NODE_VERSION) ]]; then
  echo "node $NODE_VERSION is already installed"
else
  nodenv install $NODE_VERSION
  nodenv global $NODE_VERSION
fi

echo "## install other programs"
brew tap homebrew/cask-fonts

brew_cask_install 1password
brew_cask_install firefox
brew_cask_install font-fira-code
brew_cask_install google-chrome
brew_cask_install ngrok
brew_cask_install slack
brew_cask_install visual-studio-code
brew_cask_install zoomus

echo "## install utilities"
xcode-select --install
brew_install entr
brew_install ripgrep
brew_install sl

echo "## install ruby"
brew_install rbenv
if [[ $(rbenv versions | grep $RUBY_VERSION) ]]; then
  echo "ruby $RUBY_VERSION is already installed"
else
  rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
fi

echo "## install go"
brew_install go

echo "## install elixir"
brew_install exenv
if [[ $(exenv versions | grep $ELIXIR_VERSION) ]]; then
  echo "elixir $ELIXIR_VERSION is already installed"
else
  exenv install $ELIXIR_VERSION
  exenv global $ELIXIR_VERSION
fi

echo "## configure npm"
npm config set init.author.name $NPM_AUTHOR
npm config set init.license MIT
npm config set update-notifier false
npm set progress=false

echo "## configure git"
git config --global user.name $GITHUB_USERNAME
git config --global user.email $GITHUB_EMAIL
git config --global core.editor 'code --wait'
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
git config --global alias.quickrebase '!git fetch && git rebase origin/master'
git config --global alias.cleanbranches '!git branch | grep -v "master" | xargs git branch -D '

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
fi

vscode_extension() {
  code --install-extension $1
}

echo "## install vscode extensions"
echo "### vscode"
vscode_extension shan.code-settings-sync
vscode_extension ms-vsliveshare.vsliveshare
vscode_extension editorconfig.editorconfig
echo "### general formatting"
vscode_extension coenraads.bracket-pair-colorizer-2
vscode_extension tyriar.sort-lines
vscode_extension wayou.vscode-todo-highlight
vscode_extension yzhang.markdown-all-in-one
echo "### git"
vscode_extension eamodio.gitlens
echo "### elixir"
vscode_extension jakebecker.elixir-ls
vscode_extension florinpatrascu.vscode-elixir-snippets
echo "### javascript"
vscode_extension dbaeumer.vscode-eslint
echo "### go"
vscode_extension ms-vscode.go
echo "### docker"
vscode_extension PeterJausovec.vscode-docker
echo "### terraform"
vscode_extension mauve.terraform
echo "### dotenv"
vscode_extension mikestead.dotenv

echo "# Setup is complete."
