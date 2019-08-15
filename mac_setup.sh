#!/bin/bash

# Manual Steps
# Install Docker: https://docs.docker.com/docker-for-mac/install/

# Settings
GITHUB_USERNAME=bannmoore
GITHUB_EMAIL=moore.brittanyann@gmail.com
NPM_AUTHOR="Brittany Moore<$GITHUB_USERNAME>"
COMPUTER_NAME=Ada
NODE_VERSION=10.16.2
ELIXIR_VERSION=1.9.0

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
brew tap caskroom/fonts

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

echo "## install rvm, ruby, and rails"
curl -sSL https://get.rvm.io | bash -s stable --ruby --rails

gem install jekyll bundler
gem install ruby-debug-ide
gem install rubocop

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

echo "## install postgres"
brew_install postgresql
brew services start postgresql

echo "## set computer name"
if [[ ! $(scutil --get ComputerName) -eq $COMPUTER_NAME ]]; then  
  scutil --set ComputerName $COMPUTER_NAME
fi

echo "## change mac settings"
echo "### cursor speed"
defaults write NSGlobalDomain KeyRepat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
echo "### accessibility UI mode"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo "## create .bash_profile"
cat > ~/.bash_profile <<'EOF'
export PS1="$ "
export PATH=/usr/local/bin:$PATH
eval "$(nodenv init -)"
EOF

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

# This section may be replaced by the Settings Sync extension in VSCode.
# echo "## configure vscode"
# VSCODE_PATH="Library/Application Support/Code/User"
# cp ./vscode/settings.json ~/"$VSCODE_PATH/settings.json"
# cp ./vscode/keybindings.json ~/"$VSCODE_PATH/keybindings.json"
# cp -r ./vscode/snippets ~/"$VSCODE_PATH" 

echo "## install vscode extensions"
code --install-extension EditorConfig.EditorConfig
code --install-extension esbenp.prettier-vscode
code --install-extension mikestead.dotenv
code --install-extension PeterJausovec.vscode-docker
code --install-extension steoates.autoimport
code --install-extension wayou.vscode-todo-highlight
code --install-extension rebornix.ruby
code --install-extension jakebecker.elixir-ls
code --install-extension ms-vsliveshare.vsliveshare
code --install-extension chenxsan.vscode-standardjs
code --install-extension shinnn.stylelint
code --install-extension florinpatrascu.vscode-elixir-snippets
code --install-extension shan.code-settings-sync

echo "# Setup is complete."
