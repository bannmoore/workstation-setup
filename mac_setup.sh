#!/bin/bash

# Settings
GITHUB_USERNAME=bannmoore
GITHUB_EMAIL=moore.brittanyann@gmail.com
NPM_AUTHOR="Brittany Moore<$GITHUB_USERNAME>"
COMPUTER_NAME=Ada
NODE_VERSION=8.11.3

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

brew_cask_install docker
brew_cask_install firefox
brew_cask_install font-fira-code
brew_cask_install google-chrome
brew_cask_install ngrok
brew_cask_install selfcontrol
brew_cask_install slack
brew_cask_install visual-studio-code
brew_cask_install zoomus

echo "## install utilities"
xcode-select --install
brew_install entr
brew_install ripgrep
brew_install ruby
gem install jekyll bundler

echo "## set computer name"
if [[ ! $(scutil --get ComputerName) -eq $COMPUTER_NAME ]]; then  
  scutil --set ComputerName $COMPUTER_NAME
fi

echo "## increase cursor speed"
defaults write NSGlobalDomain KeyRepat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

echo "## create .bash_profile"
cat > ~/.bash_profile <<'EOF'
export PS1="$ "
export PATH=/usr/local/bin:$PATH
eval "$(nodenv init -)"
EOF

echo "## configure npm"
npm config set init.author.name $NPM_AUTHOR
npm config set init.license MIT
npm set progress=false

echo "## configure git"
git config --global alias.s 'status -sb'
git config --global alias.last 'log -1 HEAD'
git config --global alias.gists '!curl --user "'$GITHUB_USERNAME'" https://api.github.com/gists'
git config --global alias.clonemy '!f() { git clone git@github.com:'"$GITHUB_USERNAME"'/$1.git; }; f'
git config --global alias.amend 'commit --amend -C HEAD'
git config --global alias.publish 'push origin HEAD'
git config --global core.editor 'code --wait'
git config --global merge.ff only
git config --global user.name $GITHUB_USERNAME
git config --global user.email $GITHUB_EMAIL

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

echo "## configure vscode"
VSCODE_PATH="Library/Application Support/Code/User"
cp ./vscode/settings.json ~/"$VSCODE_PATH/settings.json"
cp ./vscode/keybindings.json ~/"$VSCODE_PATH/keybindings.json"
cp -r ./vscode/snippets ~/"$VSCODE_PATH" 

echo "## install vscode extensions"
code --install-extension EditorConfig.EditorConfig
code --install-extension esbenp.prettier-vscode
code --install-extension mikestead.dotenv
code --install-extension PeterJausovec.vscode-docker
code --install-extension steoates.autoimport
code --install-extension wayou.vscode-todo-highlight

echo "# Setup is complete."
